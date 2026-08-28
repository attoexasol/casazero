// core/services/notification_manager.dart
// Decouples push payload processing from UI controllers.
// Handles notification/document sync, deduplication, and deep-link navigation.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../constants/push_types.dart';
import '../services/private_chat_notification_service.dart';
import '../services/storage_service.dart';
import '../../app/routes/app_routes.dart';
import '../../data/models/document_model.dart';
import '../../data/models/feed_item_model.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../presentation/documents/controllers/documents_controller.dart';
import '../../presentation/chat/controllers/chat_controller.dart';
import '../../presentation/chat/controllers/private_chat_controller.dart';
import '../../presentation/tickets/controllers/tickets_controller.dart';
import '../../presentation/maintenance/controllers/maintenance_controller.dart';
import '../../presentation/main/main_scaffold.dart';
import 'package:casazero/core/logging/diagnostic_logger.dart';

class NotificationManager extends GetxService {
  /// Last processed FCM message ID; used to skip duplicate delivery.
  String? _lastProcessedMessageId;

  /// Single pending deep-link payload (cold start / pre-HOME / login required).
  Map<String, dynamic>? _pendingNavigationPayload;

  /// Prevents double flush of the same pending payload.
  bool _pendingNavigationExecuting = false;

  /// Process push payload: refresh notifications, unread count, and optionally documents.
  /// [messageId] used for deduplication; when null (e.g. some silent sync), processing is not skipped.
  void handlePushPayload(Map<String, dynamic>? data, {String? messageId}) {
    final payload = _normalizePayload(data ?? {});

    if (messageId != null && messageId == _lastProcessedMessageId) {
      DiagnosticLogger.instance.debug(
        '📬 [NotificationManager] Skipping duplicate messageId: $messageId',
      );
      return;
    }

    final type = _safeType(payload);
    if (type != null && type.isNotEmpty) {
      DiagnosticLogger.instance.debug('📬 [NotificationManager] Push type: $type');
    }

    _refreshNotificationsAndUnread();

    if (PushTypes.isChat(type)) {
      _dispatchChatPayload(payload);
    } else {
      switch (type) {
        case PushTypes.documentUploaded:
          _refreshDocuments();
          break;
        case PushTypes.syncNotifications:
          break;
        default:
          if (PushTypes.isDocument(type)) {
            _refreshDocuments();
          }
          break;
      }
    }

    if (messageId != null) {
      _lastProcessedMessageId = messageId;
    }
  }

  void _dispatchChatPayload(Map<String, dynamic> payload) {
    try {
      if (!Get.isRegistered<PrivateChatNotificationService>()) return;
      unawaited(
        Get.find<PrivateChatNotificationService>().handleIncomingPayload(
          payload,
        ),
      );
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [NotificationManager] Chat dispatch error: $e');
    }
  }

  /// Central deep-link navigation for FCM taps, local notification taps,
  /// and Notification Center taps. Queues when HOME / session is not ready.
  void handleNotificationNavigation(Map<String, dynamic> payload) {
    try {
      final normalized = _normalizePayload(payload);
      // Always persist so login / session-expiry can resume the deep link.
      _queuePendingNavigation(normalized);

      if (!_isNavigationReady()) {
        DiagnosticLogger.instance.debug(
          '🧭 [NotificationManager] Navigation queued — scheduling flush retry',
        );
        Future<void>.delayed(
          const Duration(milliseconds: 250),
          flushPendingNavigation,
        );
        Future<void>.delayed(
          const Duration(milliseconds: 600),
          flushPendingNavigation,
        );
        Future<void>.delayed(
          const Duration(milliseconds: 1200),
          flushPendingNavigation,
        );
        return;
      }
      unawaited(_runNavigation(normalized));
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [NotificationManager] Navigation error: $e');
    }
  }

  /// Call after splash/auth when MainScaffold (HOME) is ready.
  void flushPendingNavigation() {
    if (_pendingNavigationExecuting) return;

    final fromMemory = _pendingNavigationPayload;
    final fromStorage = _loadPendingFromStorage();
    final payload = fromMemory ?? fromStorage;
    if (payload == null || payload.isEmpty) return;

    if (!_isNavigationReady()) {
      DiagnosticLogger.instance.debug(
        '🧭 [NotificationManager] flushPendingNavigation deferred — HOME not ready',
      );
      // Keep stored for after login.
      _queuePendingNavigation(payload);
      return;
    }

    _pendingNavigationExecuting = true;
    DiagnosticLogger.instance.debug(
      '🧭 [NotificationManager] Flushing pending navigation '
      '(type=${_safeType(payload) ?? "none"}, '
      'reference_id=${_referenceId(payload) ?? "none"})',
    );
    unawaited(() async {
      try {
        _pendingNavigationPayload = Map<String, dynamic>.from(payload);
        await _runNavigation(payload);
      } catch (e) {
        DiagnosticLogger.instance.error('❌ [NotificationManager] Flush navigation error: $e');
      } finally {
        _pendingNavigationExecuting = false;
      }
    }());
  }

  Future<void> _runNavigation(Map<String, dynamic> payload) async {
    final enriched = await _enrichPayload(payload);
    final navigated = _executeNavigation(enriched);
    if (navigated) {
      _clearPendingNavigation();
    } else {
      _queuePendingNavigation(enriched);
      DiagnosticLogger.instance.debug(
        '🧭 [NotificationManager] Keeping pending — no navigable section yet',
      );
    }
  }

  void _clearPendingNavigation() {
    _pendingNavigationPayload = null;
    try {
      if (Get.isRegistered<StorageService>()) {
        unawaited(Get.find<StorageService>().clearPendingNotificationNav());
      }
    } catch (_) {}
    DiagnosticLogger.instance.debug('🧭 [NotificationManager] Pending navigation cleared');
  }

  /// When FCM/local tap payload lacks type, resolve from in-app feed (same as modal).
  Future<Map<String, dynamic>> _enrichPayload(
    Map<String, dynamic> payload,
  ) async {
    if (_hasNavigableType(payload)) return payload;

    try {
      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();

        if (home.feedItems.isEmpty) {
          await home.fetchNotifications();
        }

        final notificationId = _firstNonEmpty(payload, const [
          'id',
          'notification_id',
          'notificationId',
        ]);
        if (notificationId != null) {
          final match = _findFeedItemById(home.feedItems, notificationId);
          if (match != null) {
            DiagnosticLogger.instance.debug(
              '🧭 [NotificationManager] Enriched payload from feed id=$notificationId '
              'type=${match.type}',
            );
            return match.toNavigationPayload();
          }
        }

        final refId = _referenceId(payload);
        if (refId != null) {
          for (final item in home.feedItems) {
            if (item.referenceId != null &&
                item.referenceId.toString() == refId) {
              DiagnosticLogger.instance.debug(
                '🧭 [NotificationManager] Enriched payload from feed '
                'reference_id=$refId type=${item.type}',
              );
              return item.toNavigationPayload();
            }
          }
        }
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [NotificationManager] Enrich payload error: $e');
    }

    try {
      final synthetic = FeedItemModel.fromJson(payload);
      final derived = synthetic.toNavigationPayload();
      if (_hasNavigableType(derived)) {
        DiagnosticLogger.instance.debug(
          '🧭 [NotificationManager] Enriched payload via FeedItemModel inference: '
          'type=${derived['type']}',
        );
        return derived;
      }
    } catch (_) {}

    return payload;
  }

  FeedItemModel? _findFeedItemById(List<FeedItemModel> items, String id) {
    for (final item in items) {
      if (item.id.toString() == id) return item;
    }
    return null;
  }

  bool _hasNavigableType(Map<String, dynamic> payload) {
    final type = _safeType(payload);
    return PushTypes.isDocument(type) ||
        PushTypes.isPrivateChat(type) ||
        PushTypes.isGroupChat(type) ||
        PushTypes.isChat(type) ||
        PushTypes.isTicketOrSupport(type) ||
        PushTypes.isMaintenance(type);
  }

  void _queuePendingNavigation(Map<String, dynamic> payload) {
    _pendingNavigationPayload = Map<String, dynamic>.from(payload);
    _persistPendingToStorage(payload);
    DiagnosticLogger.instance.debug(
      '🧭 [NotificationManager] Queued pending navigation '
      '(type=${_safeType(payload) ?? "none"}, '
      'reference_id=${_referenceId(payload) ?? "none"})',
    );
  }

  void _persistPendingToStorage(Map<String, dynamic> payload) {
    try {
      if (!Get.isRegistered<StorageService>()) return;
      unawaited(Get.find<StorageService>().savePendingNotificationNav(payload));
    } catch (_) {}
  }

  Map<String, dynamic>? _loadPendingFromStorage() {
    try {
      if (!Get.isRegistered<StorageService>()) return null;
      return Get.find<StorageService>().getPendingNotificationNav();
    } catch (_) {
      return null;
    }
  }

  bool _isNavigationReady() {
    if (Get.isRegistered<StorageService>()) {
      final token = Get.find<StorageService>().getAccessToken();
      if (token == null || token.isEmpty) return false;
    } else {
      return false;
    }

    // Dismiss any open modal / dialog / bottom sheet that blocks MainScaffold.
    try {
      if (Get.isDialogOpen == true ||
          Get.isBottomSheetOpen == true ||
          Get.isOverlaysOpen == true) {
        Get.until(
          (route) => route.settings.name == AppRoutes.HOME || route.isFirst,
        );
      }
    } catch (_) {}

    // If currently on an authenticated sub-route, bring user back to HOME
    if (Get.currentRoute != AppRoutes.HOME &&
        Get.currentRoute != AppRoutes.SPLASH &&
        Get.currentRoute != AppRoutes.AUTH &&
        Get.currentRoute != AppRoutes.OTP_VERIFICATION) {
      Get.offAllNamed(AppRoutes.HOME);
    }

    if (!Get.isRegistered<HomeController>()) return false;
    try {
      Get.find<HomeController>();
    } catch (_) {
      return false;
    }
    if (Get.currentRoute != AppRoutes.HOME) return false;

    return true;
  }

  /// Returns true when a concrete app section was opened.
  bool _executeNavigation(Map<String, dynamic> payload) {
    final type = _safeType(payload) ?? '';
    final refId = _referenceId(payload);
    DiagnosticLogger.instance.debug(
      '🧭 [NotificationManager] Navigation intent – type: $type, '
      'reference_id: ${refId ?? "none"}',
    );

    if (PushTypes.isDocument(type)) {
      _navigateToDocuments(payload);
      return true;
    }

    if (PushTypes.isGroupChat(type)) {
      _navigateToGroupChat(payload);
      return true;
    }

    if (PushTypes.isPrivateChat(type)) {
      _navigateToPrivateChat(payload);
      return true;
    }

    if (PushTypes.isChat(type)) {
      if (_looksLikeAdminChat(payload)) {
        _navigateToPrivateChat(payload);
      } else {
        _navigateToGroupChat(payload);
      }
      return true;
    }

    if (PushTypes.isTicketOrSupport(type)) {
      _navigateToTickets(payload);
      return true;
    }

    if (PushTypes.isMaintenance(type)) {
      _navigateToMaintenance(payload);
      return true;
    }

    if (type == 'residence_status' ||
        type == 'construction' ||
        type == 'home' ||
        PushTypes.isSyncOrAnnouncement(type)) {
      final home = Get.find<HomeController>();
      home.navigateToScreen(AppScreen.home);
      return true;
    }

    // Unknown → stay on current screen
    DiagnosticLogger.instance.debug(
      '🧭 [NotificationManager] No section route for type="$type" — staying on current screen',
    );
    return false;
  }

  /// Flatten nested FCM `data` JSON strings and normalize keys.
  static Map<String, dynamic> _normalizePayload(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};

    void merge(Map input) {
      input.forEach((key, value) {
        if (value == null) return;
        out[key.toString()] = value;
      });
    }

    merge(raw);

    final nested = raw['data'];
    if (nested is String && nested.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(nested);
        if (decoded is Map) merge(decoded);
      } catch (_) {}
    } else if (nested is Map) {
      merge(nested);
    }

    return out;
  }

  /// Safely read "type" from payload (null-safe, trimmed, lowercase).
  static String? _safeType(Map<String, dynamic> data) {
    for (final key in const [
      'type',
      'notification_type',
      'push_type',
      'category',
      'event',
      'screen',
      'click_action',
    ]) {
      final value = data[key];
      if (value == null) continue;
      final s = PushTypes.normalize(value.toString());
      if (s != null) return s;
    }
    if (data.containsKey('group_id') &&
        data['group_id'] != null &&
        data['group_id'].toString().isNotEmpty) {
      return 'group_chat';
    }
    if (data.containsKey('conversation_id') ||
        (data.containsKey('chat_id') && !data.containsKey('group_id'))) {
      return 'private_chat';
    }
    return null;
  }

  static String? _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return null;
  }

  /// Primary entity id from push/API (`reference_id` preferred).
  static String? _referenceId(Map<String, dynamic> data) {
    return _firstNonEmpty(data, const [
      'reference_id',
      'referenceId',
      'document_id',
      'documentId',
      'ticket_id',
      'ticketId',
      'maintenance_id',
      'maintenanceId',
      'task_id',
      'related_document_id',
      'related_id',
      'entity_id',
    ]);
  }

  void _navigateToDocuments(Map<String, dynamic> payload) {
    final home = Get.find<HomeController>();
    home.navigateToScreen(AppScreen.documents);

    final documentId = _firstNonEmpty(payload, const [
      'reference_id',
      'referenceId',
      'document_id',
      'documentId',
      'related_document_id',
      'related_id',
      'entity_id',
    ]);
    final fileName = _firstNonEmpty(payload, const [
      'file_name',
      'document_name',
      'related_entity_name',
    ]);

    if ((documentId == null || documentId.isEmpty) &&
        (fileName == null || fileName.isEmpty)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openDocument(documentId: documentId, fileName: fileName));
    });
  }

  Future<void> _openDocument({String? documentId, String? fileName}) async {
    try {
      if (!Get.isRegistered<DocumentsController>()) {
        Get.put(DocumentsController());
      }
      final docs = Get.find<DocumentsController>();
      if (docs.documents.isEmpty) {
        await docs.fetchDocuments();
      }

      DocumentModel? match;
      if (documentId != null && documentId.isNotEmpty) {
        match = docs.documents.firstWhereOrNull(
          (d) => d.id == documentId || d.id == documentId.toString(),
        );
      }
      if (match == null && fileName != null && fileName.isNotEmpty) {
        final cleanTarget = fileName.toLowerCase().trim();
        match = docs.documents.firstWhereOrNull((d) {
          final t = d.title.toLowerCase().trim();
          final fn = (d.fileUrl ?? '').toLowerCase().trim();
          return t == cleanTarget ||
              fn.endsWith(cleanTarget) ||
              t.contains(cleanTarget);
        });
      }

      if (match == null) {
        DiagnosticLogger.instance.error(
          '🧭 [NotificationManager] Document not in list — stayed on Documents',
        );
        return;
      }

      await docs.downloadDocument(match);
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [NotificationManager] Open document error: $e');
    }
  }

  bool _looksLikeAdminChat(Map<String, dynamic> payload) {
    final type = _safeType(payload);
    if (PushTypes.isPrivateChat(type)) return true;
    if (PushTypes.isGroupChat(type)) return false;

    final group = payload['group_id']?.toString() ?? '';
    if (group.isNotEmpty) return false;

    final title = (payload['title'] ?? payload['notification_title'] ?? '')
        .toString()
        .toLowerCase();
    final cat = (payload['category'] ?? payload['category_name'] ?? '')
        .toString()
        .toLowerCase();

    if (title.contains('condomin') ||
        title.contains('group') ||
        title.contains('gruppo') ||
        cat.contains('condomin') ||
        cat.contains('group') ||
        cat.contains('gruppo')) {
      return false;
    }

    final body = (payload['body'] ??
            payload['description'] ??
            payload['content'] ??
            '')
        .toString()
        .toLowerCase();

    return title.contains('admin') ||
        body.contains('admin') ||
        cat.contains('admin') ||
        title.contains('amministratore') ||
        body.contains('amministratore') ||
        cat.contains('amministratore') ||
        title.contains('private') ||
        body.contains('private') ||
        cat.contains('private') ||
        title.contains('privat') ||
        body.contains('privat');
  }

  void _navigateToPrivateChat([Map<String, dynamic>? payload]) {
    final home = Get.find<HomeController>();
    if (Get.isRegistered<PrivateChatController>()) {
      Get.delete<PrivateChatController>();
    }
    home.navigateToScreen(AppScreen.adminChat);
  }

  void _navigateToGroupChat([Map<String, dynamic>? payload]) {
    final home = Get.find<HomeController>();
    if (Get.isRegistered<ChatController>()) {
      Get.delete<ChatController>();
    }
    if (!Get.isRegistered<ChatController>()) {
      Get.put(ChatController());
    }
    home.navigateToScreen(AppScreen.chat);
  }

  void _navigateToTickets(Map<String, dynamic> payload) {
    final home = Get.find<HomeController>();

    if (!Get.isRegistered<TicketsController>()) {
      Get.put(TicketsController());
    }
    final tickets = Get.find<TicketsController>();

    final ticketId = _firstNonEmpty(payload, const [
      'reference_id',
      'referenceId',
      'ticket_id',
      'ticketId',
      'support_ticket_id',
      'related_id',
      'entity_id',
      'id',
    ]);
    if (ticketId != null && ticketId.isNotEmpty) {
      tickets.pendingExpandTicketId.value = ticketId;
    }

    home.navigateToScreen(AppScreen.tickets);
  }

  void _navigateToMaintenance(Map<String, dynamic> payload) {
    final home = Get.find<HomeController>();

    if (!Get.isRegistered<MaintenanceController>()) {
      Get.put(MaintenanceController());
    }
    final maintenance = Get.find<MaintenanceController>();

    final taskId = _firstNonEmpty(payload, const [
      'reference_id',
      'referenceId',
      'maintenance_id',
      'maintenanceId',
      'task_id',
      'taskId',
      'related_id',
      'entity_id',
    ]);
    if (taskId != null && taskId.isNotEmpty) {
      maintenance.pendingFocusTaskId.value = taskId;
      maintenance.expandedCardId.value = taskId;
      maintenance.setSelectedCategoryId(null);
    }

    home.navigateToScreen(AppScreen.maintenance);
  }

  void _refreshNotificationsAndUnread() {
    try {
      if (!Get.isRegistered<HomeController>()) return;
      final home = Get.find<HomeController>();
      home.fetchNotifications();
      home.fetchUnreadCount();
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [NotificationManager] Refresh notifications error: $e');
    }
  }

  void _refreshDocuments() {
    try {
      if (!Get.isRegistered<DocumentsController>()) return;
      Get.find<DocumentsController>().fetchDocuments();
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [NotificationManager] Refresh documents error: $e');
    }
  }
}
