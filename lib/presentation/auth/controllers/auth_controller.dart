// presentation/auth/controllers/auth_controller.dart
// UPDATED WITH PHONE SUPPORT FOR LOGIN

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/message_popup_controller.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/models/user_model.dart';
import '../../documents/controllers/documents_controller.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/models/document_model.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/fcm_service.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final FirebaseAuthService _firebaseAuthService = Get.find();
  final StorageService _storageService = Get.find();
  final LocaleController _localeController = Get.find();

  // For development - remove in production
  final emailController = TextEditingController(text: 'ahmdsajid2200@gmail.com');
  final passwordController = TextEditingController(text: 'CasaZero@024017');
  final phoneController = TextEditingController(); // Add phone controller

  // For production - uncomment these
  // final emailController = TextEditingController();
  // final passwordController = TextEditingController();
  // final phoneController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  String get selectedLanguage => _localeController.currentLanguageCode;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void changeLanguage(String lang) {
    _localeController.changeLocale(lang);
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      MessagePopupController.showError(
        messageKey: 'enter_email_password',
        titleKey: 'error',
      );
      return;
    }

    isLoading.value = true;

    final result = await _authRepository.login(
      email: emailController.text.trim(),
      password: passwordController.text,
      phone: phoneController.text.trim().isEmpty
          ? null
          : phoneController.text.trim(),
    );

    isLoading.value = false;

    if (result['success']) {
      final UserModel user = result['user'];
      final bool isTrusted = result['is_trusted'] ?? false;

      // Save tokens and user data
      print('🔑 Login Access Token (from API): ${result['access_token']}');
      print('Is Trusted Device: $isTrusted');
      print('Is Password Set By Admin: ${user.isPasswordSetByAdmin}');

      // Access token + user already saved in AuthRepository.login (before Firebase sign-in).
      final storedToken = _storageService.getAccessToken();
      print('💾 Stored Access Token: $storedToken');

      await _storageService.saveUserData(user.toJson());
      await _storageService.setFirstLogin(user.isFirstLogin);

      debugPrint('[AuthController] Laravel login success user.id=${user.id}');

      // Firebase sign-in already ran inside AuthRepository.login(); sync if needed.
      var firebaseOk = result['firebase_signed_in'] == true;
      if (!firebaseOk) {
        firebaseOk = await _authRepository.syncFirebaseAuthAfterLogin();
      }
      _storageService.debugPrintStorageKeys();
      final uid = _firebaseAuthService.firebaseUid;
      debugPrint(
        '[AuthController] Firebase session uid=$uid syncOk=$firebaseOk '
        '(expected Laravel id string: ${user.id})',
      );
      if (!firebaseOk) {
        debugPrint(
          '[AuthController] WARNING: Firebase auth not established. '
          'Scroll up for [LOGIN API] response — if firebase_token is missing there, '
          'Laravel login is not sending it for this user/request (Flutter cannot fix without the field).',
        );
      }

      // Set user's preferred language from API
      await _localeController.changeLocale(user.language);

      // Register FCM token with backend (idempotent; login payload already sends token)
      try {
        if (Get.isRegistered<FcmService>()) {
          await Get.find<FcmService>().sendTokenToBackend();
        }
      } catch (_) {}

      // Pre-load documents in background while navigating
      _preloadDocuments();

      // Navigation logic based on user status and device trust
      _navigateBasedOnUserStatus(user, isTrusted);
    } else {
      MessagePopupController.showError(
        messageKey: 'invalid_credentials',
        titleKey: 'login_failed',
      );
    }
  }

  /// Enhanced navigation logic with trusted device check
  ///
  /// Priority Order:
  /// 1. Password set by admin (is_password_set_by_admin = true) → First Login Flow
  /// 2. Trusted device (is_trusted = true) → Home (skip 2FA)
  /// 3. Untrusted device + 2FA enabled → OTP Verification
  /// 4. Otherwise → Home
  void _navigateBasedOnUserStatus(UserModel user, bool isTrusted) {
    print('🔄 Navigation Decision:');
    print('  - Password Set By Admin: ${user.isPasswordSetByAdmin}');
    print('  - Is Trusted Device: $isTrusted');
    print('  - 2FA Enabled: ${user.is2FAEnabled}');

    // Priority 1: First login (password set by admin)
    // User must change password set by admin
    if (user.isPasswordSetByAdmin) {
      print('  → Going to FIRST_LOGIN (password change required)');
      Get.offAllNamed(AppRoutes.FIRST_LOGIN);
      return;
    }

    // Priority 2: Trusted device - Direct to HOME (skip 2FA)
    // If password is NOT set by admin AND device IS trusted
    // Then skip 2FA verification and go directly to HOME
    if (isTrusted) {
      print('  → Going to HOME (trusted device - skipping 2FA)');
      Get.offAllNamed(AppRoutes.HOME);
      return;
    }

    // Priority 3: Untrusted device + 2FA enabled
    // Device is not recognized, require 2FA verification
    if (user.is2FAEnabled) {
      print('  → Going to OTP_VERIFICATION (untrusted device - 2FA required)');
      Get.offAllNamed(AppRoutes.OTP_VERIFICATION);
      return;
    }

    // Priority 4: Untrusted device + No 2FA - Direct to HOME
    // This is less secure but follows the requested logic
    print('  → Going to HOME (untrusted device without 2FA)');
    Get.offAllNamed(AppRoutes.HOME);
  }

  /// Pre-load documents in background after login
  /// This ensures documents are ready when user navigates to documents screen
  void _preloadDocuments() {
    // Call in background - don't await, don't block navigation
    Future.microtask(() async {
      try {
        print('📄 Pre-loading documents after login...');
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

  Future<void> forgotPassword() async {
    // Navigate to forgot password screen
    Get.toNamed(AppRoutes.FORGOT_PASSWORD);
  }
}
