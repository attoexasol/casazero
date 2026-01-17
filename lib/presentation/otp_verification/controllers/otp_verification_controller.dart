// presentation/otp_verification/controllers/otp_verification_controller.dart (WITH EMAIL OTP)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../app/routes/app_routes.dart';
import '../../documents/controllers/documents_controller.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/models/document_model.dart';

class OtpVerificationController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final StorageService _storageService = Get.find();

  final otpController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isResending = false.obs;
  final RxInt countdown = 0.obs;
  final RxString twoFaMethod = ''.obs;
  final RxString maskedContact = ''.obs;
  final RxBool fromForgotPassword = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Check if this OTP verification is from forgot password flow
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map) {
      fromForgotPassword.value = arguments['fromForgotPassword'] == true;
    }
    _initializeVerification();
  }

  @override
  void onClose() {
    otpController.dispose();
    super.onClose();
  }

  void _initializeVerification() {
    // Get user data to determine 2FA method
    final userData = _storageService.getUserData();
    
    // If from forgot password flow, verify user_id exists
    if (fromForgotPassword.value) {
      final userId = userData?['id'];
      if (userId == null) {
        print('❌ [OTPVerification] User ID not found in storage for forgot password flow');
        Get.snackbar(
          'error'.tr,
          'user_id_not_found'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[700],
          colorText: Colors.white,
        );
        // Navigate back to forgot password screen
        Future.delayed(const Duration(seconds: 2), () {
          Get.offAllNamed(AppRoutes.FORGOT_PASSWORD);
        });
        return;
      } else {
        print('✅ [OTPVerification] User ID found in storage for forgot password flow: $userId');
      }
    }
    
    if (userData != null) {
      twoFaMethod.value = userData['two_fa_method'] ?? 'email';

      // Set masked contact based on method
      if (twoFaMethod.value == 'email') {
        final email = userData['email'] ?? '';
        maskedContact.value = _maskEmail(email);
      } else if (twoFaMethod.value == 'sms') {
        final phone = userData['phone'] ?? '';
        maskedContact.value = _maskPhone(phone);
      } else if (twoFaMethod.value == 'authenticator') {
        maskedContact.value = 'Authenticator App';
      }
    }

    // Auto-send OTP for email and SMS using actual API
    if (twoFaMethod.value == 'email' || twoFaMethod.value == 'sms') {
      sendOTP();
    }
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

    // Remove any non-digit characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 4) return '***';

    final visibleEnd = digits.substring(digits.length - 4);
    return '***-***-$visibleEnd';
  }

  String get methodDisplayName {
    switch (twoFaMethod.value) {
      case 'email':
        return 'email_authentication'.tr;
      case 'sms':
        return 'sms_authentication'.tr;
      case 'authenticator':
        return 'authenticator_app'.tr;
      default:
        return 'two_factor_authentication'.tr;
    }
  }

  String get methodIcon {
    switch (twoFaMethod.value) {
      case 'email':
        return 'email';
      case 'sms':
        return 'sms';
      case 'authenticator':
        return 'authenticator';
      default:
        return 'security';
    }
  }

  String get instructionText {
    switch (twoFaMethod.value) {
      case 'email':
        return 'otp_email_instruction'.tr;
      case 'sms':
        return 'otp_sms_instruction'.tr;
      case 'authenticator':
        return 'otp_authenticator_instruction'.tr;
      default:
        return 'otp_verification_instruction'.tr;
    }
  }

  /// Send OTP using actual API endpoint
  Future<void> sendOTP() async {
    if (twoFaMethod.value == 'authenticator') {
      // Authenticator doesn't need to send OTP
      return;
    }

    isResending.value = true;

    // Use actual API to send OTP
    final result = await _authRepository.sendOTP(
      method: twoFaMethod.value,
    );

    isResending.value = false;

    if (result['success']) {


      // Start countdown
      countdown.value = 60;
      _startCountdown();
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
    if (countdown.value > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (countdown.value > 0) {
          countdown.value--;
          _startCountdown();
        }
      });
    }
  }

  /// Verify OTP using actual API endpoint
  Future<void> verifyOTP() async {
    final code = otpController.text.trim();

    if (code.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'enter_otp_code'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
      return;
    }

    if (code.length != 6) {
      Get.snackbar(
        'error'.tr,
        'otp_must_be_6_digits'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    // Use actual API to verify OTP
    final result = await _authRepository.verifyOTP(
      code: code,
      method: twoFaMethod.value,
    );

    isLoading.value = false;
    print(result.toString());
    if (result['success']) {
      // Check if this is from forgot password flow
      if (fromForgotPassword.value) {
        // Navigate to forgot change password screen
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(AppRoutes.FORGOT_CHANGE_PASSWORD);
      } else {
        // Pre-load documents in background while navigating
        _preloadDocuments();

        // Navigate to home
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(AppRoutes.HOME);
      }
    } else {
      Get.snackbar(
        'error'.tr,
        result['error'] ?? 'invalid_otp_code'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );

      // Clear the OTP field
      otpController.clear();
    }
  }

  Future<void> resendOTP() async {
    if (countdown.value > 0) {
      Get.snackbar(
        'info'.tr,
        'please_wait_before_resend'.tr.replaceAll('{seconds}', countdown.value.toString()),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    await sendOTP();
  }

  void cancelVerification() {
    Get.dialog(
      AlertDialog(
        title: Text('cancel_verification'.tr),
        content: Text('cancel_verification_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('no'.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              _logout();
            },
            child: Text('yes'.tr),
          ),
        ],
      ),
    );
  }

  /// Pre-load documents in background after OTP verification
  /// This ensures documents are ready when user navigates to documents screen
  void _preloadDocuments() {
    // Call in background - don't await, don't block navigation
    Future.microtask(() async {
      try {
        print('📄 Pre-loading documents after OTP verification...');
        final documentRepository = DocumentRepository();
        final result = await documentRepository.getDocumentsByUnit();
        
        if (result['success'] == true) {
          // Initialize DocumentsController with pre-loaded data
          if (!Get.isRegistered<DocumentsController>()) {
            final documentsController = Get.put(DocumentsController());
            // Update documents list with pre-loaded data
            final documentsData = result['data'] as List<dynamic>;
            documentsController.documents.value = documentsData
                .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
                .toList();
            print('✅ Documents pre-loaded: ${documentsData.length} documents');
          } else {
            // If controller exists, just refresh
            final documentsController = Get.find<DocumentsController>();
            await documentsController.fetchDocuments();
          }
        } else {
          print('⚠️  Failed to pre-load documents: ${result['error']}');
        }
      } catch (e) {
        print('⚠️  Error pre-loading documents: $e');
        // Don't block - just log the error
      }
    });
  }

  Future<void> _logout() async {
    // Clear storage
    await _storageService.clearAll();

    // Navigate back to auth screen
    Get.offAllNamed(AppRoutes.AUTH);
  }
}