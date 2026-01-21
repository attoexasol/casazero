// presentation/profile/controllers/document_password_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/validators.dart';

class DocumentPasswordController extends GetxController {
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
  // FORM VALIDATION
  // ---------------------------------------------------------------------------
  final formKey = GlobalKey<FormState>();

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

  /// Updates the password strength requirements from Validators class
  void _updatePasswordRequirements() {
    final newPassword = newPasswordController.text;

    hasPasswordInput.value = newPassword.isNotEmpty;

    passwordRequirements.value =
        Validators.getPasswordRequirements(newPassword);
  }

  /// Updates when to show the "passwords match" message
  void _updatePasswordMatchVisibility() {
    showPasswordMatch.value =
        newPasswordController.text.isNotEmpty &&
            confirmPasswordController.text.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // PASSWORD VISIBILITY
  // ---------------------------------------------------------------------------
  void toggleNewPasswordVisibility() {
    showNewPassword.value = !showNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    showConfirmPassword.value = !showConfirmPassword.value;
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
  // VALIDATION METHODS
  // ---------------------------------------------------------------------------

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'new_password_required'.tr;
    }

    if (!isPasswordStrong) {
      // Return null here - validation details shown in requirements list
      // Form validation will prevent submission via canSubmit getter
      return null;
    }

    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'confirm_password_required'.tr;
    }

    if (!passwordsMatch) {
      return 'passwords_do_not_match'.tr;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // SUBMIT HANDLER (Ready for future API integration)
  // ---------------------------------------------------------------------------
  Future<void> submitDocumentPassword() async {
    // Validate form state
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Double-check security requirements
    if (!canSubmit) {
      _showError('complete_fields'.tr);
      return;
    }

    isLoading.value = true;

    try {
      // Get password value securely (never log it)
      final newPassword = newPasswordController.text.trim();

      // TODO: Implement API call here
      // Example:
      // final result = await _repository.updateDocumentPassword(
      //   newPassword: newPassword,
      // );
      // 
      // IMPORTANT SECURITY NOTES:
      // - Backend must handle password hashing/encryption
      // - Never log password values
      // - Use secure HTTPS connection
      // - Consider rate limiting on backend

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Clear password fields for security
      newPasswordController.clear();
      confirmPasswordController.clear();
      hasPasswordInput.value = false;
      showPasswordMatch.value = false;

      // Success feedback
      Get.snackbar(
        'success'.tr,
        'document_password_saved'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );

      // Navigate back after success
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.back();
      });
    } catch (e) {
      // Never log password in error messages
      _showError('failed_to_save_document_password'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // ERROR HANDLING
  // ---------------------------------------------------------------------------

  void _showError(String message) {
    Get.snackbar(
      'error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }
}

