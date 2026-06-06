import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/push_types.dart';
import 'notification_manager.dart';

/// Hooks for future FCM private-chat notifications.
/// Does not replace existing [NotificationManager] / [FcmService] flow.
class PrivateChatNotificationService extends GetxService {
  NotificationManager? get _notificationManager {
    if (!Get.isRegistered<NotificationManager>()) return null;
    return Get.find<NotificationManager>();
  }

  /// Register handler for private chat push payloads (call once at startup).
  void registerHandlers() {
    debugPrint(
      '[PrivateChatNotificationService] Registered for type=${PushTypes.privateChatMessage}',
    );
  }

  /// Process incoming FCM data payload for a private chat message.
  Future<void> handleIncomingPayload(Map<String, dynamic> data) async {
    final type = data['type']?.toString() ?? '';
    if (type != PushTypes.privateChatMessage) return;

    final conversationId = data['conversation_id']?.toString();
    final senderName = data['sender_name']?.toString() ?? 'Administrator';
    final preview = data['message_preview']?.toString() ?? '';

    debugPrint(
      '[PrivateChatNotificationService] conversation=$conversationId '
      'from=$senderName preview=$preview',
    );

    // Future: navigate to conversation, refresh list, show local notification.
    _notificationManager?.handlePushPayload(data);
  }

  /// Payload shape for backend when sending FCM for private chat.
  static Map<String, String> buildOutgoingPayload({
    required String conversationId,
    required int recipientUserId,
    required String senderName,
    required String messagePreview,
  }) {
    return {
      'type': PushTypes.privateChatMessage,
      'conversation_id': conversationId,
      'recipient_user_id': recipientUserId.toString(),
      'sender_name': senderName,
      'message_preview': messagePreview,
    };
  }
}
