import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../utils/notification_content_localizer.dart';
import '../constants/push_types.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../presentation/chat/controllers/private_chat_controller.dart';
import '../../presentation/chat/controllers/chat_controller.dart';

/// Handles FCM private/group chat notification payloads.
/// Dispatched from [NotificationManager]; does not call back into it (no loops).
class PrivateChatNotificationService extends GetxService {
  /// Register handler for private chat push payloads (call once at startup).
  void registerHandlers() {
    debugPrint(
      '[PrivateChatNotificationService] Registered for '
      'aliases=private_chat_message|private_chat|group_chat',
    );
  }

  /// Process incoming FCM data payload for chat messages (all aliases).
  /// Unread/feed refresh is already done by NotificationManager before dispatch.
  Future<void> handleIncomingPayload(Map<String, dynamic> data) async {
    final type = PushTypes.normalize(
          data['type']?.toString() ??
              data['notification_type']?.toString() ??
              data['push_type']?.toString(),
        ) ??
        '';

    if (!PushTypes.isChat(type)) return;

    final conversationId = data['conversation_id']?.toString();
    final senderName = data['sender_name']?.toString() ??
        NotificationContentLocalizer.translate('administrator');
    final preview = data['message_preview']?.toString() ??
        data['body']?.toString() ??
        data['message']?.toString() ??
        '';

    debugPrint(
      '[PrivateChatNotificationService] type=$type '
      'conversation=$conversationId from=$senderName preview=$preview',
    );

    // Ensure unread badge stays current (idempotent; may already be refreshed).
    _refreshUnreadOnly();

    if (PushTypes.isPrivateChat(type)) {
      _refreshPrivateChatIfOpen(conversationId);
    } else if (PushTypes.isGroupChat(type)) {
      _refreshGroupChatIfOpen();
    }
  }

  void _refreshUnreadOnly() {
    try {
      if (!Get.isRegistered<HomeController>()) return;
      Get.find<HomeController>().fetchUnreadCount();
    } catch (e) {
      debugPrint('[PrivateChatNotificationService] unread refresh error: $e');
    }
  }

  /// Private chat uses Firestore streams; recreate controller only if needed.
  void _refreshPrivateChatIfOpen(String? conversationId) {
    try {
      if (!Get.isRegistered<PrivateChatController>()) return;
      final chat = Get.find<PrivateChatController>();
      // Stream already live — force a light UI update / reopen if id matches.
      final currentId = chat.conversation.value?.id;
      if (conversationId != null &&
          conversationId.isNotEmpty &&
          currentId != null &&
          currentId != conversationId) {
        debugPrint(
          '[PrivateChatNotificationService] Active conversation differs '
          '($currentId vs $conversationId) — leaving stream as-is',
        );
        return;
      }
      chat.update();
    } catch (e) {
      debugPrint('[PrivateChatNotificationService] private refresh error: $e');
    }
  }

  void _refreshGroupChatIfOpen() {
    try {
      if (!Get.isRegistered<ChatController>()) return;
      // Group chat streams messages; trigger UI rebuild.
      Get.find<ChatController>().update();
    } catch (e) {
      debugPrint('[PrivateChatNotificationService] group refresh error: $e');
    }
  }

  /// Payload shape for backend when sending FCM for private chat.
  /// Uses canonical [PushTypes.privateChatMessage]; backend may also send aliases.
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
