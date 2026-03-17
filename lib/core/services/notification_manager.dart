// core/services/notification_manager.dart
// Decouples push payload processing from UI controllers.
// Handles notification/document sync, deduplication, and navigation hook.

import 'package:get/get.dart';
import '../constants/push_types.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../presentation/documents/controllers/documents_controller.dart';

class NotificationManager extends GetxService {
  /// Last processed FCM message ID; used to skip duplicate delivery.
  String? _lastProcessedMessageId;

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

    switch (type) {
      case PushTypes.documentUploaded:
        _refreshDocuments();
        break;
      case PushTypes.syncNotifications:
        _refreshNotificationsAndUnread();
        break;
      default:
        break;
    }

    if (messageId != null) {
      _lastProcessedMessageId = messageId;
    }
  }

  /// Prepare structure for future deep navigation from notification tap.
  /// For now only logs intended navigation; do not trigger controllers or routes here.
  void handleNotificationNavigation(Map<String, dynamic> payload) {
    final type = _safeType(payload);
    if (type != null && type.isNotEmpty) {
      print('🧭 [NotificationManager] Navigation intent – type: $type');
    }
    // Future: document_uploaded → open document screen; new_message → open chat; announcement → open feed
  }

  /// Safely read "type" from payload (null-safe, trimmed, lowercase).
  static String? _safeType(Map<String, dynamic> data) {
    final value = data['type'];
    if (value == null) return null;
    final s = value.toString().trim().toLowerCase();
    return s.isEmpty ? null : s;
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
