// presentation/auth/controllers/auth_controller.dart
// UPDATED WITH PHONE SUPPORT FOR LOGIN

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/models/user_model.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final StorageService _storageService = Get.find();
  final LocaleController _localeController = Get.find();

  // For development - remove in production
  final emailController = TextEditingController(text: 'rajibduet02@gmail.com');
  final passwordController = TextEditingController(text: 'CasaZero@024017');
  final phoneController = TextEditingController(); // Add phone controller

  // For production - uncomment these
  // final emailController = TextEditingController();
  // final passwordController = TextEditingController();
  // final phoneController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  String get selectedLanguage => _localeController.currentLanguageCode;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void changeLanguage(String lang) {
    _localeController.changeLocale(lang);
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'enter_email_password'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    final result = await _authRepository.login(
      email: emailController.text.trim(),
      password: passwordController.text,
      phone: phoneController.text.trim().isEmpty
          ? null
          : phoneController.text.trim(),
    );

    isLoading.value = false;

    if (result['success']) {
      final UserModel user = result['user'];
      final bool isTrusted = result['is_trusted'] ?? false;

      // Save tokens and user data
      print('🔑 Login Access Token (from API): ${result['access_token']}');
      print('Is Trusted Device: $isTrusted');
      print('Is Password Set By Admin: ${user.isPasswordSetByAdmin}');

      // Always replace any old/stale token with the new one
      await _storageService.clearAccessToken();
      await _storageService.saveAccessToken(result['access_token']);
      final storedToken = _storageService.getAccessToken();
      print('💾 Stored Access Token (post-save): $storedToken');

      await _storageService.saveUserData(user.toJson());
      await _storageService.setFirstLogin(user.isFirstLogin);

      // Set user's preferred language from API
      await _localeController.changeLocale(user.language);

      // Navigation logic based on user status and device trust
      _navigateBasedOnUserStatus(user, isTrusted);
    } else {
      Get.snackbar(
        'login_failed'.tr,
        result['error'] ?? 'invalid_credentials'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    }
  }

  /// Enhanced navigation logic with trusted device check
  ///
  /// Priority Order:
  /// 1. Password set by admin (is_password_set_by_admin = true) → First Login Flow
  /// 2. Trusted device (is_trusted = true) → Home (skip 2FA)
  /// 3. Untrusted device + 2FA enabled → OTP Verification
  /// 4. Otherwise → Home
  void _navigateBasedOnUserStatus(UserModel user, bool isTrusted) {
    print('🔄 Navigation Decision:');
    print('  - Password Set By Admin: ${user.isPasswordSetByAdmin}');
    print('  - Is Trusted Device: $isTrusted');
    print('  - 2FA Enabled: ${user.is2FAEnabled}');

    // Priority 1: First login (password set by admin)
    // User must change password set by admin
    if (user.isPasswordSetByAdmin) {
      print('  → Going to FIRST_LOGIN (password change required)');
      Get.offAllNamed(AppRoutes.FIRST_LOGIN);
      return;
    }

    // Priority 2: Trusted device - Direct to HOME (skip 2FA)
    // If password is NOT set by admin AND device IS trusted
    // Then skip 2FA verification and go directly to HOME
    if (isTrusted) {
      print('  → Going to HOME (trusted device - skipping 2FA)');
      Get.offAllNamed(AppRoutes.HOME);
      return;
    }

    // Priority 3: Untrusted device + 2FA enabled
    // Device is not recognized, require 2FA verification
    if (user.is2FAEnabled) {
      print('  → Going to OTP_VERIFICATION (untrusted device - 2FA required)');
      Get.offAllNamed(AppRoutes.OTP_VERIFICATION);
      return;
    }

    // Priority 4: Untrusted device + No 2FA - Direct to HOME
    // This is less secure but follows the requested logic
    print('  → Going to HOME (untrusted device without 2FA)');
    Get.offAllNamed(AppRoutes.HOME);
  }

  Future<void> forgotPassword() async {
    if (emailController.text.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'enter_email'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final success = await _authRepository.forgotPassword(
      emailController.text.trim(),
    );

    if (success) {
      Get.snackbar(
        'password_reset_sent'.tr,
        'check_email'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[700],
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'failed_reset_email'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    }
  }
}
