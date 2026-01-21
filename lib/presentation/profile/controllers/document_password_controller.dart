// presentation/profile/controllers/document_password_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DocumentPasswordController extends GetxController {
  // Form controllers
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Password visibility toggles
  final showNewPassword = false.obs;
  final showConfirmPassword = false.obs;

  // Form validation
  final formKey = GlobalKey<FormState>();

  // Loading state
  final isLoading = false.obs;

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // Toggle password visibility
  void toggleNewPasswordVisibility() {
    showNewPassword.value = !showNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    showConfirmPassword.value = !showConfirmPassword.value;
  }

  // Validation
  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'new_password_required'.tr;
    }
    if (value.length < 6) {
      return 'password_length'.tr;
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'confirm_password_required'.tr;
    }
    if (value != newPasswordController.text) {
      return 'passwords_do_not_match'.tr;
    }
    return null;
  }

  // Check if form is valid
  bool get isFormValid {
    return newPasswordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        newPasswordController.text == confirmPasswordController.text &&
        newPasswordController.text.length >= 6;
  }

  // Submit handler (ready for future API integration)
  Future<void> submitDocumentPassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (!isFormValid) {
      Get.snackbar(
        'error'.tr,
        'passwords_do_not_match'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    isLoading.value = true;

    try {
      // TODO: Implement API call here
      // Example:
      // final result = await _repository.updateDocumentPassword(
      //   newPassword: newPasswordController.text,
      // );
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

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
      Get.snackbar(
        'error'.tr,
        'failed_to_save_document_password'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoading.value = false;
    }
  }
}

