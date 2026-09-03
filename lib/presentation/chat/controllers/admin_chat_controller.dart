import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/permissions.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../home/controllers/home_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../models/chat_message_model.dart';

enum AdminChatState {
  initial,
  ready,
  noAuth,
  noConversation,
  permissionDenied,
  networkError,
}

/// One-to-one user ↔ admin chat.
///
/// Firestore layout (wire rules to match):
/// - `admin_chats/{conversationId}` — metadata (optional)
/// - `admin_chats/{conversationId}/messages/{messageId}` — message docs
///
/// [conversationId] = `res_{residenceId}_user_{firebaseUid}`
class AdminChatController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final FirebaseAuthService _firebaseAuthService = Get.find();
  final StorageService _storageService = Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'admin_chats';

  Stream<List<ChatMessage>>? _messagesStream;
  StreamSubscription<User?>? _authStateSub;
  final RxBool isSending = false.obs;
  final Rx<AdminChatState> chatState = AdminChatState.initial.obs;

  String? _conversationId;
  String? _residenceId;

  @override
  void onInit() {
    super.onInit();
    messageController.addListener(_onMessageChanged);
    _resolveConversationId();
    _listenFirebaseAuth();
    unawaited(_initWhenFirebaseReady());
  }

  @override
  void onClose() {
    _authStateSub?.cancel();
    messageController.removeListener(_onMessageChanged);
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onMessageChanged() => update(['input']);

  /// Public for Firestore rules / backend setup.
  String get conversationId => _conversationId ?? '';

  String get firestoreCollectionPath => '$collectionName/$conversationId';

  String get firestoreMessagesPath =>
      '$collectionName/$conversationId/messages';

  bool get isFirebaseSignedIn => _firebaseAuthService.isSignedIn;

  String? get firebaseUid => _firebaseAuthService.firebaseUid;

  Stream<List<ChatMessage>> get messagesStream =>
      _messagesStream ?? Stream.value([]);

  bool isOwnMessage(String senderId) {
    final uid = firebaseUid;
    if (uid == null || senderId.isEmpty) return false;
    final a = senderId.trim();
    final b = uid.trim();
    if (a == b) return true;
    final aNum = int.tryParse(a);
    final bNum = int.tryParse(b);
    return aNum != null && bNum != null && aNum == bNum;
  }

  bool isAdminMessage(ChatMessage msg) => msg.isAdminSender;

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

  void _resolveConversationId() {
    try {
      int? residenceId;
      final homeController = Get.find<HomeController>();

      final residence = homeController.selectedResidence.value;
      if (residence != null) {
        residenceId = UserModel.parseResidenceIdAsInt(residence.id);
      }
      if (residenceId == null) {
        final residenceData = homeController.residenceData.value;
        if (residenceData != null) {
          residenceId = UserModel.parseResidenceIdAsInt(
            residenceData['id'] ?? residenceData['residence_id'],
          );
        }
      }
      if (residenceId == null) {
        final rid = homeController.currentUser.value?.residenceId;
        residenceId = UserModel.parseResidenceIdAsInt(rid);
      }
      if (residenceId == null) {
        final userData = _storageService.getUserData();
        final rid = userData?['residence_id'] ?? userData?['unit_id'];
        residenceId = UserModel.parseResidenceIdAsInt(rid);
      }

      _residenceId = residenceId?.toString();
      final uid = firebaseUid ?? _storageService.getUserData()?['id']?.toString();
      if (residenceId != null && uid != null && uid.isNotEmpty) {
        _conversationId = 'res_${residenceId}_user_$uid';
      } else {
        _conversationId = null;
      }
      debugPrint(
        '💬 [AdminChatController] conversationId=$_conversationId',
      );
    } catch (e) {
      _conversationId = null;
      debugPrint('⚠️ [AdminChatController] resolve conversation: $e');
    }
  }

  Future<void> _initWhenFirebaseReady() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await _retryFirebaseAuth();
    }
    if (FirebaseAuth.instance.currentUser == null) {
      chatState.value = AdminChatState.noAuth;
      _messagesStream = Stream.value([]);
      return;
    }
    if (_conversationId == null) {
      chatState.value = AdminChatState.noConversation;
      _messagesStream = Stream.value([]);
      return;
    }
    _subscribeToMessages();
  }

  Future<void> _retryFirebaseAuth() async {
    try {
      if (!Get.isRegistered<AuthRepository>()) return;
      await Get.find<AuthRepository>().syncFirebaseAuthAfterLogin();
      if (_firebaseAuthService.isSignedIn && _conversationId != null) {
        _subscribeToMessages();
      }
    } catch (e) {
      debugPrint('[AdminChatController] retry auth: $e');
    }
  }

  void _listenFirebaseAuth() {
    _authStateSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        chatState.value = AdminChatState.noAuth;
        _messagesStream = Stream.value([]);
        return;
      }
      if (_conversationId == null) return;
      if (chatState.value == AdminChatState.noAuth) {
        _subscribeToMessages();
      }
    });
  }

  void _subscribeToMessages() {
    if (_conversationId == null) {
      chatState.value = AdminChatState.noConversation;
      _messagesStream = Stream.value([]);
      return;
    }
    if (firebaseUid == null) {
      chatState.value = AdminChatState.noAuth;
      _messagesStream = Stream.value([]);
      return;
    }

    chatState.value = AdminChatState.ready;
    _messagesStream = _streamMessages(_conversationId!).map((messages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      });
      return messages;
    });
  }

  Stream<List<ChatMessage>> _streamMessages(String conversationId) {
    return _firestore
        .collection(collectionName)
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }

  Role? _currentUserRole() {
    if (Get.isRegistered<HomeController>()) {
      final role = Get.find<HomeController>().currentUser.value?.role;
      if (role != null) return role;
    }
    if (Get.isRegistered<ProfileController>()) {
      final role = Get.find<ProfileController>().user.value?.role;
      if (role != null) return role;
    }
    final userData = _storageService.getUserData();
    if (userData != null) {
      return UserModel.fromJson(userData).role;
    }
    return null;
  }

  String _senderRole() {
    final role = _currentUserRole();
    if (role != null) {
      return ChatMessage.senderRoleForUser(role);
    }
    return 'user';
  }

  String _senderName() {
    if (Get.isRegistered<ProfileController>()) {
      final name = Get.find<ProfileController>().user.value?.userName.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    if (Get.isRegistered<HomeController>()) {
      final name =
          Get.find<HomeController>().currentUser.value?.userName.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    final stored =
        _storageService.getUserData()?['user_name']?.toString().trim();
    if (stored != null && stored.isNotEmpty) return stored;
    return 'You';
  }

  Future<void> _ensureConversationDoc() async {
    if (_conversationId == null) return;
    final ref = _firestore.collection(collectionName).doc(_conversationId!);
    final snap = await ref.get();
    if (snap.exists) return;

    final uid = firebaseUid;
    await ref.set({
      'userId': uid,
      'residenceId': _residenceId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'type': 'user_admin',
    }, SetOptions(merge: true));
  }

  Future<void> sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    final uid = firebaseUid;
    if (uid == null || _conversationId == null) return;

    isSending.value = true;
    messageController.clear();

    try {
      await _ensureConversationDoc();

      final messageData = <String, dynamic>{
        'text': text,
        'senderId': uid,
        'senderRole': _senderRole(),
        'senderName': _senderName(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(collectionName)
          .doc(_conversationId!)
          .collection('messages')
          .add(messageData);

      await _firestore.collection(collectionName).doc(_conversationId!).set({
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _scrollToBottom();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        chatState.value = AdminChatState.permissionDenied;
      } else if (e.code == 'unavailable') {
        chatState.value = AdminChatState.networkError;
      }
      messageController.text = text;
    } catch (e) {
      debugPrint('[AdminChatController] send error: $e');
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
