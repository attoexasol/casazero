import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/firebase_error_handler.dart';
import '../../../data/models/private_chat_conversation.dart';
import '../../../data/models/private_chat_message.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/private_chat_repository.dart';
import '../../home/controllers/home_controller.dart';
import '../providers/message_provider.dart';
import '../providers/private_chat_provider.dart';

enum PrivateChatState {
  initial,
  ready,
  noAuth,
  noAdmin,
  permissionDenied,
  networkError,
  indexPending,
}

class PrivateChatController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final FirebaseAuthService _firebaseAuthService = Get.find();
  final StorageService _storageService = Get.find();
  final PrivateChatRepository _repository = Get.find();
  final PrivateChatProvider _provider = Get.find();
  final MessageProvider _messageProvider = Get.find();

  StreamSubscription<User?>? _authStateSub;
  Worker? _messageErrorWorker;
  Worker? _messagesScrollWorker;
  final RxBool isSending = false.obs;
  final RxBool isOpening = false.obs;
  final Rx<PrivateChatState> chatState = PrivateChatState.initial.obs;
  final Rxn<PrivateChatConversation> conversation = Rxn<PrivateChatConversation>();

  @override
  void onInit() {
    super.onInit();
    messageController.addListener(_onMessageChanged);
    _listenFirebaseAuth();
    _messageErrorWorker = ever<String?>(
      _messageProvider.messageError,
      _onMessageStreamError,
    );
    _messagesScrollWorker = ever<List<PrivateChatMessage>>(
      _messageProvider.messages,
      (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        });
      },
    );
    _provider.prepareChat();
    unawaited(_openChat());
  }

  @override
  void onClose() {
    _authStateSub?.cancel();
    _messageErrorWorker?.dispose();
    _messagesScrollWorker?.dispose();
    _messageProvider.clear();
    messageController.removeListener(_onMessageChanged);
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onMessageChanged() => update(['input']);

  bool get isFirebaseSignedIn => _firebaseAuthService.isSignedIn;

  String? get firebaseUid => _firebaseAuthService.firebaseUid;

  RxList<PrivateChatMessage> get messages => _messageProvider.messages;

  RxBool get isLoadingMessages => _messageProvider.isLoadingMessages;

  bool isOwnMessage(PrivateChatMessage msg) {
    final residentId = _residentId();
    return residentId != null && msg.senderId == residentId;
  }

  bool isAdminMessage(PrivateChatMessage msg) => msg.isFromAdmin;

  String formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 24) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  int? _residentId() => _provider.residentId;

  String _residentName() {
    final stored = _storageService.getUserData()?['user_name']?.toString();
    if (stored != null && stored.isNotEmpty) return stored;
    return 'Resident';
  }

  void _onMessageStreamError(String? errorKey) {
    if (errorKey == null) {
      if (chatState.value != PrivateChatState.noAuth &&
          chatState.value != PrivateChatState.noAdmin) {
        chatState.value = PrivateChatState.ready;
      }
      return;
    }
    chatState.value = _stateFromErrorKey(errorKey);
  }

  PrivateChatState _stateFromErrorKey(String key) {
    if (key == FirebaseErrorInfo.permissionUserMessageKey) {
      return PrivateChatState.permissionDenied;
    }
    if (key == FirebaseErrorInfo.indexUserMessageKey) {
      return PrivateChatState.indexPending;
    }
    if (key == FirebaseErrorInfo.networkUserMessageKey) {
      return PrivateChatState.networkError;
    }
    return PrivateChatState.networkError;
  }

  Future<void> _openChat() async {
    if (!_provider.isContextReady.value && Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().fetchResidenceData();
      _provider.prepareChat();
    }

    final adminId = _provider.adminId;
    final residentId = _provider.residentId;
    final residenceId = _provider.residenceId;

    if (!_provider.isContextReady.value ||
        adminId == null ||
        residentId == null ||
        residenceId == null) {
      chatState.value = PrivateChatState.noAdmin;
      return;
    }

    isOpening.value = true;
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await _retryFirebaseAuth();
      }
      if (FirebaseAuth.instance.currentUser == null) {
        chatState.value = PrivateChatState.noAuth;
        return;
      }

      final conv = await _repository.getOrCreateConversation(
        adminId: adminId,
        residentId: residentId,
        residentName: _residentName(),
        residenceId: residenceId,
        residenceName: _provider.residenceName,
        adminName: _provider.adminName,
      );
      conversation.value = conv;
      chatState.value = PrivateChatState.ready;
      _messageProvider.bindConversation(conv.id);
      unawaited(
        _repository.markResidentConversationRead(
          conversationId: conv.id,
          residentId: residentId,
        ),
      );
    } on FirebaseException catch (e) {
      FirebaseErrorHandler.log(
        tag: 'PrivateChat',
        error: e,
        conversationId: conversation.value?.id,
        userId: residentId.toString(),
      );
      chatState.value =
          _stateFromErrorKey(FirebaseErrorHandler.parse(e).userMessageKey);
    } catch (e) {
      FirebaseErrorHandler.log(
        tag: 'PrivateChat',
        error: e,
        userId: residentId.toString(),
      );
      chatState.value = PrivateChatState.networkError;
    } finally {
      isOpening.value = false;
    }
  }

  Future<void> _retryFirebaseAuth() async {
    try {
      if (!Get.isRegistered<AuthRepository>()) return;
      await Get.find<AuthRepository>().syncFirebaseAuthAfterLogin();
    } catch (e) {
      FirebaseErrorHandler.log(tag: 'PrivateChat', error: e);
    }
  }

  void _listenFirebaseAuth() {
    _authStateSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        chatState.value = PrivateChatState.noAuth;
        _messageProvider.clear();
        return;
      }
      if (chatState.value == PrivateChatState.noAuth &&
          conversation.value != null) {
        _messageProvider.bindConversation(conversation.value!.id);
        chatState.value = PrivateChatState.ready;
      }
    });
  }

  Future<void> sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final residentId = _residentId();
    final conv = conversation.value;
    if (residentId == null || conv == null || !isFirebaseSignedIn) return;

    isSending.value = true;
    messageController.clear();

    try {
      await _repository.sendResidentMessage(
        conversationId: conv.id,
        residentId: residentId,
        text: text,
      );
      await _notifyPrivateChatMessage(
        senderId: residentId,
        body: text,
        chatId: conv.id,
      );
      _scrollToBottom();
    } on FirebaseException catch (e) {
      FirebaseErrorHandler.log(
        tag: 'MessageService',
        error: e,
        conversationId: conv.id,
        userId: residentId.toString(),
      );
      chatState.value =
          _stateFromErrorKey(FirebaseErrorHandler.parse(e).userMessageKey);
      messageController.text = text;
    } catch (e) {
      FirebaseErrorHandler.log(
        tag: 'MessageService',
        error: e,
        conversationId: conv.id,
        userId: residentId.toString(),
      );
      messageController.text = text;
    } finally {
      isSending.value = false;
      update(['input']);
    }
  }

  Future<void> _notifyPrivateChatMessage({
    required int senderId,
    required String body,
    required String chatId,
  }) async {
    final adminId = _provider.adminId;
    if (adminId == null || adminId <= 0) return;

    try {
      if (!Get.isRegistered<NotificationRepository>()) return;
      await Get.find<NotificationRepository>().sendChatNotification(
        receiverId: adminId,
        senderId: senderId,
        title: 'notification_new_message'.tr,
        body: body,
        data: {
          'type': 'private_chat',
          'chat_id': chatId,
        },
      );
    } catch (e) {
      debugPrint('[PrivateChatController] Chat notification failed: $e');
    }
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool get hasMessageText => messageController.text.trim().isNotEmpty;
}
