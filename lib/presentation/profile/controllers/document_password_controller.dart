// presentation/profile/controllers/document_password_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/message_popup_controller.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../app/routes/app_routes.dart';

class DocumentPasswordController extends GetxController {
  // ---------------------------------------------------------------------------
  // DEPENDENCIES
  // ---------------------------------------------------------------------------
  final AuthRepository _authRepository = Get.find();
  
  // ---------------------------------------------------------------------------
  // TEMPORARY PASSWORD STORAGE (for 2FA flow)
  // ---------------------------------------------------------------------------
  String? _pendingPassword;
  String? _pendingConfirmPassword;
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
  // SUBMIT HANDLER (2FA-Protected - Production Ready)
  // ---------------------------------------------------------------------------
  Future<void> submitDocumentPassword() async {
    // Validate form state first
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Double-check security requirements before proceeding
    if (!canSubmit) {
      _showError('complete_fields'.tr);
      return;
    }

    // Prevent multiple simultaneous submissions
    if (isLoading.value) {
      return;
    }

    // Get password values securely (never log them)
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Additional validation: ensure passwords match after trim
    if (newPassword != confirmPassword) {
      _showError('passwords_do_not_match'.tr);
      return;
    }

    // Store passwords temporarily for use after 2FA verification
    // These will be cleared immediately after use
    _pendingPassword = newPassword;
    _pendingConfirmPassword = confirmPassword;

    // Navigate to dedicated 2FA verification screen for document password
    // Password will be saved only after successful 2FA verification
    final result = await Get.toNamed(
      AppRoutes.DOCUMENT_PASSWORD_2FA,
      arguments: {'fromDocumentPassword': true},
    );

    // Handle 2FA verification result
    // result will be true if 2FA succeeded, false/null if failed or cancelled
    if (result == true) {
      // 2FA verification successful - save the password
      await savePasswordAfter2FA();
    } else {
      // 2FA failed or cancelled - clear pending passwords and stay on screen
      _clearPendingPasswords();
    }
  }

  // ---------------------------------------------------------------------------
  // SAVE PASSWORD AFTER 2FA VERIFICATION (Called from OTP Controller)
  // ---------------------------------------------------------------------------
  Future<void> savePasswordAfter2FA() async {
    // Security check: ensure passwords are still available
    if (_pendingPassword == null || _pendingConfirmPassword == null) {
      _showError('failed_to_save_document_password');
      _clearPendingPasswords();
      return;
    }

    // Prevent multiple simultaneous submissions
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;

    try {
      // Call API to set/update document password
      final result = await _authRepository.setDocumentPassword(
        password: _pendingPassword!,
        confirmPassword: _pendingConfirmPassword!,
      );

      // Clear pending passwords immediately after use (security best practice)
      _clearPendingPasswords();

      isLoading.value = false;

      if (result['success'] == true) {
        // Clear password fields for security (passwords should not persist in memory)
        newPasswordController.clear();
        confirmPasswordController.clear();
        hasPasswordInput.value = false;
        showPasswordMatch.value = false;

        // Success feedback
        MessagePopupController.showSuccess(
          messageKey: result['message'] ?? 'document_password_saved',
          titleKey: 'success',
        );

        // Stay on Document Password screen - do NOT navigate away
        // User can manually go back when ready
      } else {
        // Show error message from API response
        _showError(result['error'] ?? 'failed_to_save_document_password');
      }
    } catch (e) {
      isLoading.value = false;
      _clearPendingPasswords();
      // Never log password in error messages - security best practice
      // Show generic error message to user
      _showError('failed_to_save_document_password');
    }
  }

  // ---------------------------------------------------------------------------
  // CLEAR PENDING PASSWORDS (Security)
  // ---------------------------------------------------------------------------
  void _clearPendingPasswords() {
    _pendingPassword = null;
    _pendingConfirmPassword = null;
  }

  // ---------------------------------------------------------------------------
  // CANCEL 2FA FLOW (Called when user cancels 2FA verification)
  // ---------------------------------------------------------------------------
  void cancel2FAFlow() {
    _clearPendingPasswords();
    // User remains on document password screen
  }

  // ---------------------------------------------------------------------------
  // ERROR HANDLING
  // ---------------------------------------------------------------------------

  void _showError(String message) {
    MessagePopupController.showError(
      messageKey: message,
      titleKey: 'error',
    );
  }
}

