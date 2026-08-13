import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../utils/firebase_config_audit.dart';
import '../utils/firebase_jwt_debug.dart';
import '../utils/firebase_response_parser.dart';
import '../logging/diagnostic_logger.dart';

/// Centralized Firebase Auth for chat and FCM identity.
/// Laravel returns a custom token; Firebase UID must match Laravel `user.id` (string).
class FirebaseAuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _authStateSub;
  bool _signInLocked = false;

  /// Last known UID from auth state stream (kept in sync with [currentUser]).
  final RxnString firebaseUidObs = RxnString();

  User? get currentUser => _auth.currentUser;

  String? get firebaseUid => _auth.currentUser?.uid;

  bool get isSignedIn => _auth.currentUser != null;

  @override
  void onInit() {
    super.onInit();
    firebaseUidObs.value = _auth.currentUser?.uid;
    _authStateSub = _auth.authStateChanges().listen((user) {
      firebaseUidObs.value = user?.uid;
      debugPrint(
        '[FirebaseAuthService] authStateChanged uid=${user?.uid ?? "null"}',
      );
      final String? uid = user?.uid;
      DiagnosticLogger.instance.info(
        'Authentication state changed',
        metadata: <String, Object?>{
          'firebase_signed_in': user != null,
          'uid_available': uid != null && uid.isNotEmpty,
        },
      );
    });
  }

  @override
  void onClose() {
    _authStateSub?.cancel();
    super.onClose();
  }

  void _logClientFirebaseContext(String phase) {
    try {
      final app = _auth.app;
      final opts = app.options;
      debugPrint(
        '[FirebaseAuthService] $phase client projectId=${opts.projectId} '
        'appId=${opts.appId} messagingSenderId=${opts.messagingSenderId} '
        'appName=${app.name}',
      );
    } catch (e) {
      debugPrint('[FirebaseAuthService] $phase client context error: $e');
    }
    debugPrint(
      '[FirebaseAuthService] $phase Firebase.apps.length=${Firebase.apps.length}',
    );
    for (final a in Firebase.apps) {
      debugPrint(
        '[FirebaseAuthService] $phase registered app name=${a.name} projectId=${a.options.projectId}',
      );
    }
  }

  void _logCustomTokenClaims(String phase, String token) {
    final payload = FirebaseJwtDebug.decodePayload(token);
    debugPrint(
      '[FirebaseAuthService] $phase token ${FirebaseResponseParser.describeTokenPresence(token)}',
    );
    debugPrint(
      '[FirebaseAuthService] $phase JWT ${FirebaseJwtDebug.describeClaims(payload)}',
    );
    String? clientProjectId;
    try {
      clientProjectId = _auth.app.options.projectId;
    } catch (_) {}
    final hint = FirebaseJwtDebug.audienceMismatchHint(
      clientProjectId: clientProjectId,
      payload: payload,
    );
    if (hint != null) {
      debugPrint('[FirebaseAuthService] $phase $hint');
    }
  }

  /// Signs out then signs in with Laravel-issued custom token.
  /// Returns `true` when [currentUser] is non-null after sign-in.
  ///
  /// [expectedLaravelUserId] — if set, logs a warning when Firebase UID differs
  /// (misconfigured Admin SDK claims vs app expectation).
  Future<bool> signInWithCustomToken(
    String token, {
    String? expectedLaravelUserId,
  }) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      debugPrint(
        '[FirebaseAuthService] signInWithCustomToken: ABORT — empty token (${FirebaseResponseParser.describeTokenPresence(token)})',
      );
      DiagnosticLogger.instance.warning(
        'Firebase custom token sign-in skipped',
        metadata: <String, Object?>{'token_available': false},
      );
      return false;
    }

    if (Firebase.apps.isEmpty) {
      debugPrint(
        '[FirebaseAuthService] signInWithCustomToken: ABORT — Firebase.apps.isEmpty (initializeApp failed or not run)',
      );
      return false;
    }

    while (_signInLocked) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    _signInLocked = true;

    try {
      _logClientFirebaseContext('BEFORE signInWithCustomToken');
      _logCustomTokenClaims('BEFORE signInWithCustomToken', trimmed);

      debugPrint(
        '[FirebaseAuth] signInWithCustomToken START ${FirebaseResponseParser.describeTokenPresence(trimmed)}',
      );
      DiagnosticLogger.instance.info(
        'Firebase custom token sign-in started',
        metadata: <String, Object?>{'token_available': true},
      );
      await _auth.signOut();
      await _auth.signInWithCustomToken(trimmed);
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        debugPrint('[FirebaseAuth] FAILED — currentUser null after signIn');
        _logClientFirebaseContext('AFTER signIn FAIL (null user)');
        DiagnosticLogger.instance.error(
          'Firebase custom token sign-in failed',
          metadata: <String, Object?>{'reason': 'current_user_null'},
        );
        return false;
      }
      debugPrint(
        '[FirebaseAuth] SUCCESS uid=$uid projectId=${_auth.app.options.projectId}',
      );
      DiagnosticLogger.instance.info(
        'Firebase custom token sign-in completed',
        metadata: <String, Object?>{'uid_available': true},
      );
      if (expectedLaravelUserId != null &&
          expectedLaravelUserId.isNotEmpty &&
          expectedLaravelUserId != uid) {
        debugPrint(
          '[FirebaseAuthService] WARNING: Firebase UID ($uid) != Laravel user.id ($expectedLaravelUserId). '
          'Fix Laravel Admin SDK custom token claims (uid must be user id string).',
        );
      }
      return true;
    } on FirebaseAuthException catch (e, st) {
      debugPrint('[FirebaseAuth] FAILED');
      debugPrint('[FirebaseAuth] $e');
      debugPrint('[FirebaseAuth] stackTrace:\n$st');
      debugPrint(
        '[FirebaseAuthService] FirebaseAuthException code=${e.code} message=${e.message}',
      );
      DiagnosticLogger.instance.error(
        'Firebase custom token sign-in failed',
        error: e,
        stackTrace: st,
        metadata: <String, Object?>{'code': e.code},
      );
      _logClientFirebaseContext('AFTER signIn FAIL (${e.code})');
      _logCustomTokenClaims('AFTER signIn FAIL (${e.code})', trimmed);
      FirebaseConfigAudit.logStartupState();
      debugPrint('[FirebaseAuthService] stackTrace:\n$st');
      if (e.code == 'custom-token-mismatch') {
        debugPrint(
          '[FirebaseAuthService] FIX: Laravel Kreait service account JSON must be from the SAME '
          'Firebase project as this app (see JWT aud= vs client projectId= above). '
          'Android/iOS google-services must also use that project.',
        );
      }
      return false;
    } catch (e, st) {
      debugPrint('[FirebaseAuthService] signInWithCustomToken error: $e\n$st');
      DiagnosticLogger.instance.error(
        'Firebase custom token sign-in failed',
        error: e,
        stackTrace: st,
      );
      _logClientFirebaseContext('AFTER signIn FAIL (generic)');
      _logCustomTokenClaims('AFTER signIn FAIL (generic)', trimmed);
      return false;
    } finally {
      _signInLocked = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('[FirebaseAuthService] signOut: done');
    } catch (e) {
      debugPrint('[FirebaseAuthService] signOut error: $e');
    }
  }
}
