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
  /// Always signs out first to ensure correct user when switching accounts (uid 17 vs 19).
  Future<void> signInWithCustomToken(String token) async {
    if (token.isEmpty) return;

    // Always sign out first so account switch works: if user 19 was signed in
    // and user 17 logs in, we must clear 19 and sign in 17 (skip caused wrong UID).
    await FirebaseAuth.instance.signOut();

    await FirebaseAuth.instance.signInWithCustomToken(token);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('Firebase UID after login: $uid');
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
