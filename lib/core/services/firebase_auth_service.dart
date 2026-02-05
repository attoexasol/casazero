import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:get/get.dart';

/// Centralized Firebase Auth for chat.
/// Laravel returns firebase_token; Flutter signs in via custom token.
/// Firebase UID MUST match Laravel user ID (string, e.g. "19").
/// On iOS, currentUser can lag; we store UID from credential as fallback.
class FirebaseAuthService extends GetxService {
  /// Stored UID from last successful sign-in (iOS fallback when currentUser lags).
  String? _lastSignedInUid;

  /// Firebase UID. Uses credential fallback on iOS when currentUser is null.
  String? get firebaseUid =>
      _lastSignedInUid ?? FirebaseAuth.instance.currentUser?.uid;

  bool get isSignedIn =>
      _lastSignedInUid != null ||
      FirebaseAuth.instance.currentUser != null;

  /// Call immediately after Laravel login success. Must be awaited before navigation.
  Future<void> signInWithCustomToken(String token) async {
    debugPrint(
      '🔥 signInWithCustomToken: Platform=$defaultTargetPlatform, token length=${token.length}',
    );

    final credential =
        await FirebaseAuth.instance.signInWithCustomToken(token);

    final user = credential.user;
    if (user == null) {
      debugPrint('❌ signInWithCustomToken returned null user. Failing loudly.');
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Firebase sign-in returned null user',
      );
    }

    _lastSignedInUid = user.uid;
    debugPrint('🔥 Firebase sign-in completed. UID = $_lastSignedInUid');
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint('🔥 iOS Firebase UID: $_lastSignedInUid');
    }
  }

  Future<void> signOut() async {
    _lastSignedInUid = null;
    await FirebaseAuth.instance.signOut();
  }
}
