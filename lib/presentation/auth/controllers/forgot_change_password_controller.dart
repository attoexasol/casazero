// presentation/auth/controllers/forgot_change_password_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/message_popup_controller.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/utils/validators.dart';
import '../../../core/services/storage_service.dart';

class ForgotChangePasswordController extends GetxController {
  // ---------------------------------------------------------------------------
  // DEPENDENCIES
  // ---------------------------------------------------------------------------
  final AuthRepository _authRepository = Get.find();
  final StorageService _storageService = Get.find();

  // ---------------------------------------------------------------------------
  // TEXT CONTROLLERS
  // ---------------------------------------------------------------------------
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // ---------------------------------------------------------------------------
  // OBSERVABLES FOR UI
  // ---------------------------------------------------------------------------
  final RxBool showNewPassword = false.obs;
  final RxBool showConfirmPassword = false.obs;

  final RxBool isLoading = false.obs;
  final RxBool hasPasswordInput = false.obs;
  final RxBool showPasswordMatch = false.obs;

  final RxList<PasswordRequirement> passwordRequirements =
      <PasswordRequirement>[].obs;

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();

    // Update password strength + rules
    newPasswordController.addListener(_updatePasswordRequirements);

    // Show/hide password match section
    newPasswordController.addListener(_updatePasswordMatchVisibility);
    confirmPasswordController.addListener(_updatePasswordMatchVisibility);

    // Update GetBuilder UI for submit button / form state
    newPasswordController.addListener(() => update());
    confirmPasswordController.addListener(() => update());
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // INPUT LISTENERS
  // ---------------------------------------------------------------------------

  /// updates the password strength requirements from Validators class
  void _updatePasswordRequirements() {
    final newPassword = newPasswordController.text;

    hasPasswordInput.value = newPassword.isNotEmpty;

    passwordRequirements.value =
        Validators.getPasswordRequirements(newPassword);

    update(); // updates GetBuilder UI
  }

  /// updates when to show the "passwords match" message
  void _updatePasswordMatchVisibility() {
    showPasswordMatch.value =
        newPasswordController.text.isNotEmpty &&
            confirmPasswordController.text.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // PASSWORD VISIBILITY
  // ---------------------------------------------------------------------------
  void togglePasswordVisibility(String field) {
    if (field == 'new') {
      showNewPassword.toggle();
    } else if (field == 'confirm') {
      showConfirmPassword.toggle();
    }
  }

  // ---------------------------------------------------------------------------
  // VALIDATION GETTERS
  // ---------------------------------------------------------------------------

  bool get passwordsMatch =>
      newPasswordController.text == confirmPasswordController.text;

  bool get isPasswordStrong =>
      Validators.isPasswordStrong(newPasswordController.text);

  bool get canSubmit =>
      newPasswordController.text.isNotEmpty &&
          confirmPasswordController.text.isNotEmpty &&
          passwordsMatch &&
          isPasswordStrong;

  // ---------------------------------------------------------------------------
  // SUBMIT PASSWORD RESET
  // ---------------------------------------------------------------------------
  Future<void> handleResetPassword({
    required Function(String message) onSuccess,
  }) async {
    // Empty fields
    if (!canSubmit) {
      _showError('complete_fields');
      return;
    }

    isLoading.value = true;

    // Get email from storage (set during forgot password flow)
    final userData = _storageService.getUserData();
    final email = userData?['email'] ?? '';

    if (email.isEmpty) {
      isLoading.value = false;
      _showError('email_not_found');
      return;
    }

    final result = await _authRepository.resetPassword(
      email: email,
      newPassword: newPasswordController.text.trim(),
    );

    isLoading.value = false;

    if (result['success'] == true) {
      onSuccess(result['message'] ?? 'password_reset_successful');
    } else {
      _showError(result['error'] ?? 'password_reset_failed');
    }
  }

  void _showError(String message) {
    MessagePopupController.showError(
      messageKey: message,
      titleKey: 'error',
    );
  }
}
