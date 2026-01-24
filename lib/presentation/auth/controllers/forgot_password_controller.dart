// presentation/auth/controllers/forgot_password_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/message_popup_controller.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/utils/validators.dart';
import '../../../core/services/storage_service.dart';

class ForgotPasswordController extends GetxController {
  // ---------------------------------------------------------------------------
  // DEPENDENCIES
  // ---------------------------------------------------------------------------
  final AuthRepository _authRepository = Get.find();
  final StorageService _storageService = Get.find();

  // ---------------------------------------------------------------------------
  // TEXT CONTROLLERS
  // ---------------------------------------------------------------------------
  final emailController = TextEditingController();

  // ---------------------------------------------------------------------------
  // OBSERVABLES FOR UI
  // ---------------------------------------------------------------------------
  final RxBool isLoading = false.obs;

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();

    // Update GetBuilder UI for submit button / form state
    emailController.addListener(() => update());
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // VALIDATION GETTERS
  // ---------------------------------------------------------------------------

  bool get isValidEmail => Validators.isValidEmail(emailController.text);

  bool get canSubmit => emailController.text.isNotEmpty && isValidEmail;

  // ---------------------------------------------------------------------------
  // SUBMIT PASSWORD RESET REQUEST
  // ---------------------------------------------------------------------------
  Future<void> handleResetPassword({
    required Function(String message) onSuccess,
  }) async {
    // Empty fields
    if (!canSubmit) {
      _showError('complete_fields'.tr);
      return;
    }

    isLoading.value = true;

    final result = await _authRepository.forgotPassword(
      emailController.text.trim(),
    );

    isLoading.value = false;

    if (result['success'] == true) {
      // Save email and user_id to storage for use in OTP verification and forgot change password screen
      final email = emailController.text.trim();
      final userId = result['user_id'];
      final userData = _storageService.getUserData() ?? {};
      userData['email'] = email;
      if (userId != null) {
        userData['id'] = userId;
        print('✅ [ForgotPassword] User ID stored: $userId');
      } else {
        print('⚠️ [ForgotPassword] User ID not found in API response');
      }
      await _storageService.saveUserData(userData);

      // Navigate to OTP verification screen
      onSuccess(result['message'] ?? 'password_reset_successful'.tr);
    } else {
      _showError(result['error'] ?? 'password_reset_failed'.tr);
    }
  }

  void _showError(String message) {
    MessagePopupController.showError(
      messageKey: message,
      titleKey: 'error',
    );
  }
}
