import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../home/controllers/home_controller.dart';
import '../models/chat_message_model.dart';

enum ChatState {
  initial,
  ready,
  noAuth,
  noGroup,
  permissionDenied,
  networkError,
}

/// Text-only real-time chat. Uses FirebaseAuthService.firebaseUid.
/// No Firestore listeners if firebaseUid is null.
class ChatController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final FirebaseAuthService _firebaseAuthService = Get.find();
  final StorageService _storageService = Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ChatMessage>>? _messagesStream;
  final RxBool isSending = false.obs;
  final Rx<ChatState> chatState = ChatState.initial.obs;

  String? _groupId;

  @override
  void onInit() {
    super.onInit();
    messageController.addListener(_onMessageChanged);
    _resolveGroupId();
    _subscribeToMessages();
  }

  @override
  void onClose() {
    messageController.removeListener(_onMessageChanged);
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onMessageChanged() => update(['input']);

  void _resolveGroupId() {
    try {
      final homeController = Get.find<HomeController>();
      int? residenceId;

      final residence = homeController.selectedResidence.value;
      if (residence != null) {
        residenceId = residence.id;
      }
      if (residenceId == null) {
        final residenceData = homeController.residenceData.value;
        if (residenceData != null && residenceData['id'] != null) {
          residenceId = residenceData['id'] is int
              ? residenceData['id'] as int
              : int.tryParse(residenceData['id'].toString());
        }
      }
      if (residenceId == null) {
        final userData = _storageService.getUserData();
        final rid = userData?['residence_id'] ?? userData?['unit_id'];
        residenceId = rid is int ? rid : int.tryParse(rid?.toString() ?? '');
      }

      _groupId = residenceId != null ? 'group_$residenceId' : null;
      debugPrint('💬 [ChatController] Group ID: $_groupId');
    } catch (e) {
      _groupId = null;
      debugPrint('⚠️ [ChatController] Failed to resolve group ID: $e');
    }
  }

  void _subscribeToMessages() {
    if (_groupId == null) {
      chatState.value = ChatState.noGroup;
      _messagesStream = Stream.value([]);
      debugPrint('❌ Chat blocked: No residence-based group ID');
      return;
    }

    final uid = firebaseUid;
    if (uid == null) {
      debugPrint('❌ Chat blocked: Firebase UID is null');
      chatState.value = ChatState.noAuth;
      _messagesStream = Stream.value([]);
      return;
    }

    debugPrint('✅ Chat allowed for UID: $uid');
    _validateGroupAndSubscribe();
  }

  Future<void> _validateGroupAndSubscribe() async {
    if (_groupId == null) return;
    try {
      final groupDoc = await _firestore
          .collection('groups')
          .doc(_groupId!)
          .get();
      if (!groupDoc.exists) {
        chatState.value = ChatState.noGroup;
        _messagesStream = Stream.value([]);
        debugPrint('⚠️ [ChatController] Group $_groupId does not exist');
        return;
      }
      debugPrint('✅ Group validation passed');
      chatState.value = ChatState.ready;
      _messagesStream = _streamMessages(_groupId!).map((messages) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        });
        return messages;
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        chatState.value = ChatState.permissionDenied;
      } else if (e.code == 'unavailable' || e.code == 'resource-exhausted') {
        chatState.value = ChatState.networkError;
      } else {
        chatState.value = ChatState.permissionDenied;
      }
      _messagesStream = Stream.value([]);
      debugPrint('⚠️ [ChatController] Group validation failed: ${e.code}');
    } catch (e) {
      final err = e.toString().toLowerCase();
      chatState.value = err.contains('network') || err.contains('socket')
          ? ChatState.networkError
          : ChatState.permissionDenied;
      _messagesStream = Stream.value([]);
      debugPrint('⚠️ [ChatController] Group validation error: $e');
    }
  }

  Stream<List<ChatMessage>> _streamMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }

  Stream<List<ChatMessage>> get messagesStream =>
      _messagesStream ?? Stream.value([]);

  String get groupId => _groupId ?? '';

  bool get isFirebaseSignedIn => _firebaseAuthService.isSignedIn;

  String? get firebaseUid => _firebaseAuthService.firebaseUid;

  bool isOwnMessage(String senderId) =>
      firebaseUid != null && senderId == firebaseUid;

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

  String _senderRole() {
    final userData = _storageService.getUserData();
    final role = userData?['role']?.toString().toLowerCase() ?? 'client';
    return role == 'admin' ? 'admin' : 'user';
  }

  String _senderName() =>
      _storageService.getUserData()?['user_name']?.toString() ?? 'You';

  Future<void> sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    final uid = firebaseUid;
    if (uid == null) return;
    if (_groupId == null || _groupId!.isEmpty) return;

    isSending.value = true;
    messageController.clear();

    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': uid,
        'senderRole': _senderRole(),
        'senderName': _senderName(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        chatState.value = ChatState.permissionDenied;
      } else if (e.code == 'unavailable') {
        chatState.value = ChatState.networkError;
      }
      messageController.text = text;
    } catch (e) {
      messageController.text = text;
    } finally {
      isSending.value = false;
      update(['input']);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get hasMessageText => messageController.text.trim().isNotEmpty;
}
