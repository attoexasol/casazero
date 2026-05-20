import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Logs Firebase app configuration for debugging project/token mismatches.
class FirebaseConfigAudit {
  FirebaseConfigAudit._();

  static void logStartupState() {
    debugPrint('[FirebaseAudit] ========== Firebase startup ==========');
    debugPrint('[FirebaseAudit] Firebase.apps.length=${Firebase.apps.length}');
    debugPrint(
      '[FirebaseAudit] DefaultFirebaseOptions.android.projectId=${DefaultFirebaseOptions.android.projectId}',
    );
    debugPrint(
      '[FirebaseAudit] DefaultFirebaseOptions.ios.projectId=${DefaultFirebaseOptions.ios.projectId}',
    );
    if (DefaultFirebaseOptions.android.projectId !=
        DefaultFirebaseOptions.ios.projectId) {
      debugPrint(
        '[FirebaseAudit] ⚠ PLATFORM PROJECT MISMATCH: Android=${DefaultFirebaseOptions.android.projectId} '
        'iOS=${DefaultFirebaseOptions.ios.projectId} — update ios/Runner/GoogleService-Info.plist '
        'and ios section in firebase_options.dart to casazero-a39ba',
      );
    }

    for (final app in Firebase.apps) {
      final o = app.options;
      debugPrint(
        '[FirebaseAudit] app name=${app.name} projectId=${o.projectId} '
        'appId=${o.appId} messagingSenderId=${o.messagingSenderId} '
        'storageBucket=${o.storageBucket}',
      );
    }

    try {
      final authApp = FirebaseAuth.instance.app;
      debugPrint(
        '[FirebaseAudit] FirebaseAuth.instance.app.name=${authApp.name} '
        'projectId=${authApp.options.projectId}',
      );
      debugPrint(
        '[FirebaseAudit] FirebaseAuth.currentUser.uid=${FirebaseAuth.instance.currentUser?.uid ?? "null"}',
      );
    } catch (e) {
      debugPrint('[FirebaseAudit] FirebaseAuth inspect error: $e');
    }
    debugPrint('[FirebaseAudit] ========================================');
  }
}
