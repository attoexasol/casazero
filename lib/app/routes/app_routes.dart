// app/routes/app_routes.dart (ENHANCED WITH OTP VERIFICATION)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../presentation/auth/views/auth_screen.dart';
import '../../presentation/auth/controllers/auth_controller.dart';
import '../../presentation/auth/controllers/change_password_controller.dart';
import '../../presentation/first_login/views/first_login_setup_screen.dart';
import '../../presentation/first_login/controllers/first_login_controller.dart';
import '../../presentation/otp_verification/views/otp_verification_screen.dart';
import '../../presentation/otp_verification/controllers/otp_verification_controller.dart';
import '../../presentation/main/main_scaffold.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../presentation/auth/views/change_password_screen.dart';
import '../../presentation/auth/views/forgot_password_screen.dart';
import '../../presentation/auth/controllers/forgot_password_controller.dart';
import '../../presentation/profile/views/two_fa_management_screen.dart';
import '../../presentation/profile/views/two_fa_activation_screen.dart';
import '../../presentation/profile/controllers/two_fa_management_controller.dart';
import '../../presentation/profile/views/two_fa_deactivation_verification_screen.dart';
import '../../presentation/splash/controllers/splash_controller.dart';
import '../../presentation/splash/views/splash_screen.dart';

class AppRoutes {
  static const String SPLASH = '/';
  static const String AUTH = '/auth';
  static const String FIRST_LOGIN = '/first-login-setup';
  static const String OTP_VERIFICATION = '/otp-verification';
  static const String HOME = '/home';
  static const String CHANGE_PASSWORD = '/change-password';
  static const String FORGOT_PASSWORD = '/forgot-password';
  static const String TWO_FA_MANAGEMENT = '/two-fa-management';
  static const String TWO_FA_ACTIVATION = '/two-fa-activation';
  static const String TWO_FA_DEACTIVATION_VERIFICATION =
      '/two-fa-deactivation-verification';

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
        Get.lazyPut(() => AuthController());
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
      page: () => const MainScaffold(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => HomeController());
      }),
    ),
    GetPage(
      name: TWO_FA_MANAGEMENT,
      page: () => const TwoFAManagementScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TwoFAManagementController());
      }),
    ),
    GetPage(
      name: TWO_FA_ACTIVATION,
      page: () => const TwoFAActivationScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<TwoFAManagementController>()) {
          Get.lazyPut(() => TwoFAManagementController());
        }
      }),
    ),
    GetPage(
      name: TWO_FA_DEACTIVATION_VERIFICATION,
      page: () => const TwoFADeactivationVerificationScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<TwoFAManagementController>()) {
          Get.lazyPut(() => TwoFAManagementController());
        }
      }),
    ),
    GetPage(
      name: CHANGE_PASSWORD,
      page: () => ChangePasswordScreen(
        onBack: () => Get.back(),
        onSuccess: (String message) {
          // Navigate back first
          Get.back();
          // Then show snackbar on previous screen after a brief delay
          Future.delayed(const Duration(milliseconds: 300), () {
            Get.snackbar(
              'success'.tr,
              message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF22C55E),
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
              duration: const Duration(seconds: 3),
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
          // Navigate to OTP verification screen after successful password reset
          Get.offAllNamed(OTP_VERIFICATION);
        },
      ),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ForgotPasswordController());
      }),
    ),
  ];
}
