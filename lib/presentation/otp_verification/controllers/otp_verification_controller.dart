// presentation/otp_verification/controllers/otp_verification_controller.dart (WITH EMAIL OTP)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/message_popup_controller.dart';
import '../../../core/widgets/responsive_alert_dialog.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/navigation/auth_navigation.dart';
import '../../../core/services/storage_service.dart';
import '../../../app/routes/app_routes.dart';
import '../../documents/controllers/documents_controller.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/models/document_model.dart';
import '../../profile/controllers/document_password_controller.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/firebase_auth_service.dart';

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
  final RxBool fromDocumentPassword = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Check if this OTP verification is from forgot password or document password flow
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map) {
      fromForgotPassword.value = arguments['fromForgotPassword'] == true;
      fromDocumentPassword.value = arguments['fromDocumentPassword'] == true;
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
        MessagePopupController.showError(
          messageKey: 'user_id_not_found',
          titleKey: 'error',
        );
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

    if (result['success'] == true) {
      // Show info message when OTP is sent successfully (not error)
      // Use explicit info popup to ensure correct styling
      MessagePopupController.showInfo(
        messageKey: 'otp_sent_to_email',
        titleKey: 'info',
      );

      // Start countdown
      countdown.value = 60;
      _startCountdown();
    } else {
      // Only show error for actual failures
      MessagePopupController.showError(
        messageKey: 'failed_to_send_otp',
        titleKey: 'error',
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
      MessagePopupController.showError(
        messageKey: 'enter_otp_code',
        titleKey: 'error',
      );
      return;
    }

    if (code.length != 6) {
      MessagePopupController.showError(
        messageKey: 'otp_must_be_6_digits',
        titleKey: 'error',
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
      // Check if this is from document password flow
      if (fromDocumentPassword.value) {
        // Return success result to Document Password screen
        // The Document Password controller will handle saving the password
        Get.back(result: true);
        return;
      } else if (fromForgotPassword.value) {
        // Navigate to forgot change password screen
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(AppRoutes.FORGOT_CHANGE_PASSWORD);
      } else {
        // Refresh local FCM token after OTP (backend token sent on initial login payload)
        try {
          if (Get.isRegistered<FcmService>()) {
            await Get.find<FcmService>().registerAfterAuth();
          }
        } catch (_) {}

        final firebaseOk = await _authRepository.syncFirebaseAuthAfterLogin();
        debugPrint(
          '[OtpVerification] Firebase sync after OTP ok=$firebaseOk uid=${Get.find<FirebaseAuthService>().firebaseUid}',
        );

        // Pre-load documents in background while navigating
        _preloadDocuments();

        // Navigate to home
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(AppRoutes.HOME);
      }
    } else {
      // 2FA verification failed
      if (fromDocumentPassword.value) {
        // Return false result to Document Password screen
        // Don't show error here - let the user try again or cancel
        MessagePopupController.showError(
          messageKey: 'invalid_otp_code',
          titleKey: 'error',
        );
        otpController.clear();
        // Stay on 2FA screen - user can retry or cancel
      } else {
        // For login flow, show error and stay on screen
        MessagePopupController.showError(
          messageKey: 'invalid_otp_code',
          titleKey: 'error',
        );
        otpController.clear();
      }
    }
  }

  Future<void> resendOTP() async {
    if (countdown.value > 0) {
      MessagePopupController.showInfo(
        messageKey: 'please_wait_to_resend'.tr.replaceAll('{seconds}', countdown.value.toString()),
        titleKey: 'info',
      );
      return;
    }

    await sendOTP();
  }

  void cancelVerification() {
    if (fromDocumentPassword.value) {
      Get.dialog(
        Builder(
          builder: (_) => ResponsiveAlertDialog(
            scrollable: true,
            title: Text(
              'cancel_verification'.tr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            content: Text(
              'document_password_2fa_cancel_message'.tr,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'no'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  try {
                    final documentPasswordController =
                        Get.find<DocumentPasswordController>();
                    documentPasswordController.cancel2FAFlow();
                  } catch (e) {
                    // Controller might not be found, that's okay
                  }
                  Get.back(result: false);
                },
                child: Text(
                  'yes'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      Get.dialog(
        Builder(
          builder: (_) => ResponsiveAlertDialog(
            scrollable: true,
            title: Text(
              'cancel_verification'.tr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            content: Text(
              'cancel_verification_message'.tr,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'no'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  _logout();
                },
                child: Text(
                  'yes'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
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
            final documentsController = Get.put(
              DocumentsController(skipInitialFetch: true),
            );
            final documentsData = result['data'] as List<dynamic>;
            final parsed = documentsData.map<DocumentModel>((item) {
              if (item is DocumentModel) return item;
              return DocumentModel.fromJson(item as Map<String, dynamic>);
            }).toList();
            documentsController.applyDocuments(parsed);
            await documentsController.fetchDocumentCategories();
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
    await _storageService.clearAll();

    AuthNavigation.replaceStackWithAuth();
  }
}