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
  Future<void> signInWithCustomToken(String token) async {
    final credential =
        await FirebaseAuth.instance.signInWithCustomToken(token);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('🔥 Firebase sign-in completed. UID = $uid');
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
