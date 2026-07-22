// core/services/notification_manager.dart
// Decouples push payload processing from UI controllers.
// Handles notification/document sync, deduplication, and deep-link navigation.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../constants/push_types.dart';
import '../controllers/message_popup_controller.dart';
import '../services/download_service.dart';
import '../services/file_opener_service.dart';
import '../services/private_chat_notification_service.dart';
import '../services/storage_service.dart';
import '../../app/routes/app_routes.dart';
import '../../data/models/feed_item_model.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../presentation/documents/controllers/documents_controller.dart';
import '../../presentation/chat/controllers/chat_controller.dart';
import '../../presentation/chat/controllers/private_chat_controller.dart';
import '../../presentation/tickets/controllers/tickets_controller.dart';
import '../../presentation/maintenance/controllers/maintenance_controller.dart';
import '../../presentation/main/main_scaffold.dart';

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
      print('📬 [NotificationManager] Skipping duplicate messageId: $messageId');
      return;
    }

    final type = _safeType(payload);
    if (type != null && type.isNotEmpty) {
      print('📬 [NotificationManager] Push type: $type');
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
        Get.find<PrivateChatNotificationService>().handleIncomingPayload(payload),
      );
    } catch (e) {
      print('❌ [NotificationManager] Chat dispatch error: $e');
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
        print(
          '🧭 [NotificationManager] Navigation queued — HOME/session not ready',
        );
        return;
      }
      unawaited(_runNavigation(normalized));
    } catch (e) {
      print('❌ [NotificationManager] Navigation error: $e');
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
      print(
        '🧭 [NotificationManager] flushPendingNavigation deferred — HOME not ready',
      );
      // Keep stored for after login.
      _queuePendingNavigation(payload);
      return;
    }

    _pendingNavigationExecuting = true;
    print(
      '🧭 [NotificationManager] Flushing pending navigation '
      '(type=${_safeType(payload) ?? "none"}, '
      'reference_id=${_referenceId(payload) ?? "none"})',
    );
    unawaited(() async {
      try {
        _pendingNavigationPayload = Map<String, dynamic>.from(payload);
        await _runNavigation(payload);
      } catch (e) {
        print('❌ [NotificationManager] Flush navigation error: $e');
      } finally {
        _pendingNavigationExecuting = false;
      }
    }());
  }

  Future<void> _runNavigation(Map<String, dynamic> payload) async {
    final enriched = await _enrichPayload(payload);
    _queuePendingNavigation(enriched);
    final navigated = _executeNavigation(enriched);
    if (navigated) {
      _schedulePendingClear();
    } else {
      print(
        '🧭 [NotificationManager] Keeping pending — no navigable section yet',
      );
    }
  }

  /// When FCM/local tap payload lacks type, resolve from in-app feed (same as modal).
  Future<Map<String, dynamic>> _enrichPayload(
    Map<String, dynamic> payload,
  ) async {
    if (_hasNavigableType(payload)) return payload;

    try {
      if (!Get.isRegistered<HomeController>()) return payload;
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
          print(
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
            print(
              '🧭 [NotificationManager] Enriched payload from feed '
              'reference_id=$refId type=${item.type}',
            );
            return item.toNavigationPayload();
          }
        }
      }
    } catch (e) {
      print('❌ [NotificationManager] Enrich payload error: $e');
    }

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
        PushTypes.isTicketOrSupport(type) ||
        PushTypes.isMaintenance(type);
  }

  void _queuePendingNavigation(Map<String, dynamic> payload) {
    _pendingNavigationPayload = Map<String, dynamic>.from(payload);
    _persistPendingToStorage(payload);
    print(
      '🧭 [NotificationManager] Queued pending navigation '
      '(type=${_safeType(payload) ?? "none"}, '
      'reference_id=${_referenceId(payload) ?? "none"})',
    );
  }

  void _persistPendingToStorage(Map<String, dynamic> payload) {
    try {
      if (!Get.isRegistered<StorageService>()) return;
      unawaited(
        Get.find<StorageService>().savePendingNotificationNav(payload),
      );
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

  /// Clear pending only if the session is still valid shortly after navigate.
  /// If a 401 forces login, the pending payload survives for post-login flush.
  void _schedulePendingClear() {
    Future<void>.delayed(const Duration(seconds: 3), () {
      try {
        if (!Get.isRegistered<StorageService>()) return;
        final token = Get.find<StorageService>().getAccessToken();
        if (token == null || token.isEmpty) return;
        if (Get.currentRoute != AppRoutes.HOME) return;
        _pendingNavigationPayload = null;
        unawaited(Get.find<StorageService>().clearPendingNotificationNav());
        print('🧭 [NotificationManager] Pending navigation cleared');
      } catch (_) {}
    });
  }

  bool _isNavigationReady() {
    if (!Get.isRegistered<HomeController>()) return false;
    try {
      Get.find<HomeController>();
    } catch (_) {
      return false;
    }
    if (Get.currentRoute != AppRoutes.HOME) return false;

    // Require a session token so we don't consume the deep link right before
    // a forced re-login (invalid/expired token).
    if (Get.isRegistered<StorageService>()) {
      final token = Get.find<StorageService>().getAccessToken();
      if (token == null || token.isEmpty) return false;
    }
    return true;
  }

  /// Returns true when a concrete app section was opened.
  bool _executeNavigation(Map<String, dynamic> payload) {
    final type = _safeType(payload) ?? '';
    final refId = _referenceId(payload);
    print(
      '🧭 [NotificationManager] Navigation intent – type: $type, '
      'reference_id: ${refId ?? "none"}',
    );

    if (PushTypes.isDocument(type)) {
      _navigateToDocuments(payload);
      return true;
    }

    if (PushTypes.isPrivateChat(type)) {
      _navigateToPrivateChat();
      return true;
    }

    if (PushTypes.isGroupChat(type)) {
      _navigateToGroupChat();
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

    // Do NOT open the notification modal on push tap.
    // Unknown / sync / announcement → stay on home (section already open if typed).
    print(
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
    ]) {
      final value = data[key];
      if (value == null) continue;
      final s = PushTypes.normalize(value.toString());
      if (s != null) return s;
    }
    return null;
  }

  static String? _firstNonEmpty(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
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
    final url = _firstNonEmpty(payload, const [
      'url',
      'file_url',
      'document_url',
    ]);
    final fileName = _firstNonEmpty(payload, const [
      'file_name',
      'document_name',
      'related_entity_name',
      'title',
    ]);

    if (documentId == null && (url == null || url.isEmpty)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (documentId != null) {
        unawaited(_openDocumentById(documentId));
      } else if (url != null) {
        unawaited(
          _openDocumentFromUrl(
            url,
            fileName: fileName,
            fileId: _firstNonEmpty(payload, const ['id', 'notification_id']),
          ),
        );
      }
    });
  }

  Future<void> _openDocumentById(String documentId) async {
    try {
      if (!Get.isRegistered<DocumentsController>()) {
        Get.put(DocumentsController());
      }
      final docs = Get.find<DocumentsController>();
      if (docs.documents.isEmpty) {
        await docs.fetchDocuments();
      }

      final match = docs.documents.firstWhereOrNull(
        (d) => d.id == documentId || d.id == documentId.toString(),
      );
      if (match == null) {
        print(
          '🧭 [NotificationManager] Document id=$documentId not in list — stayed on Documents',
        );
        return;
      }

      await docs.downloadDocument(match);
    } catch (e) {
      print('❌ [NotificationManager] Open document error: $e');
    }
  }

  Future<void> _openDocumentFromUrl(
    String url, {
    String? fileName,
    String? fileId,
  }) async {
    try {
      if (!Get.isRegistered<DownloadService>()) return;
      final downloadService = Get.find<DownloadService>();
      final name = (fileName != null && fileName.contains('.'))
          ? fileName
          : (fileName != null && fileName.isNotEmpty
              ? '$fileName.pdf'
              : 'document.pdf');

      MessagePopupController.showDownloading(
        messageKey: '${'downloading'.tr}: $name',
        titleKey: 'downloading',
      );

      final result = await downloadService.downloadDocument(
        fileUrl: url,
        fileName: name,
        fileId: fileId ?? name,
      );

      MessagePopupController.closePopup();

      if (result['success'] == true) {
        final filePath = result['filePath'] as String?;
        if (filePath != null && await File(filePath).exists()) {
          await FileOpenerService.openWithChooser(filePath);
        }
      } else {
        MessagePopupController.showError(
          messageKey: 'downloadError',
          titleKey: 'downloadFailed',
        );
      }
    } catch (e) {
      print('❌ [NotificationManager] Open document URL error: $e');
      MessagePopupController.closePopup();
      MessagePopupController.showError(
        messageKey: 'downloadError',
        titleKey: 'downloadFailed',
      );
    }
  }

  void _navigateToPrivateChat() {
    final home = Get.find<HomeController>();
    if (Get.isRegistered<PrivateChatController>()) {
      Get.delete<PrivateChatController>();
    }
    home.navigateToScreen(AppScreen.adminChat);
  }

  void _navigateToGroupChat() {
    final home = Get.find<HomeController>();
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
    ]);
    if (ticketId != null) {
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
      'related_id',
      'entity_id',
    ]);
    if (taskId != null) {
      maintenance.pendingFocusTaskId.value = taskId;
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
      print('❌ [NotificationManager] Refresh notifications error: $e');
    }
  }

  void _refreshDocuments() {
    try {
      if (!Get.isRegistered<DocumentsController>()) return;
      Get.find<DocumentsController>().fetchDocuments();
    } catch (e) {
      print('❌ [NotificationManager] Refresh documents error: $e');
    }
  }
}
