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
  // TEXT CONTROLLERS (owned by ForgotChangePasswordScreen State)
  // ---------------------------------------------------------------------------
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;
  bool _textControllersBound = false;

  VoidCallback? _formUpdateListener;

  // ---------------------------------------------------------------------------
  // OBSERVABLES FOR UI
  // ---------------------------------------------------------------------------
  final RxBool showNewPassword = false.obs;
  final RxBool showConfirmPassword = false.obs;

  final RxBool isLoading = false.obs;
  final RxBool isCompleted = false.obs;
  final RxBool hasPasswordInput = false.obs;
  final RxBool showPasswordMatch = false.obs;

  final RxList<PasswordRequirement> passwordRequirements =
      <PasswordRequirement>[].obs;

  // ---------------------------------------------------------------------------
  // TEXT CONTROLLER BINDING
  // ---------------------------------------------------------------------------
  void bindTextControllers({
    required TextEditingController newPassword,
    required TextEditingController confirmPassword,
  }) {
    if (_textControllersBound) return;

    newPasswordController = newPassword;
    confirmPasswordController = confirmPassword;
    _textControllersBound = true;

    newPasswordController.addListener(_updatePasswordRequirements);
    newPasswordController.addListener(_updatePasswordMatchVisibility);
    confirmPasswordController.addListener(_updatePasswordMatchVisibility);

    _formUpdateListener = () => update();
    newPasswordController.addListener(_formUpdateListener!);
    confirmPasswordController.addListener(_formUpdateListener!);
  }

  void unbindTextControllers() {
    if (!_textControllersBound) return;

    newPasswordController.removeListener(_updatePasswordRequirements);
    newPasswordController.removeListener(_updatePasswordMatchVisibility);
    confirmPasswordController.removeListener(_updatePasswordMatchVisibility);

    if (_formUpdateListener != null) {
      newPasswordController.removeListener(_formUpdateListener!);
      confirmPasswordController.removeListener(_formUpdateListener!);
      _formUpdateListener = null;
    }

    _textControllersBound = false;
  }

  @override
  void onClose() {
    unbindTextControllers();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // INPUT LISTENERS
  // ---------------------------------------------------------------------------

  void _updatePasswordRequirements() {
    if (!_textControllersBound) return;

    final newPassword = newPasswordController.text;

    hasPasswordInput.value = newPassword.isNotEmpty;

    passwordRequirements.value =
        Validators.getPasswordRequirements(newPassword);

    update();
  }

  void _updatePasswordMatchVisibility() {
    if (!_textControllersBound) return;

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
      _textControllersBound &&
      newPasswordController.text == confirmPasswordController.text;

  bool get isPasswordStrong =>
      _textControllersBound &&
      Validators.isPasswordStrong(newPasswordController.text);

  bool get canSubmit =>
      _textControllersBound &&
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
    if (!canSubmit) {
      _showError('complete_fields');
      return;
    }

    isLoading.value = true;

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
      isCompleted.value = true;
      FocusManager.instance.primaryFocus?.unfocus();
      onSuccess('password_reset_successful');
    } else {
      _showError('password_reset_failed');
    }
  }

  void _showError(String message) {
    MessagePopupController.showError(
      messageKey: message,
      titleKey: 'error',
    );
  }
}
