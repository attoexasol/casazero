import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/storage_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import 'package:flutter/material.dart';

class ProfileController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final ProfileRepository _profileRepository = ProfileRepository();
  final AuthRepository _authRepository = AuthRepository();
  final ImagePicker _imagePicker = ImagePicker();

  Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isSaving = false.obs;
  final RxBool isUploadingImage = false.obs;
  final RxBool isChangingLanguage = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  /// Load user from storage
  void loadUser() {
    final data = _storage.getUserData();
    if (data != null) {
      user.value = UserModel.fromJson(data);
    }
  }

  /// Pick and upload profile image
  Future<void> pickAndUploadProfileImage() async {
    if (user.value == null) {
      _showError('no_user_data'.tr);
      return;
    }

    try {
      // Pick image from gallery
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        // User cancelled
        return;
      }

      // Start uploading
      isUploadingImage.value = true;

      // Upload to server
      final result = await _profileRepository.uploadProfileImage(
        userId: user.value!.id,
        filePath: pickedFile.path,
      );

      if (result['success'] == true) {
        // Reload user data from storage (updated by repository)
        loadUser();
        _showSuccess(result['message'] ?? 'profile_image_updated'.tr);
      } else {
        _showError(result['error'] ?? 'failed_to_upload_image'.tr);
      }
    } catch (e) {
      _showError('error_uploading_image'.tr);
      print('Error uploading profile image: $e');
    } finally {
      isUploadingImage.value = false;
    }
  }

  /// Update language and call API to save to database
  Future<void> changeLanguage(String lang) async {
    if (user.value == null) {
      _showError('no_user_data'.tr);
      return;
    }

    try {
      isChangingLanguage.value = true;

      // Call API to update language in database
      final result = await _profileRepository.changeLanguage(
        userId: user.value!.id,
        language: lang,
      );

      if (result['success'] == true) {
        // Update local user data
        user.value = user.value!.copyWith(language: lang);

        // Update GetX locale
        if (lang == "it") {
          Get.updateLocale(const Locale('it', 'IT'));
        } else {
          Get.updateLocale(const Locale('en', 'US'));
        }

        _showSuccess(result['message'] ?? 'language_updated_successfully'.tr);
        update();
      } else {
        _showError(result['error'] ?? 'failed_to_update_language'.tr);
      }
    } catch (e) {
      _showError('error_updating_language'.tr);
      print('Error changing language: $e');
    } finally {
      isChangingLanguage.value = false;
    }
  }

  /// Update notification setting and save
  void updateNotification(String key, bool value) {
    if (user.value == null) return;

    switch (key) {
      case 'documents':
        user.value = user.value!.copyWith(isDocumentNotify: value);
        break;
      case 'maintenance':
        user.value = user.value!.copyWith(isMaintenanceNotify: value);
        break;
      case 'chat':
        user.value = user.value!.copyWith(isChatNotify: value);
        break;
      case 'tickets':
        user.value = user.value!.copyWith(isSupportTicketNotify: value);
        break;
    }

    _saveUserToStorage();
    update();
  }

  /// Update user profile information (name, email, phone)
  Future<bool> updateUserInfo({
    String? userName,
    String? email,
    String? phone,
  }) async {
    if (user.value == null) {
      _showError('no_user_data'.tr);
      return false;
    }

    isSaving.value = true;

    try {
      // Call repository to update profile
      final result = await _profileRepository.updateProfile(
        userId: user.value!.id,
        userName: userName,
        email: email,
        phone: phone,
      );

      if (result['success'] == true) {
        // Reload user data from storage (updated by repository)
        loadUser();
        _showSuccess(result['message'] ?? 'profile_updated_successfully'.tr);
        return true;
      } else {
        _showError(result['error'] ?? 'failed_to_update_profile'.tr);
        return false;
      }
    } catch (e) {
      _showError('error_updating_profile'.tr);
      print('Error updating profile: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Save settings to server
  Future<void> saveSettings() async {
    if (user.value == null) {
      _showError('no_user_data'.tr);
      return;
    }

    isSaving.value = true;

    try {
      final result = await _profileRepository.updateProfileFromStorage();

      if (result['success'] == true) {
        // Reload user data from storage (updated by repository)
        loadUser();
        _showSuccess(result['message'] ?? 'settings_saved_successfully'.tr);
      } else {
        _showError(result['error'] ?? 'failed_to_save_settings'.tr);
      }
    } catch (e) {
      _showError('error_saving_settings'.tr);
    } finally {
      isSaving.value = false;
    }
  }

  /// Logout action
  /// Calls logout API, then clears all storage and navigates to auth screen
  Future<void> logout() async {
    try {
      print('🚪 Starting logout process...');

      // Call logout API first
      final result = await _authRepository.logout();

      if (result['success'] == true) {
        print('✅ Logout API successful: ${result['message']}');
      } else {
        print('⚠️  Logout API failed: ${result['error']}');
        // Still proceed with clearing storage even if API fails
      }

      // Clear all storage regardless of API result
      await _storage.clearAll();
      print('✅ All storage cleared');

      // Navigate to auth screen
      Get.offAllNamed(AppRoutes.AUTH);
      print('✅ Navigated to auth screen');
    } catch (e) {
      print('❌ Error during logout: $e');
      // Even if there's an error, try to clear storage and navigate
      try {
        await _storage.clearAll();
        Get.offAllNamed(AppRoutes.AUTH);
      } catch (clearError) {
        print('❌ Error clearing storage: $clearError');
        _showError('Failed to logout. Please try again.');
      }
    }
  }

  void _saveUserToStorage() {
    if (user.value != null) {
      _storage.saveUserData(user.value!.toJson());
    }
  }

  // -------------------------------------------------------------------------
  // SNACKBARS
  // -------------------------------------------------------------------------

  void _showError(String message) {
    Get.snackbar(
      'error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'success'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.brandSage600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }
}