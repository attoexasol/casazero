import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/storage_service.dart';
import '../../home/controllers/home_controller.dart';
import '../models/chat_message_model.dart';

class ChatController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final StorageService _storageService = Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<ChatMessage>>? _messagesStream;
  final RxBool isSending = false.obs;
  final RxBool isUploadingImage = false.obs;

  String? _groupId;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserRole;

  @override
  void onInit() {
    super.onInit();
    messageController.addListener(_onMessageChanged);
    _initCurrentUser();
    _resolveGroupId();
    _subscribeToMessages();
    final fbUser = FirebaseAuth.instance.currentUser;
    print('🔥 FIREBASE UID = ${fbUser?.uid}');
  }

  @override
  void onClose() {
    messageController.removeListener(_onMessageChanged);
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onMessageChanged() => update(['input']);

  void _initCurrentUser() {
    final userData = _storageService.getUserData();
    _currentUserId = userData?['id']?.toString();
    _currentUserName = userData?['user_name']?.toString() ?? 'You';
    final role = userData?['role']?.toString() ?? 'client';
    _currentUserRole = role == 'admin' ? 'admin' : 'resident';
  }

  void _resolveGroupId() {
    try {
      final homeController = Get.find<HomeController>();
      final residence = homeController.selectedResidence.value;
      if (residence != null) {
        _groupId = 'group_${residence.id}';
      } else {
        final userData = _storageService.getUserData();
        final residenceId = userData?['residence_id'] ?? userData?['unit_id'];
        _groupId = residenceId != null ? 'group_$residenceId' : 'group_1';
      }
      print('💬 [ChatController] Group ID: $_groupId');
    } catch (e) {
      _groupId = 'group_1';
      print('⚠️ [ChatController] Using default group_1: $e');
    }
  }

  void _subscribeToMessages() {
    if (_groupId == null) return;
    _messagesStream = streamMessages(_groupId!);
  }

  /// Stream messages from Firestore (real-time)
  Stream<List<ChatMessage>> streamMessages(String groupId) {
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

  String get groupId => _groupId ?? 'group_1';

  bool get isFirebaseSignedIn => FirebaseAuth.instance.currentUser != null;

  String get currentUserId => _currentUserId ?? '';

  bool isOwnMessage(String senderId) =>
      _currentUserId != null && senderId == _currentUserId;

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

  Future<void> sendText() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    if (!isFirebaseSignedIn) {
      print('⚠️ [ChatController] Cannot send: not signed in to Firebase');
      return;
    }
    if (_currentUserId == null || _currentUserName == null) {
      print('⚠️ [ChatController] Cannot send: user data missing');
      return;
    }

    isSending.value = true;
    messageController.clear();

    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add({
        'senderId': _currentUserId,
        'senderName': _currentUserName,
        'senderRole': _currentUserRole ?? 'resident',
        'type': 'chat',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    } catch (e) {
      print('❌ [ChatController] Send text error: $e');
      messageController.text = text; // Restore on error
    } finally {
      isSending.value = false;
      update(['input']);
    }
  }

  Future<void> sendImage() async {
    if (!isFirebaseSignedIn) {
      print('⚠️ [ChatController] Cannot send image: not signed in to Firebase');
      return;
    }
    if (_currentUserId == null || _currentUserName == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    isUploadingImage.value = true;
    try {
      final file = File(picked.path);
      final ref = _storage
          .ref()
          .child('chat')
          .child(groupId)
          .child('${DateTime.now().millisecondsSinceEpoch}_${picked.name}');

      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add({
        'senderId': _currentUserId,
        'senderName': _currentUserName,
        'senderRole': _currentUserRole ?? 'resident',
        'type': 'image',
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    } catch (e) {
      print('❌ [ChatController] Send image error: $e');
    } finally {
      isUploadingImage.value = false;
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
