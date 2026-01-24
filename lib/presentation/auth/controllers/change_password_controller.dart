// presentation/auth/controllers/change_password_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/message_popup_controller.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/utils/validators.dart';

class ChangePasswordController extends GetxController {
  // ---------------------------------------------------------------------------
  // DEPENDENCIES
  // ---------------------------------------------------------------------------
  final AuthRepository _authRepository = Get.find();

  // ---------------------------------------------------------------------------
  // TEXT CONTROLLERS
  // ---------------------------------------------------------------------------
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // ---------------------------------------------------------------------------
  // OBSERVABLES FOR UI
  // ---------------------------------------------------------------------------
  final RxBool showCurrentPassword = false.obs;
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
    currentPasswordController.addListener(() => update());
    confirmPasswordController.addListener(() => update());
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
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
    if (field == 'current') {
      showCurrentPassword.toggle();
    } else if (field == 'new') {
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
      currentPasswordController.text.isNotEmpty &&
          newPasswordController.text.isNotEmpty &&
          confirmPasswordController.text.isNotEmpty &&
          passwordsMatch &&
          isPasswordStrong;

  // ---------------------------------------------------------------------------
  // SUBMIT PASSWORD CHANGE
  // ---------------------------------------------------------------------------
  Future<void> handleChangePassword({
    required Function(String message) onSuccess,
  }) async {
    // Empty fields
    if (!canSubmit) {
      _showError('complete_fields'.tr);
      return;
    }

    isLoading.value = true;

    final result = await _authRepository.changePassword(
      currentPassword: currentPasswordController.text.trim(),
      newPassword: newPasswordController.text.trim(),
    );

    isLoading.value = false;

    if (result['success'] == true) {
      // Navigate back first, then show popup on previous screen
      onSuccess(result['message'] ?? 'password_changed'.tr);
    } else {
      _showError(result['error'] ?? 'password_requirements_not_met'.tr);
    }
  }

  void _showError(String message) {
    MessagePopupController.showError(
      messageKey: message,
      titleKey: 'error',
    );
  }
}