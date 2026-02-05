import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Centralized Firebase Auth for chat.
/// Laravel returns firebase_token; Flutter signs in via custom token.
/// Firebase UID MUST match Laravel user ID (string, e.g. "19").
class FirebaseAuthService extends GetxService {
  /// Firebase UID. Null until signInWithCustomToken succeeds.
  String? get firebaseUid => FirebaseAuth.instance.currentUser?.uid;

  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  /// Call immediately after Laravel login success. Must be awaited before navigation.
  /// Avoids duplicate sign-in when already signed in with the same UID.
  Future<void> signInWithCustomToken(String token) async {
    if (token.isEmpty) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null) {
      debugPrint('🔥 Firebase already signed in. UID = $currentUid (skipping duplicate sign-in)');
      return;
    }

    await FirebaseAuth.instance.signInWithCustomToken(token);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('Firebase UID after login: $uid');
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
