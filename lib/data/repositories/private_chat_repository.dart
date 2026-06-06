import 'package:get/get.dart';

import '../../core/services/private_chat_service.dart';
import '../models/private_chat_conversation.dart';
import '../models/private_chat_message.dart';

class PrivateChatRepository {
  final PrivateChatService _chatService = Get.find();

  String conversationIdFor({
    required int adminId,
    required int residentId,
  }) {
    return _chatService.conversationIdFor(
      adminId: adminId,
      residentId: residentId,
    );
  }

  Future<PrivateChatConversation> getOrCreateConversation({
    required int adminId,
    required int residentId,
    required String residentName,
    required int residenceId,
    required String residenceName,
    required String adminName,
  }) {
    return _chatService.getOrCreateConversation(
      adminId: adminId,
      residentId: residentId,
      residentName: residentName,
      residenceId: residenceId,
      residenceName: residenceName,
      adminName: adminName,
    );
  }

  Stream<List<PrivateChatMessage>> streamMessages(String conversationId) {
    return _chatService.streamMessages(conversationId);
  }

  Future<void> sendResidentMessage({
    required String conversationId,
    required int residentId,
    required String text,
  }) {
    return _chatService.sendResidentMessage(
      conversationId: conversationId,
      residentId: residentId,
      text: text,
    );
  }

  Future<void> markResidentConversationRead({
    required String conversationId,
    required int residentId,
  }) {
    return _chatService.markResidentConversationRead(
      conversationId: conversationId,
      residentId: residentId,
    );
  }
}
