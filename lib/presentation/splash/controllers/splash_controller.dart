// lib/presentation/splash/controllers/splash_controller.dart
// UPDATED VERSION with auto-login functionality

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/auth/pending_2fa_policy.dart';
import '../../../core/navigation/auth_navigation.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/session_expiry_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/logging/diagnostic_logger.dart';

class SplashController extends GetxController {
  final StorageService _storageService = Get.find();
  Timer? _timer;
  bool _navigationStarted = false;

  @override
  void onInit() {
    super.onInit();
    DiagnosticLogger.instance.debug('🟢 SplashController: onInit called');
    _startSplashTimer();
  }

  void _startSplashTimer() {
    DiagnosticLogger.instance.debug('🟢 SplashController: Starting 3.5 second timer');

    // Auto-transition after 3.5 seconds
    _timer = Timer(const Duration(milliseconds: 3500), () {
      DiagnosticLogger.instance.debug('🟢 SplashController: Timer completed, checking authentication');
      _checkAuthenticationAndNavigate();
    });
  }

  bool get _shouldAbortNavigation =>
      isClosed ||
      _navigationStarted ||
      SessionExpiryService.isHandling ||
      SessionExpiryService.isSigningOut;

  /// Check if user is already authenticated and navigate accordingly
  void _checkAuthenticationAndNavigate() async {
    if (_shouldAbortNavigation) {
      DiagnosticLogger.instance.debug('🔐 SplashController: Skipping auth check — already navigating/signed out');
      return;
    }

    DiagnosticLogger.instance.debug('🔐 SplashController: Checking authentication status...');
    DiagnosticLogger.instance.info('Session restore started');

    // Check for stored access token
    final accessToken = _storageService.getAccessToken();
    final userData = _storageService.getUserData();
    final phase = _storageService.getAuthPhase();

    DiagnosticLogger.instance.debug('  - Access Token: ${accessToken != null ? "Found" : "Not found"}');
    DiagnosticLogger.instance.debug('  - User Data: ${userData != null ? "Found" : "Not found"}');
    DiagnosticLogger.instance.debug('  - Auth Phase: ${phase.name}');

    final destination = Pending2FAPolicy.splashDestination(
      accessToken: accessToken,
      userData: userData,
      phase: phase,
    );

    if (destination == AppRoutes.OTP_VERIFICATION) {
      // A stored token only proves the password step. If the login-time 2FA
      // challenge was never completed (app killed on the OTP screen), resume
      // at OTP — never HOME. Authenticated initialization (Firebase sign-in,
      // FCM refresh) is deferred until OTP succeeds.
      DiagnosticLogger.instance.warning('  ⚠️ 2FA pending from previous session - resuming OTP verification');
      DiagnosticLogger.instance.info(
        'Existing session found',
        metadata: <String, Object?>{
          'phase': phase.name,
          'destination': 'otp',
        },
      );
      DiagnosticLogger.instance.info('Session restore completed');
      _navigateToOtpVerification();
      return;
    }

    if (destination == AppRoutes.HOME) {
      final hasFirebaseToken =
          _storageService.getStoredFirebaseToken() != null;
      DiagnosticLogger.instance.debug('  - Stored firebase_token: ${hasFirebaseToken ? "Found" : "MISSING — log out and log in again"}');
      DiagnosticLogger.instance.info(
        'Existing session found',
        metadata: <String, Object?>{
          'phase': phase.name,
          'firebase_token_available': hasFirebaseToken,
        },
      );
      _storageService.debugPrintStorageKeys();
      await _ensureFirebaseSignedIn();
      if (_shouldAbortNavigation) return;

      await _registerFcmTokenAfterSessionRestore();
      if (_shouldAbortNavigation) return;

      // Session may have been cleared by a 401 during Firebase/FCM restore.
      final tokenAfterRestore = _storageService.getAccessToken();
      if (tokenAfterRestore == null || tokenAfterRestore.isEmpty) {
        DiagnosticLogger.instance.error('  ❌ Session cleared during restore - navigating to AUTH');
        DiagnosticLogger.instance.error(
          'Session restore failed',
          metadata: <String, Object?>{'reason': 'session_cleared_during_restore'},
        );
        _navigateToAuth();
        return;
      }

      DiagnosticLogger.instance.info('  ✅ User authenticated - navigating to HOME');
      DiagnosticLogger.instance.info('Session restore completed');
      _navigateToHome();
      return;
    }

    // No authentication data - navigate to AUTH
    DiagnosticLogger.instance.error('  ❌ No authentication found - navigating to AUTH');
    DiagnosticLogger.instance.info('No session found');
    DiagnosticLogger.instance.info('Session restore completed');
    _navigateToAuth();
  }

  void _navigateToOtpVerification() {
    if (_shouldAbortNavigation) return;
    _navigationStarted = true;
    DiagnosticLogger.instance.info(
      '🟢 SplashController: Attempting navigation to: ${AppRoutes.OTP_VERIFICATION}',
    );

    try {
      Get.offAllNamed(AppRoutes.OTP_VERIFICATION);
      DiagnosticLogger.instance.error('✅ SplashController: Navigation to OTP_VERIFICATION successful');
    } catch (e) {
      DiagnosticLogger.instance.error('❌ SplashController: Navigation to OTP_VERIFICATION failed: $e');
      // Fallback — never fall through to HOME while 2FA is pending.
      _navigationStarted = false;
      _navigateToAuth();
    }
  }

  /// Refresh local FCM token when restoring an existing session.
  Future<void> _registerFcmTokenAfterSessionRestore() async {
    try {
      if (Get.isRegistered<FcmService>()) {
        await Get.find<FcmService>().registerAfterAuth();
      }
    } catch (e) {
      debugPrint('  [Splash] FCM token registration failed: $e');
      DiagnosticLogger.instance.error(
        'FCM registration after session restore failed',
        error: e,
      );
    }
  }

  /// When app restarts with valid session, Firebase Auth may have been cleared.
  /// Resolves custom token from Laravel and signs in so chat works.
  Future<void> _ensureFirebaseSignedIn() async {
    try {
      final authRepo = Get.find<AuthRepository>();
      final ok = await authRepo.syncFirebaseAuthAfterLogin();
      final fb = Get.find<FirebaseAuthService>();
      if (ok && fb.isSignedIn) {
        debugPrint('  [Splash] Firebase signed in uid=${fb.firebaseUid}');
        DiagnosticLogger.instance.info(
          'Firebase auth signed in',
          metadata: <String, Object?>{'uid_available': true},
        );
      } else {
        debugPrint(
          '  [Splash] Firebase not signed in (syncOk=$ok) — uses stored login firebase_token if available',
        );
        DiagnosticLogger.instance.warning(
          'Firebase auth not signed in after session restore',
          metadata: <String, Object?>{'sync_ok': ok},
        );
      }
    } catch (e) {
      debugPrint('  [Splash] Firebase sign-in on splash failed: $e');
      DiagnosticLogger.instance.error(
        'Firebase sign-in on session restore failed',
        error: e,
      );
    }
  }

  void _navigateToHome() {
    if (_shouldAbortNavigation) return;
    _navigationStarted = true;
    DiagnosticLogger.instance.info('🟢 SplashController: Attempting navigation to: ${AppRoutes.HOME}');

    try {
      // Use Get.offAllNamed to clear splash from navigation stack
      Get.offAllNamed(AppRoutes.HOME);
      DiagnosticLogger.instance.error('✅ SplashController: Navigation to HOME successful');
    } catch (e) {
      DiagnosticLogger.instance.error('❌ SplashController: Navigation to HOME failed: $e');
      // Fallback - navigate to AUTH if HOME navigation fails
      _navigationStarted = false;
      _navigateToAuth();
    }
  }

  void _navigateToAuth() {
    if (isClosed) return;
    _navigationStarted = true;
    DiagnosticLogger.instance.info('🟢 SplashController: Attempting navigation to: ${AppRoutes.AUTH}');
    // Idempotent — safe if session expiry already opened AUTH.
    AuthNavigation.replaceStackWithAuth();
    DiagnosticLogger.instance.info('✅ SplashController: Navigation to AUTH requested');
  }

  @override
  void onClose() {
    DiagnosticLogger.instance.debug('🟢 SplashController: onClose called, cancelling timer');
    _timer?.cancel();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    DiagnosticLogger.instance.debug('🟢 SplashController: onReady called');
  }
}
