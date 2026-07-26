// app/routes/app_routes.dart (ENHANCED WITH OTP VERIFICATION)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/message_popup_controller.dart';
import '../../presentation/auth/views/auth_screen.dart';
import '../../presentation/auth/controllers/auth_controller.dart';
import '../../presentation/auth/controllers/change_password_controller.dart';
import '../../presentation/first_login/views/first_login_setup_screen.dart';
import '../../presentation/first_login/controllers/first_login_controller.dart';
import '../../presentation/otp_verification/views/otp_verification_screen.dart';
import '../../presentation/otp_verification/controllers/otp_verification_controller.dart';
import '../../presentation/main/main_scaffold.dart';
import '../../core/widgets/app_lifecycle_refresh_wrapper.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../presentation/auth/views/change_password_screen.dart';
import '../../presentation/auth/views/forgot_password_screen.dart';
import '../../presentation/auth/controllers/forgot_password_controller.dart';
import '../../presentation/auth/views/forgot_change_password_screen.dart';
import '../../presentation/auth/controllers/forgot_change_password_controller.dart';
import '../../presentation/profile/views/two_fa_management_screen.dart';
import '../../presentation/profile/views/two_fa_activation_screen.dart';
import '../../presentation/profile/controllers/two_fa_management_controller.dart';
import '../../presentation/profile/views/two_fa_deactivation_verification_screen.dart';
import '../../presentation/splash/controllers/splash_controller.dart';
import '../../presentation/splash/views/splash_screen.dart';
import '../../core/services/notification_manager.dart';
import '../../presentation/trusted_device/views/trusted_devices_screen.dart';
import '../../presentation/trusted_device/controllers/trusted_devices_controller.dart';
import '../../presentation/profile/views/document_password_screen.dart';
import '../../presentation/profile/controllers/document_password_controller.dart';
import '../../presentation/profile/views/document_password_2fa_verification_screen.dart';
import '../middleware/auth_guard.dart';

class AppRoutes {
  static const String SPLASH = '/';
  static const String AUTH = '/auth';
  static const String FIRST_LOGIN = '/first-login-setup';
  static const String OTP_VERIFICATION = '/otp-verification';
  static const String HOME = '/home';
  static const String CHANGE_PASSWORD = '/change-password';
  static const String FORGOT_PASSWORD = '/forgot-password';
  static const String FORGOT_CHANGE_PASSWORD = '/forgot-change-password';
  static const String TWO_FA_MANAGEMENT = '/two-fa-management';
  static const String TWO_FA_ACTIVATION = '/two-fa-activation';
  static const String TWO_FA_DEACTIVATION_VERIFICATION =
      '/two-fa-deactivation-verification';
  static const String TRUSTED_DEVICES = '/trusted-devices';
  static const String DOCUMENT_PASSWORD = '/document-password';
  static const String DOCUMENT_PASSWORD_2FA = '/document-password-2fa';

  static final routes = [
    GetPage(
      name: SPLASH,
      page: () => const SplashScreen(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    GetPage(
      name: AUTH,
      page: () => const AuthScreen(),
      binding: BindingsBuilder(() {
        if (Get.isRegistered<AuthController>()) {
          Get.delete<AuthController>(force: true);
        }
        Get.put(AuthController());
      }),
    ),
    GetPage(
      name: FIRST_LOGIN,
      page: () => FirstLoginSetupScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FirstLoginController());
      }),
    ),
    GetPage(
      name: OTP_VERIFICATION,
      page: () => const OtpVerificationScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OtpVerificationController());
      }),
    ),
    GetPage(
      name: HOME,
      page: () => const AppLifecycleRefreshWrapper(child: MainScaffold()),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => HomeController());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().ensureDataForCurrentUser();
          }
          // Phase 3: run queued notification deep-link after HOME is ready.
          void flushNav() {
            if (Get.isRegistered<NotificationManager>()) {
              Get.find<NotificationManager>().flushPendingNavigation();
            }
          }

          flushNav();
          // Feed may still be loading — enrich+navigate on a short delay.
          Future<void>.delayed(const Duration(milliseconds: 1500), flushNav);
          Future<void>.delayed(const Duration(milliseconds: 3500), flushNav);
        });
      }),
    ),
    GetPage(
      name: TWO_FA_MANAGEMENT,
      page: () => const TwoFAManagementScreen(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TwoFAManagementController());
      }),
    ),
    GetPage(
      name: TWO_FA_ACTIVATION,
      page: () => const TwoFAActivationScreen(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<TwoFAManagementController>()) {
          Get.lazyPut(() => TwoFAManagementController());
        }
      }),
    ),
    GetPage(
      name: TWO_FA_DEACTIVATION_VERIFICATION,
      page: () => const TwoFADeactivationVerificationScreen(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<TwoFAManagementController>()) {
          Get.lazyPut(() => TwoFAManagementController());
        }
      }),
    ),
    GetPage(
      name: CHANGE_PASSWORD,
      middlewares: [AuthGuard()],
      page: () => ChangePasswordScreen(
        onBack: () => Get.back(),
        onSuccess: (String message) {
          Get.back();
          Future.delayed(const Duration(milliseconds: 300), () {
            MessagePopupController.showSuccess(
              messageKey: message,
              titleKey: 'success',
            );
          });
        },
      ),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ChangePasswordController());
      }),
    ),
    GetPage(
      name: FORGOT_PASSWORD,
      page: () => ForgotPasswordScreen(
        onBack: () => Get.back(),
        onSuccess: (String message) {
          // Navigate to OTP verification screen with flag indicating it's from forgot password
          Get.offAllNamed(
            OTP_VERIFICATION,
            arguments: {'fromForgotPassword': true},
          );
        },
      ),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ForgotPasswordController());
      }),
    ),
    GetPage(
      name: TRUSTED_DEVICES,
      page: () => const TrustedDevicesScreen(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TrustedDevicesController());
      }),
    ),
    GetPage(
      name: DOCUMENT_PASSWORD,
      page: () => const DocumentPasswordScreen(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DocumentPasswordController());
      }),
    ),
    GetPage(
      name: DOCUMENT_PASSWORD_2FA,
      page: () => const DocumentPassword2FAVerificationScreen(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OtpVerificationController());
      }),
    ),

    GetPage(
      name: FORGOT_CHANGE_PASSWORD,
      page: () => ForgotChangePasswordScreen(
        onBack: () => Get.back(),
        onSuccess: (String message) {
          FocusManager.instance.primaryFocus?.unfocus();
          Get.offAllNamed(AUTH);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            MessagePopupController.showSuccess(
              messageKey: message,
              titleKey: 'success',
            );
          });
        },
      ),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ForgotChangePasswordController());
      }),
    ),
  ];
}
