import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../controllers/message_popup_controller.dart';
import '../navigation/auth_navigation.dart';
import 'fcm_service.dart';
import 'firebase_auth_service.dart';
import 'storage_service.dart';
import '../logging/diagnostic_logger.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../presentation/profile/controllers/profile_controller.dart';

/// Handles forced sign-out when the backend rejects an authenticated request.
class SessionExpiryService {
  SessionExpiryService._();

  static const String sessionExpiredMessageKey =
      'session_expired_sign_in_again';

  static bool _isHandling = false;
  static bool _isSigningOut = false;

  /// Call at the start of an explicit logout so in-flight 401s do not trigger
  /// a second forced sign-out while navigation to the auth screen is underway.
  static void beginForcedSignOut() {
    _isHandling = true;
    _isSigningOut = true;
  }

  /// Resets the guard after a successful login so future expirations are handled.
  static void reset() {
    _isHandling = false;
    _isSigningOut = false;
  }

  static bool get isHandling => _isHandling;
  static bool get isSigningOut => _isSigningOut;

  /// Clears local session, navigates to login, and shows the expiry message once.
  static Future<void> handleSessionExpired() async {
    if (_isHandling) return;
    _isHandling = true;
    DiagnosticLogger.instance.info('Session expired — signing out');

    try {
      final storage = Get.find<StorageService>();

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().clearStateOnLogout();
      }
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().user.value = null;
      }

      try {
        if (Get.isRegistered<FirebaseAuthService>()) {
          await Get.find<FirebaseAuthService>().signOut();
        }
      } catch (_) {}

      try {
        if (Get.isRegistered<FcmService>()) {
          await Get.find<FcmService>().deleteToken();
        }
      } catch (_) {}

      await storage.clearAll();

      AuthNavigation.replaceStackWithAuth();

      SchedulerBinding.instance.addPostFrameCallback((_) {
        MessagePopupController.showError(
          messageKey: sessionExpiredMessageKey,
          titleKey: 'error',
        );
      });
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [SessionExpiryService] Error handling session expiry: $e');
      DiagnosticLogger.instance.error(
        'Session expiry handling failed',
        error: e,
      );
      try {
        if (Get.isRegistered<StorageService>()) {
          await Get.find<StorageService>().clearAll();
        }
        AuthNavigation.replaceStackWithAuth();
      } catch (_) {}
    }
  }
}
