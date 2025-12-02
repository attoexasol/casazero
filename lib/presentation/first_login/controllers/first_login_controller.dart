// presentation/first_login/controllers/first_login_controller.dart (WITH EMAIL OTP)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/two_factor_method_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/validators.dart';
import '../../../app/routes/app_routes.dart';

class FirstLoginController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final StorageService _storageService = Get.find();

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final verificationCodeController = TextEditingController();
  final phoneNumberController = TextEditingController();

  final RxInt currentStep = 1.obs;
  final RxBool showCurrentPassword = false.obs;
  final RxBool showNewPassword = false.obs;
  final RxBool showConfirmPassword = false.obs;
  final RxBool enable2FA = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasPasswordInput = false.obs;

  final RxList<PasswordRequirement> passwordRequirements = <PasswordRequirement>[].obs;

  // 2FA Method Selection
  final RxList<TwoFactorMethod> twoFactorMethods = <TwoFactorMethod>[].obs;
  final Rx<TwoFactorMethod?> selectedMethod = Rx<TwoFactorMethod?>(null);
  final RxBool isConfiguringMethod = false.obs;

  // Authenticator App Data
  final RxString qrCodeData = ''.obs;
  final RxString totpSecret = ''.obs;
  final RxBool showManualEntry = false.obs;

  // Email/SMS verification
  final RxBool isVerificationSent = false.obs;
  final RxInt verificationCountdown = 0.obs;

  // Make this observable so Obx can track it
  final RxBool _isPasswordFormValidRx = false.obs;

  String get userEmail {
    final userData = _storageService.getUserData();
    return userData?['email'] ?? 'user@example.com';
  }

  // Return the RxBool itself so Obx can track it
  RxBool get isPasswordFormValid => _isPasswordFormValidRx;

  @override
  void onInit() {
    super.onInit();
    newPasswordController.addListener(_updatePasswordRequirements);
    currentPasswordController.addListener(_validateForm);
    confirmPasswordController.addListener(_validateForm);
    _initializeTwoFactorMethods();
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    verificationCodeController.dispose();
    phoneNumberController.dispose();
    super.onClose();
  }

  void _initializeTwoFactorMethods() {
    twoFactorMethods.value = [
      TwoFactorMethod(
        id: 'email',
        name: 'email_2fa'.tr,
        description: 'email_2fa_desc'.tr,
        icon: 'email',
        type: TwoFactorMethodType.email,
      ),
      TwoFactorMethod(
        id: 'sms',
        name: 'sms_2fa'.tr,
        description: 'sms_2fa_desc'.tr,
        icon: 'sms',
        type: TwoFactorMethodType.sms,
      ),
      TwoFactorMethod(
        id: 'authenticator',
        name: 'authenticator_2fa'.tr,
        description: 'authenticator_2fa_desc'.tr,
        icon: 'authenticator',
        type: TwoFactorMethodType.authenticator,
      ),
    ];
  }

  void _updatePasswordRequirements() {
    hasPasswordInput.value = newPasswordController.text.isNotEmpty;
    passwordRequirements.value = Validators.getPasswordRequirements(
      newPasswordController.text,
    );
    _validateForm();
  }

  void _validateForm() {
    final isValid = _checkPasswordFormValid();
    _isPasswordFormValidRx.value = isValid;
  }

  bool _checkPasswordFormValid() {
    if (currentPasswordController.text.trim().isEmpty ||
        newPasswordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      return false;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      return false;
    }

    return Validators.isPasswordStrong(newPasswordController.text);
  }

  void togglePasswordVisibility(String field) {
    switch (field) {
      case 'current':
        showCurrentPassword.value = !showCurrentPassword.value;
        break;
      case 'new':
        showNewPassword.value = !showNewPassword.value;
        break;
      case 'confirm':
        showConfirmPassword.value = !showConfirmPassword.value;
        break;
    }
  }

  Future<void> changePassword() async {
    if (!isPasswordFormValid.value) {
      Get.snackbar(
        'error'.tr,
        'complete_fields'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    final result = await _authRepository.changePassword(
      currentPassword: currentPasswordController.text,
      newPassword: newPasswordController.text,
    );

    isLoading.value = false;

    if (result['success']) {
      Get.snackbar(
        'success'.tr,
        'password_changed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[700],
        colorText: Colors.white,
      );
      currentStep.value = 2;
    } else {
      Get.snackbar(
        'error'.tr,
        result['error'] ?? 'password_requirements_not_met'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    }
  }

  void selectTwoFactorMethod(TwoFactorMethod method) {
    selectedMethod.value = method;
    enable2FA.value = true;
    isConfiguringMethod.value = true;

    // Clear previous data
    verificationCodeController.clear();
    qrCodeData.value = '';
    totpSecret.value = '';
    isVerificationSent.value = false;

    // Initialize method-specific setup
    if (method.type == TwoFactorMethodType.authenticator) {
      _generateAuthenticatorSetup();
    } else if (method.type == TwoFactorMethodType.email) {
      // Email is ready - user can send OTP when ready
    } else if (method.type == TwoFactorMethodType.sms) {
      // SMS is ready - user needs to enter phone number
    }
  }

  Future<void> _generateAuthenticatorSetup() async {
    isLoading.value = true;

    // Use the new API endpoint that returns base64 QR code
    final result = await _authRepository.setupAuthenticator2FA();

    isLoading.value = false;

    if (result['success']) {
      // Store the secret key
      totpSecret.value = result['secret'] ?? '';

      // Store the base64 QR code image (includes data:image/svg+xml;base64, prefix)
      qrCodeData.value = result['qr_base64'] ?? '';

      print('✅ Authenticator Setup Success:');
      print('   Secret Key: ${totpSecret.value}');
      print('   QR Base64 Length: ${qrCodeData.value.length}');
      print('   OtpAuth URL: ${result['otpauth_url']}');
    } else {
      Get.snackbar(
        'error'.tr,
        result['error'] ?? 'failed_to_generate_qr'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    }
  }

  /// Send verification code - Email OTP using actual API
  Future<void> sendVerificationCode() async {
    if (selectedMethod.value?.type == TwoFactorMethodType.sms) {
      if (phoneNumberController.text.trim().isEmpty) {
        Get.snackbar(
          'error'.tr,
          'enter_phone_number'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[700],
          colorText: Colors.white,
        );
        return;
      }
    }

    isLoading.value = true;

    // Send OTP using actual API
    final result = await _authRepository.sendOTP(
      method: selectedMethod.value?.type.name ?? 'email',
    );

    isLoading.value = false;

    if (result['success']) {
      isVerificationSent.value = true;

      // Start countdown timer
      verificationCountdown.value = 60;
      _startCountdown();

      Get.snackbar(
        'success'.tr,
        result['message'] ?? 'verification_code_sent'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[700],
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        result['error'] ?? 'failed_to_send_otp'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (verificationCountdown.value > 0) {
        verificationCountdown.value--;
        _startCountdown();
      }
    });
  }

  void toggleManualEntry() {
    showManualEntry.value = !showManualEntry.value;
  }

  void cancelMethodConfiguration() {
    isConfiguringMethod.value = false;
    selectedMethod.value = null;
    enable2FA.value = false;
    verificationCodeController.clear();
    phoneNumberController.clear();
    qrCodeData.value = '';
    totpSecret.value = '';
    isVerificationSent.value = false;
  }

  /// Verify 2FA method - Email OTP using actual API
  Future<void> verify2FAMethod() async {
    if (verificationCodeController.text.length != 6) {
      Get.snackbar(
        'error'.tr,
        'enter_verification_code'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    // Verify OTP using actual API
    final result = await _authRepository.verifyOTP(
      code: verificationCodeController.text,
      method: selectedMethod.value?.type.name ?? 'email',
    );

    isLoading.value = false;

    if (result['success']) {
      // Mark method as configured
      final index = twoFactorMethods.indexWhere((m) => m.id == selectedMethod.value?.id);
      if (index != -1) {
        twoFactorMethods[index] = twoFactorMethods[index].copyWith(
          isEnabled: true,
          isConfigured: true,
        );
      }

      // Update user data in storage with 2FA method
      final userData = _storageService.getUserData();
      if (userData != null) {
        userData['two_fa_method'] = selectedMethod.value?.type.name ?? 'email';
        await _storageService.saveUserData(userData);
      }

      Get.snackbar(
        'success'.tr,
        result['message'] ?? '2fa_enabled'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[700],
        colorText: Colors.white,
      );

      // Complete setup
      await _completeSetup();
    } else {
      Get.snackbar(
        'error'.tr,
        result['error'] ?? 'invalid_verification_code'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    }
  }

  Future<void> setup2FA() async {
    // If configuring a method, verify it
    if (isConfiguringMethod.value) {
      await verify2FAMethod();
      return;
    }

    // If skipping 2FA setup
    await _completeSetup();
  }

  Future<void> _completeSetup() async {
    await _storageService.setFirstLogin(false);

    final userData = _storageService.getUserData();
    if (userData != null) {
      userData['is_first_login'] = false;
      userData['is_password_set_by_admin'] = false;
      await _storageService.saveUserData(userData);
    }

    Get.offAllNamed(AppRoutes.HOME);
  }

  void goBack() {
    if (isConfiguringMethod.value) {
      cancelMethodConfiguration();
    } else if (currentStep.value > 1) {
      currentStep.value--;
    }
  }
}