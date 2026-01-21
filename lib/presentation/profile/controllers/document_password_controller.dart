// presentation/profile/controllers/document_password_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';

class DocumentPasswordController extends GetxController {
  // ---------------------------------------------------------------------------
  // DEPENDENCIES
  // ---------------------------------------------------------------------------
  final AuthRepository _authRepository = Get.find();
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

  /// Updates the password strength requirements from Validators class
  void _updatePasswordRequirements() {
    final newPassword = newPasswordController.text;

    hasPasswordInput.value = newPassword.isNotEmpty;

    passwordRequirements.value =
        Validators.getPasswordRequirements(newPassword);
    
    // Trigger reactive update for canSubmit
    update();
  }

  /// Updates when to show the "passwords match" message
  void _updatePasswordMatchVisibility() {
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;
    
    showPasswordMatch.value =
        newPassword.isNotEmpty && confirmPassword.isNotEmpty;
    
    // Trigger reactive update for canSubmit
    update();
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

    // Check password strength
    if (!Validators.isPasswordStrong(value)) {
      // Don't show error here - requirements list shows details
      // But we need to ensure canSubmit prevents submission
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
      // Get password values securely (never log them)
      final newPassword = newPasswordController.text.trim();
      final confirmPassword = confirmPasswordController.text.trim();

      // Call API to set document password
      final result = await _authRepository.setDocumentPassword(
        password: newPassword,
        confirmPassword: confirmPassword,
      );

      isLoading.value = false;

      if (result['success'] == true) {
        // Clear password fields for security
        newPasswordController.clear();
        confirmPasswordController.clear();
        hasPasswordInput.value = false;
        showPasswordMatch.value = false;

        // Success feedback
        Get.snackbar(
          'success'.tr,
          result['message'] ?? 'document_password_saved'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );

        // Navigate back after success
        Future.delayed(const Duration(milliseconds: 3000), () {
          Get.back();
        });
      } else {
        // Show error message
        _showError(result['error'] ?? 'failed_to_save_document_password'.tr);
      }
    } catch (e) {
      isLoading.value = false;
      // Never log password in error messages
      _showError('failed_to_save_document_password'.tr);
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

