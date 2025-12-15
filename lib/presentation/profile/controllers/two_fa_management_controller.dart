// presentation/profile/controllers/two_fa_management_controller.dart

import 'package:casazero/presentation/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/two_factor_method_model.dart';

class TwoFAManagementController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final ProfileRepository _profileRepository = Get.find();
  final StorageService _storageService = Get.find();

  // User data
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // 2FA State
  final RxBool is2FAEnabled = false.obs;
  final RxString current2FAMethod = ''.obs;

  // UI State
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;
  final RxBool isInSetupMode = false.obs;
  final RxBool isInDeactivationMode = false.obs;

  // For Authenticator Setup
  final RxString qrCodeData = ''.obs;
  final RxString totpSecret = ''.obs;
  final RxString otpauthUrl = ''.obs;
  final verificationCodeController = TextEditingController();

  // For OTP Verification (Deactivation)
  final otpController = TextEditingController();
  final RxInt countdown = 0.obs;
  final RxBool isResending = false.obs;

  // Available 2FA Methods
  final RxList<TwoFactorMethod> twoFactorMethods = <TwoFactorMethod>[].obs;
  final Rx<TwoFactorMethod?> selectedMethod = Rx<TwoFactorMethod?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _initializeMethods();
  }

  @override
  void onClose() {
    verificationCodeController.dispose();
    otpController.dispose();
    super.onClose();
  }

  void _loadUserData() {
    final userData = _storageService.getUserData();
    if (userData != null) {
      currentUser.value = UserModel.fromJson(userData);
      is2FAEnabled.value = currentUser.value?.is2FAEnabled ?? false;
      current2FAMethod.value = currentUser.value?.twoFaMethod ?? 'none';
    }
  }

  void _initializeMethods() {
    twoFactorMethods.value = [
      TwoFactorMethod(
        id: '1',
        name: 'Email Authentication',
        type: TwoFactorMethodType.email,
        description: 'Receive verification codes via email',
        icon: 'email',
        isEnabled: false,
        isConfigured: current2FAMethod.value == 'email',
      ),
      TwoFactorMethod(
        id: '2',
        name: 'SMS Authentication',
        type: TwoFactorMethodType.sms,
        description: 'Receive verification codes via text message',
        icon: 'sms',
        isEnabled: false,
        isConfigured: current2FAMethod.value == 'sms',
      ),
      TwoFactorMethod(
        id: '3',
        name: 'Authenticator App',
        type: TwoFactorMethodType.authenticator,
        description: 'Use an authenticator app like Google Authenticator',
        icon: 'authenticator',
        isEnabled: false,
        isConfigured: current2FAMethod.value == 'authenticator',
      ),
    ];
  }

  // ============================================================================
  // ACTIVATE 2FA
  // ============================================================================

  /// Start 2FA activation flow
  void startActivation() {
    // Reset state
    isInSetupMode.value = true;
    isInDeactivationMode.value = false;
    selectedMethod.value = null;
    verificationCodeController.clear();
    qrCodeData.value = '';
    totpSecret.value = '';
    otpauthUrl.value = '';
  }

  /// Select a 2FA method to activate
  void selectMethod(TwoFactorMethod method) async {
    selectedMethod.value = method;

    // If authenticator, setup QR code
    if (method.type == TwoFactorMethodType.authenticator) {
      await _setupAuthenticatorQRCode();
    } else if (method.type == TwoFactorMethodType.email || method.type == TwoFactorMethodType.sms) {
      // Auto-send OTP for email/SMS
      //await _sendActivationOTP();
    }
  }

  /// Setup Authenticator QR Code
  Future<void> _setupAuthenticatorQRCode() async {
    isLoading.value = true;

    final userData = _storageService.getUserData();
    final userId = userData?['id'];

    if (userId == null) {
      Get.snackbar(
        'error'.tr,
        'User not found',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
      isLoading.value = false;
      return;
    }

    // Call API to get QR code
    final result = await _authRepository.setupAuthenticator2FA();

    isLoading.value = false;

    if (result['success']) {
      qrCodeData.value = result['qr_base64'] ?? '';
      totpSecret.value = result['secret'] ?? '';
      otpauthUrl.value = result['otpauth_url'] ?? '';

      print('Ã¢Å“â€¦ QR Code generated successfully');
      print('   OtpAuth URL: ${otpauthUrl.value}');

      print('ÃƒÆ’Ã‚Â¢Ãƒâ€¦Ã¢â‚¬Å“ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ QR Code generated successfully');
    } else {
      Get.snackbar(
        'error'.tr,
        result['error'] ?? 'Failed to generate QR code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
      // Close dialog if failed
      Get.back();
    }
  }

  /// Send OTP for Email/SMS activation
  Future<void> sendActivationOTP() async {
    isLoading.value = true;

    final result = await _authRepository.sendOTP(
      method: selectedMethod.value!.type.name,
    );

    isLoading.value = false;

    if (result['success']) {
      print('OTP sent for activation');
    } else {
      Get.snackbar(
        'error'.tr,
        result['error'] ?? 'Failed to send OTP',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    }
  }

  /// Verify and activate 2FA
  Future<void> verifyAndActivate() async {
    if (selectedMethod.value == null) {
      Get.snackbar(
        'error'.tr,
        'Please select a 2FA method',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
      return;
    }

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

    isProcessing.value = true;

    // Verify OTP
    final result = await _authRepository.verifyOTP(
      code: verificationCodeController.text,
      method: selectedMethod.value!.type.name,
    );

    if (result['success']) {
      // Update profile with new 2FA method
      await _updateProfileWith2FA(selectedMethod.value!.type.name);
    } else {
      isProcessing.value = false;
      Get.snackbar(
        'error'.tr,
        result['error'] ?? 'invalid_verification_code'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    }
  }

  /// Update user profile with 2FA method
  Future<void> _updateProfileWith2FA(String method) async {
    final userData = _storageService.getUserData();
    final userId = userData?['id'];

    if (userId == null) {
      isProcessing.value = false;
      return;
    }
    final Map<String, dynamic> result;
    // Update profile via API
    if(method!="none") {
      result = await _authRepository.update2FAStatus(userId: userId, status: 1);
    } else
      {
         result = await _authRepository.update2FAStatus(userId: userId, status: 0);
      }




    isProcessing.value = false;

    if (result['success']) {
      // Update local state based on method
      final isActivating = method != 'none';
      is2FAEnabled.value = isActivating;
      current2FAMethod.value = method;

      // Update user data in storage
      final updatedUserData = _storageService.getUserData();
      if (updatedUserData != null) {
        updatedUserData['two_fa_method'] = method;
        await _storageService.saveUserData(updatedUserData);
      }

      // Reload user
      _loadUserData();

      // Reset mode flags
      isInSetupMode.value = false;
      isInDeactivationMode.value = false;

      Get.back(); // Close verification dialog

      Get.snackbar(
        'success'.tr,
        isActivating ? '2FA activated successfully' : '2FA deactivated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[700],
        colorText: Colors.white,
      );

      // Refresh profile screen if controller exists
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().loadUser();
      }
    } else {
      Get.snackbar(
        'error'.tr,
        result['error'] ?? (method == 'none' ? 'Failed to deactivate 2FA' : 'Failed to activate 2FA'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    }
  }

  void cancelActivation() {
    isInSetupMode.value = false;
    selectedMethod.value = null;
    verificationCodeController.clear();
    qrCodeData.value = '';
    totpSecret.value = '';
  }

  // ============================================================================
  // DEACTIVATE 2FA
  // ============================================================================

  /// Start 2FA deactivation flow - requires OTP verification
  Future<void> startDeactivation() async {
    isInSetupMode.value = false;
    isInDeactivationMode.value = true;
    otpController.clear();
    countdown.value = 0;

    // Auto-send OTP for email/SMS methods
    if (current2FAMethod.value == 'email' || current2FAMethod.value == 'sms') {
      await sendDeactivationOTP();
    }
  }

  /// Send OTP for deactivation verification
  Future<void> sendDeactivationOTP() async {
    if (current2FAMethod.value == 'authenticator') {
      // Authenticator doesn't need to send OTP
      return;
    }

    isResending.value = true;

    final result = await _authRepository.sendOTP(
      method: current2FAMethod.value,
    );

    isResending.value = false;

    if (result['success']) {
      countdown.value = 60;
      _startCountdown();

      Get.snackbar(
        'success'.tr,
        'OTP sent successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[700],
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        result['error'] ?? 'Failed to send OTP',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    }
  }

  void _startCountdown() {
    if (countdown.value > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (countdown.value > 0) {
          countdown.value--;
          _startCountdown();
        }
      });
    }
  }

  Future<void> resendDeactivationOTP() async {
    if (countdown.value > 0) {
      Get.snackbar(
        'info'.tr,
        'Please wait ${countdown.value} seconds before resending',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    await sendDeactivationOTP();
  }

  /// Verify OTP and deactivate 2FA
  /// Returns true if deactivation was successful, false otherwise
  Future<bool> verifyAndDeactivate() async {
    final code = otpController.text.trim();

    if (code.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'enter_otp_code'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
      return false;
    }

    if (code.length != 6) {
      Get.snackbar(
        'error'.tr,
        'OTP must be 6 digits',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
      return false;
    }

    isProcessing.value = true;

    // Step 1: Verify OTP code
    final verifyResult = await _authRepository.verifyOTP(
      code: code,
      method: current2FAMethod.value,
    );

    if (!verifyResult['success']) {
      isProcessing.value = false;
      Get.snackbar(
        'error'.tr,
        verifyResult['error'] ?? 'Invalid OTP code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
      otpController.clear();
      return false;
    }

    // Step 2: Update 2FA status to inactive (REQUIRED)
    final userData = _storageService.getUserData();
    final userId = userData?['id'];

    if (userId != null) {
      print('📡 Calling update 2FA status API (deactivate)...');
      final statusUpdateResult = await _authRepository.update2FAStatus(
        userId: userId,
        status: 0, // 0 = deactivate
      );

      if (!statusUpdateResult['success']) {
        isProcessing.value = false;
        Get.snackbar(
          'error'.tr,
          statusUpdateResult['error'] ?? 'Failed to update 2FA status',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[700],
          colorText: Colors.white,
        );
        otpController.clear();
        return false;
      }

      print('✅ 2FA Status updated to inactive');
    }

    // Step 3: Call disable 2FA API
    final disableResult = await _authRepository.disable2FA();

    isProcessing.value = false;

    if (disableResult['success']) {
      // Update local state
      is2FAEnabled.value = false;
      current2FAMethod.value = 'none';

      // Reload user data from updated storage
      _loadUserData();

      // Reset mode flags
      isInDeactivationMode.value = false;
      otpController.clear();
      countdown.value = 0;

      // Show success message (but don't navigate back - let the screen handle it)
      Get.snackbar(
        'success'.tr,
        disableResult['message'] ?? '2FA deactivated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[700],
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Refresh profile screen if controller exists
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().loadUser();
      }

      return true;
    } else {
      Get.snackbar(
        'error'.tr,
        disableResult['error'] ?? 'Failed to deactivate 2FA',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
      otpController.clear();
      return false;
    }
  }

  void cancelDeactivation() {
    isInDeactivationMode.value = false;
    otpController.clear();
    countdown.value = 0;
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  String get current2FAMethodDisplay {
    switch (current2FAMethod.value) {
      case 'email':
        return 'Email Authentication';
      case 'sms':
        return 'SMS Authentication';
      case 'authenticator':
        return 'Authenticator App';
      default:
        return 'None';
    }
  }

  String getMaskedContact() {
    if (current2FAMethod.value == 'email') {
      final email = currentUser.value?.email ?? '';
      return _maskEmail(email);
    } else if (current2FAMethod.value == 'sms') {
      final phone = currentUser.value?.phone ?? '';
      return _maskPhone(phone);
    } else if (current2FAMethod.value == 'authenticator') {
      return 'Authenticator App';
    }
    return '';
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    }
    final visibleStart = username.substring(0, 2);
    final visibleEnd = username[username.length - 1];
    return '$visibleStart***$visibleEnd@$domain';
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '***';
    final visibleEnd = digits.substring(digits.length - 4);
    return '***-***-$visibleEnd';
  }
}