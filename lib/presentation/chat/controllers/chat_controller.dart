import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/firebase_config_audit.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../core/utils/permissions.dart';
import '../../../data/models/user_model.dart';
import '../../home/controllers/home_controller.dart';
import '../../profile/controllers/profile_controller.dart';
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
  final ApiService _apiService = Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ChatMessage>>? _messagesStream;
  StreamSubscription<User?>? _authStateSub;
  int _messageSnapshotLogCount = 0;
  final RxBool isSending = false.obs;
  final Rx<ChatState> chatState = ChatState.initial.obs;
  final RxString residenceName = ''.obs;

  String? _groupId;

  @override
  void onInit() {
    super.onInit();
    messageController.addListener(_onMessageChanged);
    _resolveGroupId();
    _listenFirebaseAuthForChat();
    unawaited(_initChatWhenFirebaseReady());
    _fetchResidenceName();
    _ensureProfileLoadedForChatAvatar();
  }

  /// Fetches current user profile from API so chat messages can include profile image.
  /// Profile screen uses the same API; this ensures we have the latest profile_image when sending.
  void _ensureProfileLoadedForChatAvatar() {
    if (_groupId == null) return;
    try {
      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();
        // Refresh from API so we have latest profile_image (same as profile screen).
        profileController.refreshData();
      }
    } catch (_) {}
  }

  Future<void> _fetchResidenceName() async {
    if (_groupId == null || !_groupId!.startsWith('group_')) return;
    final idStr = _groupId!.replaceFirst('group_', '');
    final residenceId = int.tryParse(idStr);
    if (residenceId == null) return;
    try {
      final endpoint = '${ApiConstants.GET_SINGLE_RESIDENCE}/$residenceId';
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200 &&
          response.data['status'] == true &&
          response.data['data'] != null) {
        final name = response.data['data']['residence_name']?.toString();
        if (name != null && name.isNotEmpty) {
          residenceName.value = name;
        }
      }
    } catch (_) {
      residenceName.value = '';
    }
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

  /// Waits for Firebase auth before attaching Firestore listeners.
  Future<void> _initChatWhenFirebaseReady() async {
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('[ChatController] Firebase user missing — syncing from stored login token');
      await retryFirebaseAuthForChat();
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      debugPrint('[ChatController] Firebase user missing — chat blocked');
      chatState.value = ChatState.noAuth;
      _messagesStream = Stream.value([]);
      _logFirebaseUidNullDiagnostics(
        reason: '_initChatWhenFirebaseReady — no Firebase user after sync',
      );
      return;
    }

    debugPrint(
      '[ChatController] Firebase ready uid=${firebaseUser.uid} — starting chat',
    );
    _subscribeToMessages();
  }

  /// Full terminal dump when chat cannot run because Firebase UID is missing.
  void _logFirebaseUidNullDiagnostics({required String reason}) {
    debugPrint('');
    debugPrint('══════════════════════════════════════════════════════════');
    debugPrint('❌ [ChatController] FIREBASE UID NULL — DEBUG REPORT');
    debugPrint('══════════════════════════════════════════════════════════');
    debugPrint('  trigger: $reason');
    debugPrint('  chatState: ${chatState.value}');
    debugPrint('  groupId: ${_groupId ?? "null"}');

    // Laravel session (chat uses Firebase UID = Laravel user.id string)
    final userData = _storageService.getUserData();
    final laravelUserId = userData?['id']?.toString();
    final accessToken = _storageService.getAccessToken();
    debugPrint('  ── Laravel / local session ──');
    debugPrint('  laravelUser.id (expected Firebase uid): ${laravelUserId ?? "null"}');
    debugPrint(
      '  apiAccessToken: ${accessToken != null && accessToken.isNotEmpty ? "present len=${accessToken.length}" : "MISSING"}',
    );
    debugPrint('  userData keys: ${userData?.keys.join(", ") ?? "null"}');
    debugPrint(
      '  stored firebase_token: ${_storageService.getStoredFirebaseToken() != null ? "present" : "MISSING — re-login required"}',
    );

    // FirebaseAuthService wrapper
    debugPrint('  ── FirebaseAuthService ──');
    debugPrint('  isSignedIn: ${_firebaseAuthService.isSignedIn}');
    debugPrint('  firebaseUid (service): ${_firebaseAuthService.firebaseUid ?? "null"}');
    debugPrint(
      '  firebaseUidObs: ${_firebaseAuthService.firebaseUidObs.value ?? "null"}',
    );
    debugPrint(
      '  currentUser (service): ${_firebaseAuthService.currentUser?.uid ?? "null"}',
    );

    // Raw Firebase Auth
    debugPrint('  ── FirebaseAuth.instance ──');
    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('  currentUser.uid: ${user?.uid ?? "null"}');
      debugPrint('  currentUser.email: ${user?.email ?? "null"}');
      debugPrint('  currentUser.isAnonymous: ${user?.isAnonymous ?? "n/a"}');
      debugPrint(
        '  currentUser.metadata.lastSignInTime: ${user?.metadata.lastSignInTime}',
      );
    } catch (e) {
      debugPrint('  currentUser read error: $e');
    }

    // Firebase Core / project (custom-token-mismatch shows here)
    debugPrint('  ── Firebase.initializeApp ──');
    debugPrint('  Firebase.apps.isEmpty: ${Firebase.apps.isEmpty}');
    debugPrint('  Firebase.apps.length: ${Firebase.apps.length}');
    if (Firebase.apps.isNotEmpty) {
      for (final app in Firebase.apps) {
        final o = app.options;
        debugPrint(
          '  app name=${app.name} projectId=${o.projectId} appId=${o.appId}',
        );
      }
      try {
        debugPrint(
          '  Firestore project: ${_firestore.app.options.projectId}',
        );
      } catch (e) {
        debugPrint('  Firestore app error: $e');
      }
    } else {
      debugPrint('  ⚠ Firebase never initialized — check main.dart logs');
    }

    debugPrint('  ── Likely causes (check logs above this block) ──');
    if (Firebase.apps.isEmpty) {
      debugPrint('  • Firebase.initializeApp failed or timed out at startup');
    }
    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('  • No Laravel API token — login did not complete');
    } else if (!_firebaseAuthService.isSignedIn) {
      debugPrint('  • Laravel session OK but Firebase sign-in never succeeded');
      debugPrint('  • Look for [FirebaseAuthService] signInWithCustomToken FAIL');
      debugPrint('  • Common: custom-token-mismatch (Laravel wrong Firebase project)');
      debugPrint('  • Fix: call syncFirebaseAuthAfterLogin after login/splash');
    }
    if (laravelUserId != null &&
        _firebaseAuthService.firebaseUid != null &&
        laravelUserId != _firebaseAuthService.firebaseUid) {
      debugPrint(
        '  • UID mismatch: Laravel id=$laravelUserId vs Firebase uid=${_firebaseAuthService.firebaseUid}',
      );
    }

    debugPrint('══════════════════════════════════════════════════════════');
    debugPrint('');

    FirebaseConfigAudit.logStartupState();
  }

  /// Retry Firebase custom token sign-in when chat opens without a UID.
  Future<void> retryFirebaseAuthForChat() async {
    debugPrint('[ChatController] retryFirebaseAuthForChat: start');
    try {
      if (!Get.isRegistered<AuthRepository>()) {
        debugPrint('[ChatController] retryFirebaseAuthForChat: AuthRepository not registered');
        return;
      }
      final authRepo = Get.find<AuthRepository>();
      await authRepo.syncFirebaseAuthAfterLogin();
      if (_firebaseAuthService.isSignedIn) {
        debugPrint(
          '[ChatController] retryFirebaseAuthForChat: SUCCESS uid=${_firebaseAuthService.firebaseUid}',
        );
        if (FirebaseAuth.instance.currentUser == null) {
          debugPrint('[ChatController] Firebase auth missing after reported success');
          return;
        }
        _subscribeToMessages();
      } else {
        _logFirebaseUidNullDiagnostics(
          reason: 'retryFirebaseAuthForChat completed but still unsigned',
        );
      }
    } catch (e, st) {
      debugPrint('[ChatController] retryFirebaseAuthForChat error: $e\n$st');
      _logFirebaseUidNullDiagnostics(reason: 'retryFirebaseAuthForChat threw');
    }
  }

  void _listenFirebaseAuthForChat() {
    _authStateSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint(
        '[ChatController] Firebase authState uid=${user?.uid ?? "null"} groupId=$_groupId',
      );
      if (user == null) {
        chatState.value = ChatState.noAuth;
        _messagesStream = Stream.value([]);
        _logFirebaseUidNullDiagnostics(reason: 'authStateChanges emitted null user');
        return;
      }
      if (_groupId == null) return;
      if (chatState.value == ChatState.noAuth) {
        debugPrint('[ChatController] auth became available — binding Firestore stream');
        _subscribeToMessages();
      }
    });
  }

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

    if (FirebaseAuth.instance.currentUser == null) {
      _logFirebaseUidNullDiagnostics(
        reason: '_subscribeToMessages — FirebaseAuth.instance.currentUser is null',
      );
      chatState.value = ChatState.noAuth;
      _messagesStream = Stream.value([]);
      return;
    }

    final uid = firebaseUid;
    if (uid == null) {
      _logFirebaseUidNullDiagnostics(
        reason: '_subscribeToMessages called with null firebaseUid',
      );
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
      debugPrint('✅ [ChatController] Group validation passed — attaching messages listener');
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
        .map((snapshot) {
          _messageSnapshotLogCount++;
          if (kDebugMode && _messageSnapshotLogCount <= 3) {
            debugPrint(
              '[ChatController] messages snapshot #$_messageSnapshotLogCount '
              'docs=${snapshot.docs.length} hasPendingWrites=${snapshot.metadata.hasPendingWrites}',
            );
            for (final doc in snapshot.docs.take(3)) {
              final d = doc.data();
              debugPrint(
                '[ChatController] sample msg id=${doc.id} '
                'senderId=${d['senderId'] ?? d['sender_id']} '
                'senderRole=${d['senderRole'] ?? d['sender_role']} '
                'role=${d['role']} is_admin=${d['is_admin'] ?? d['isAdmin']}',
              );
            }
          }
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }

  Stream<List<ChatMessage>> get messagesStream =>
      _messagesStream ?? Stream.value([]);

  String get groupId => _groupId ?? '';

  bool get isFirebaseSignedIn => _firebaseAuthService.isSignedIn;

  String? get firebaseUid => _firebaseAuthService.firebaseUid;

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

  bool get isCurrentUserStaff {
    final role = _currentUserRole();
    return role == Role.admin || role == Role.manager;
  }

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
    final stored = _storageService.getUserData()?['user_name']?.toString().trim();
    if (stored != null && stored.isNotEmpty) return stored;
    return 'You';
  }

  int? _currentUserId() {
    if (Get.isRegistered<HomeController>()) {
      final id = Get.find<HomeController>().currentUser.value?.id;
      if (id != null && id > 0) return id;
    }
    final raw = _storageService.getUserData()?['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  Future<void> _notifyGroupChatMessage({required String body}) async {
    final senderId = _currentUserId();
    if (senderId == null) return;

    try {
      if (!Get.isRegistered<NotificationRepository>()) return;
      await Get.find<NotificationRepository>().sendChatNotification(
        receiverId: 0,
        senderId: senderId,
        title: 'notification_new_message'.tr,
        body: body,
        data: {
          'type': 'group_chat',
          'group_id': groupId,
        },
      );
    } catch (e) {
      debugPrint('[ChatController] Chat notification failed: $e');
    }
  }

  Future<void> sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    final uid = firebaseUid;
    if (uid == null) {
      _logFirebaseUidNullDiagnostics(
        reason: 'sendTextMessage called with null firebaseUid',
      );
      return;
    }
    if (_groupId == null || _groupId!.isEmpty) {
      debugPrint('[ChatController] sendTextMessage: blocked — no groupId');
      return;
    }

    isSending.value = true;
    messageController.clear();

    try {
      // Prefer profile from API (ProfileController) – same source as profile screen.
      String? profileImage;
      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();
        profileImage = profileController.user.value?.profileImage?.trim();
      }
      if (profileImage == null || profileImage.isEmpty) {
        final userData = _storageService.getUserData();
        profileImage = userData?['profile_image']?.toString().trim();
      }
      final bool hasProfileImage = profileImage != null &&
          profileImage.isNotEmpty &&
          (profileImage.startsWith('http://') ||
              profileImage.startsWith('https://'));

      final Map<String, dynamic> messageData = {
        'text': text,
        'senderId': uid,
        'senderRole': _senderRole(),
        'senderName': _senderName(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (hasProfileImage) {
        messageData['senderProfileImage'] = profileImage;
      }

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add(messageData);
      debugPrint(
        '[ChatController] message sent group=$groupId senderId=$uid '
        'senderRole=${messageData['senderRole']} senderName=${messageData['senderName']} '
        'appRole=${_currentUserRole()?.name ?? "unknown"} chars=${text.length}',
      );
      await _notifyGroupChatMessage(body: text);
      _scrollToBottom();
    } on FirebaseException catch (e) {
      debugPrint(
        '[ChatController] sendTextMessage FirebaseException code=${e.code} message=${e.message}',
      );
      if (e.code == 'permission-denied') {
        chatState.value = ChatState.permissionDenied;
      } else if (e.code == 'unavailable') {
        chatState.value = ChatState.networkError;
      }
      messageController.text = text;
    } catch (e) {
      debugPrint('[ChatController] sendTextMessage error: $e');
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
