import 'dart:async';

import 'package:get/get.dart';

import '../../../core/utils/firebase_error_handler.dart';
import '../../../data/models/private_chat_message.dart';
import '../../../data/repositories/private_chat_repository.dart';

/// Realtime message stream with cached state and automatic recovery.
class MessageProvider extends GetxController {
  PrivateChatRepository get _repository => Get.find<PrivateChatRepository>();

  final RxList<PrivateChatMessage> messages = <PrivateChatMessage>[].obs;
  final RxBool isLoadingMessages = true.obs;
  final RxnString messageError = RxnString();

  StreamSubscription<List<PrivateChatMessage>>? _messagesSub;
  String? _conversationId;

  void bindConversation(String conversationId) {
    if (_conversationId == conversationId && _messagesSub != null) return;
    _conversationId = conversationId;
    _startStream(conversationId);
  }

  void retry() {
    final id = _conversationId;
    if (id == null) return;
    _startStream(id);
  }

  void clear() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _conversationId = null;
    messages.clear();
    isLoadingMessages.value = false;
    messageError.value = null;
  }

  void _startStream(String conversationId) {
    _messagesSub?.cancel();
    isLoadingMessages.value = messages.isEmpty;
    messageError.value = null;

    _messagesSub = _repository.streamMessages(conversationId).listen(
      (list) {
        messages.assignAll(list);
        isLoadingMessages.value = false;
        messageError.value = null;
      },
      onError: (Object error) {
        final info = FirebaseErrorHandler.parse(error);
        FirebaseErrorHandler.log(
          tag: 'MessageService',
          error: error,
          firestorePath: 'conversations/$conversationId/messages',
          conversationId: conversationId,
        );
        isLoadingMessages.value = false;
        messageError.value = info.userMessageKey;
        // Preserve cached messages on transient errors.
      },
      cancelOnError: false,
    );
  }

  @override
  void onClose() {
    clear();
    super.onClose();
  }
}
