// core/services/notification_manager.dart
// Decouples push payload processing from UI controllers.
// Handles notification/document sync, deduplication, and navigation hook.

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../constants/push_types.dart';
import '../controllers/message_popup_controller.dart';
import '../services/download_service.dart';
import '../services/file_opener_service.dart';
import '../services/private_chat_notification_service.dart';
import '../widgets/notifications_modal.dart';
import '../../app/routes/app_routes.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../presentation/documents/controllers/documents_controller.dart';
import '../../presentation/chat/controllers/chat_controller.dart';
import '../../presentation/chat/controllers/private_chat_controller.dart';
import '../../presentation/tickets/controllers/tickets_controller.dart';
import '../../presentation/main/main_scaffold.dart';

class NotificationManager extends GetxService {
  /// Last processed FCM message ID; used to skip duplicate delivery.
  String? _lastProcessedMessageId;

  /// Single pending deep-link payload (cold start / pre-HOME).
  Map<String, dynamic>? _pendingNavigationPayload;

  /// Prevents double flush of the same pending payload.
  bool _pendingNavigationExecuting = false;

  /// Process push payload: refresh notifications, unread count, and optionally documents.
  /// [messageId] used for deduplication; when null (e.g. some silent sync), processing is not skipped.
  void handlePushPayload(Map<String, dynamic>? data, {String? messageId}) {
    final payload = data ?? {};

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
          // Already refreshed above.
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
  /// and Notification Center taps. Queues when HOME is not ready.
  void handleNotificationNavigation(Map<String, dynamic> payload) {
    try {
      if (!_isNavigationReady()) {
        _queuePendingNavigation(payload);
        return;
      }
      _executeNavigation(payload);
    } catch (e) {
      print('❌ [NotificationManager] Navigation error: $e');
    }
  }

  /// Call after splash/auth when MainScaffold (HOME) is ready.
  void flushPendingNavigation() {
    if (_pendingNavigationPayload == null) return;
    if (_pendingNavigationExecuting) return;
    if (!_isNavigationReady()) {
      print(
        '🧭 [NotificationManager] flushPendingNavigation deferred — HOME not ready',
      );
      return;
    }

    final payload = Map<String, dynamic>.from(_pendingNavigationPayload!);
    _pendingNavigationPayload = null;
    _pendingNavigationExecuting = true;
    print('🧭 [NotificationManager] Flushing pending navigation');
    try {
      _executeNavigation(payload);
    } catch (e) {
      print('❌ [NotificationManager] Flush navigation error: $e');
    } finally {
      _pendingNavigationExecuting = false;
    }
  }

  void _queuePendingNavigation(Map<String, dynamic> payload) {
    // Keep only the latest payload (one-slot queue).
    _pendingNavigationPayload = Map<String, dynamic>.from(payload);
    print(
      '🧭 [NotificationManager] Queued pending navigation '
      '(type=${_safeType(payload) ?? "none"})',
    );
  }

  bool _isNavigationReady() {
    if (!Get.isRegistered<HomeController>()) return false;
    try {
      Get.find<HomeController>();
    } catch (_) {
      return false;
    }
    final route = Get.currentRoute;
    return route == AppRoutes.HOME;
  }

  void _executeNavigation(Map<String, dynamic> payload) {
    final type = _safeType(payload) ?? '';
    print('🧭 [NotificationManager] Navigation intent – type: $type');

    if (PushTypes.isDocument(type)) {
      _navigateToDocuments(payload);
      return;
    }

    if (PushTypes.isPrivateChat(type)) {
      _navigateToPrivateChat();
      return;
    }

    if (PushTypes.isGroupChat(type)) {
      _navigateToGroupChat();
      return;
    }

    if (PushTypes.isTicketOrSupport(type)) {
      _navigateToTickets(payload);
      return;
    }

    if (PushTypes.isMaintenance(type)) {
      _navigateToMaintenance();
      return;
    }

    // sync_notifications, announcement, unknown, empty → Notification Center
    _navigateToNotificationCenter();
  }

  /// Safely read "type" from payload (null-safe, trimmed, lowercase).
  /// Accepts common FCM/API key aliases without breaking backend contracts.
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
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  void _navigateToDocuments(Map<String, dynamic> payload) {
    final home = Get.find<HomeController>();
    home.navigateToScreen(AppScreen.documents);

    final documentId = _firstNonEmpty(payload, const [
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

  void _navigateToMaintenance() {
    Get.find<HomeController>().navigateToScreen(AppScreen.maintenance);
  }

  void _navigateToNotificationCenter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = Get.context;
      if (context == null) {
        print(
          '🧭 [NotificationManager] Notification Center skipped — no context',
        );
        return;
      }
      NotificationsModal.show(context);
    });
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
