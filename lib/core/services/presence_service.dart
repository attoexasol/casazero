import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../utils/firebase_error_handler.dart';

enum PresenceWriteIntent { online, offline }

/// Tracks online/offline presence in Firestore `presence/user_{id}`.
/// Never throws; retries when auth/network recovers.
class PresenceService with WidgetsBindingObserver {
  static const String logTag = 'PresenceService';
  static const String collectionName = 'presence';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StreamSubscription<User?>? _authSub;
  _PresenceLifecycleBinding? _lifecycleBinding;
  Timer? _retryTimer;

  int? _boundUserId;
  PresenceWriteIntent? _pendingIntent;
  bool _writesBlocked = false;
  int _retryAttempt = 0;

  PresenceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static String documentIdFor(int userId) => 'user_$userId';

  String _presencePath(int userId) => '$collectionName/${documentIdFor(userId)}';

  DocumentReference<Map<String, dynamic>> _ref(int userId) {
    return _firestore.collection(collectionName).doc(documentIdFor(userId));
  }

  bool get _canWrite {
    if (_writesBlocked) return false;
    return _auth.currentUser != null;
  }

  Future<void> setOnline(int userId) async {
    await _writePresence(userId, online: true);
  }

  Future<void> setOffline(int userId) async {
    await _writePresence(userId, online: false);
  }

  Future<void> _writePresence(int userId, {required bool online}) async {
    _pendingIntent = online ? PresenceWriteIntent.online : PresenceWriteIntent.offline;

    if (!_canWrite) {
      debugPrint(
        '[$logTag] Deferring presence write userId=$userId online=$online '
        '(auth=${_auth.currentUser?.uid ?? 'null'})',
      );
      _scheduleRetry();
      return;
    }

    final path = _presencePath(userId);
    try {
      await _ref(userId).set({
        'online': online,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _pendingIntent = null;
      _retryAttempt = 0;
      _cancelRetryTimer();
      debugPrint(
        '[$logTag] path=$path userId=$userId online=$online success',
      );
    } on FirebaseException catch (e) {
      FirebaseErrorHandler.log(
        tag: logTag,
        error: e,
        firestorePath: path,
        userId: userId.toString(),
      );
      if (e.code == 'permission-denied') {
        _writesBlocked = true;
        _pendingIntent = null;
        debugPrint(
          '[$logTag] Presence writes disabled for session (permission-denied) '
          'userId=$userId authUid=${_auth.currentUser?.uid}',
        );
        return;
      }
      _scheduleRetry();
    } catch (e) {
      FirebaseErrorHandler.log(
        tag: logTag,
        error: e,
        firestorePath: path,
        userId: userId.toString(),
      );
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_boundUserId == null || _pendingIntent == null || _writesBlocked) {
      return;
    }
    _cancelRetryTimer();
    _retryAttempt++;
    final delay = Duration(seconds: (2 * _retryAttempt).clamp(2, 30));
    debugPrint(
      '[$logTag] Scheduling presence retry in ${delay.inSeconds}s '
      'userId=$_boundUserId intent=$_pendingIntent',
    );
    _retryTimer = Timer(delay, _flushPendingWrite);
  }

  void _flushPendingWrite() {
    final userId = _boundUserId;
    final intent = _pendingIntent;
    if (userId == null || intent == null) return;

    if (intent == PresenceWriteIntent.online) {
      unawaited(setOnline(userId));
    } else {
      unawaited(setOffline(userId));
    }
  }

  void _cancelRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _listenAuthRecovery() {
    _authSub?.cancel();
    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null && _boundUserId != null) {
        _writesBlocked = false;
        final intent = _pendingIntent ??
            (_lifecycleBinding?.isForeground == true
                ? PresenceWriteIntent.online
                : PresenceWriteIntent.offline);
        if (intent == PresenceWriteIntent.online) {
          unawaited(setOnline(_boundUserId!));
        } else {
          unawaited(setOffline(_boundUserId!));
        }
      }
    });
  }

  Stream<bool> streamOnlineStatus(int userId) {
    return _ref(userId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return false;
      return data['online'] == true;
    }).handleError((Object error) {
      FirebaseErrorHandler.log(
        tag: logTag,
        error: error,
        firestorePath: _presencePath(userId),
        userId: userId.toString(),
      );
    });
  }

  /// Lifecycle-aware presence for the signed-in resident.
  void bindLifecycle(int userId) {
    if (_boundUserId == userId && _lifecycleBinding != null) return;

    _boundUserId = userId;
    _writesBlocked = false;
    _listenAuthRecovery();

    _lifecycleBinding?.detach();
    _lifecycleBinding = _PresenceLifecycleBinding(
      service: this,
      userId: userId,
    )..attach();

    unawaited(setOnline(userId));
  }

  void _onLifecycleForeground(int userId) {
    _lifecycleBinding?.isForeground = true;
    unawaited(setOnline(userId));
  }

  void _onLifecycleBackground(int userId) {
    _lifecycleBinding?.isForeground = false;
    unawaited(setOffline(userId));
  }

  void dispose() {
    final userId = _boundUserId;
    if (userId != null) {
      unawaited(setOffline(userId));
    }
    _authSub?.cancel();
    _cancelRetryTimer();
    _lifecycleBinding?.detach();
    _lifecycleBinding = null;
    _boundUserId = null;
    _pendingIntent = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userId = _boundUserId;
    if (userId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _onLifecycleForeground(userId);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _onLifecycleBackground(userId);
        break;
      case AppLifecycleState.detached:
        _onLifecycleBackground(userId);
        break;
    }
  }
}

class _PresenceLifecycleBinding {
  _PresenceLifecycleBinding({
    required this.service,
    required this.userId,
  });

  final PresenceService service;
  final int userId;
  bool isForeground = true;

  void attach() => WidgetsBinding.instance.addObserver(service);

  void detach() => WidgetsBinding.instance.removeObserver(service);
}
