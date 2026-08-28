import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/controllers/message_popup_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/navigation/auth_navigation.dart';
import '../../../core/services/session_expiry_service.dart';
import '../../home/controllers/home_controller.dart';
import '../../../core/logging/diagnostic_logger.dart';

class ProfileController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final ProfileRepository _profileRepository = ProfileRepository();
  final AuthRepository _authRepository = AuthRepository();
  final ImagePicker _imagePicker = ImagePicker();

  Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isSaving = false.obs;
  final RxBool isUploadingImage = false.obs;
  final RxBool isChangingLanguage = false.obs;
  // Refresh timestamp for cache-busting profile images on pull-to-refresh
  final RxInt imageRefreshTimestamp = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadUser();
    // unit_name is returned by /user/profile, not by login storage or
    // /residences/by-token — fetch profile so ResidenceInfoCard can show it
    // without requiring a manual pull-to-refresh.
    final unitName = user.value?.unitName;
    if (unitName == null || unitName.isEmpty) {
      refreshData();
    }
  }

  /// Load user from storage
  /// Only updates if user.value is null to avoid overwriting reactive changes
  void loadUser() {
    // Only load from storage if user is not already set
    // This prevents overwriting reactive updates with stale storage data
    if (user.value == null) {
      final data = _storage.getUserData();
      if (data != null) {
        user.value = UserModel.fromJson(data);
        DiagnosticLogger.instance.warning('📥 [ProfileController] User loaded from storage');
      }
    } else {
      DiagnosticLogger.instance.warning(
        '⚠️ [ProfileController] loadUser() called but user.value is already set - skipping to preserve reactive state',
      );
    }
  }

  /// Force reload user from storage (use with caution - will overwrite reactive state)
  void forceReloadUser() {
    final data = _storage.getUserData();
    if (data != null) {
      user.value = UserModel.fromJson(data);
      DiagnosticLogger.instance.debug('🔄 [ProfileController] User force-reloaded from storage');
    }
  }

  /// Refresh user data from backend API
  /// Fetches latest user profile from server and updates local storage and reactive state
  /// Also syncs with HomeController if available to ensure app-wide consistency
  Future<void> refreshData() async {
    try {
      DiagnosticLogger.instance.debug('🔄 [ProfileController] Refreshing user data from backend...');
      
      // Fetch latest user data from backend API
      final updatedUser = await _authRepository.getUserProfile();
      
      if (updatedUser != null) {
        // Update reactive state with latest data
        user.value = updatedUser;
        
        // Update local storage with latest data
        await _storage.saveUserData(updatedUser.toJson());
        
        // Update refresh timestamp to force image cache invalidation
        // This ensures profile image is reloaded from backend even if URL is the same
        imageRefreshTimestamp.value = DateTime.now().millisecondsSinceEpoch;
        
        // Sync with HomeController if available to ensure app-wide consistency
        try {
          if (Get.isRegistered<HomeController>()) {
            final homeController = Get.find<HomeController>();
            homeController.currentUser.value = updatedUser;
            DiagnosticLogger.instance.warning('✅ [ProfileController] Synced updated user data to HomeController');
          }
        } catch (e) {
          DiagnosticLogger.instance.warning('⚠️ [ProfileController] Could not sync with HomeController: $e');
          // Non-critical - continue even if HomeController sync fails
        }
        
        DiagnosticLogger.instance.info('✅ [ProfileController] User data refreshed successfully from backend');
        DiagnosticLogger.instance.debug('   User ID: ${updatedUser.id}');
        DiagnosticLogger.instance.debug('   User Name: ${updatedUser.userName}');
        DiagnosticLogger.instance.debug('   Role: ${updatedUser.role.name} (API/storage)');
        DiagnosticLogger.instance.warning('   Email: ${updatedUser.email}');
        DiagnosticLogger.instance.warning('   Image refresh timestamp: ${imageRefreshTimestamp.value}');
      } else {
        DiagnosticLogger.instance.warning('⚠️ [ProfileController] Failed to fetch user data from backend');
        // Fallback: reload from storage if API fails
        forceReloadUser();
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [ProfileController] Error refreshing user data: $e');
      // Fallback: reload from storage if API fails
      forceReloadUser();
    }
  }

  /// Sync user data from external source (e.g., HomeController)
  /// Ensures ProfileController has the latest user data
  /// Only updates if user is null or user ID changed - preserves reactive updates
  void syncUserData(UserModel updatedUser) {
    // Only sync if user is null or it's a different user
    // This prevents overwriting reactive updates with stale data
    if (user.value == null) {
      DiagnosticLogger.instance.debug(
        '📥 [ProfileController] syncUserData: User is null, syncing from external source',
      );
      user.value = updatedUser;
      _saveUserToStorage();
    } else if (user.value!.id != updatedUser.id) {
      DiagnosticLogger.instance.debug(
        '📥 [ProfileController] syncUserData: Different user ID, syncing from external source',
      );
      user.value = updatedUser;
      _saveUserToStorage();
    } else {
      // Same user - don't overwrite reactive state with potentially stale data
      DiagnosticLogger.instance.warning(
        '⚠️ [ProfileController] syncUserData: Same user detected, skipping sync to preserve reactive state',
      );
      DiagnosticLogger.instance.debug('   Current user hash: ${user.value!.hashCode}');
      DiagnosticLogger.instance.debug('   Incoming user hash: ${updatedUser.hashCode}');
    }
  }

  /// Pick and upload profile image
  Future<void> pickAndUploadProfileImage() async {
    if (user.value == null) {
      _showError('no_user_data');
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
        // Get the new image URL from API response
        final newImageUrl = result['image_url'] as String?;
        
        // Directly update the user model with the new image URL
        // This bypasses the loadUser() guard and ensures immediate UI update
        if (user.value != null && newImageUrl != null) {
          user.value = user.value!.copyWith(profileImage: newImageUrl);
          // Also update storage to keep it in sync
          await _saveUserToStorage();
        } else {
          // Fallback: force reload from storage if direct update fails
          forceReloadUser();
        }
        
        _showSuccess('profile_image_updated');
      } else {
        _showError('failed_to_upload_image');
      }
    } catch (e) {
      _showError('error_uploading_image');
      DiagnosticLogger.instance.error('Error uploading profile image: $e');
    } finally {
      isUploadingImage.value = false;
    }
  }

  /// Update language and call API to save to database
  Future<void> changeLanguage(String lang) async {
    if (user.value == null) {
      _showError('no_user_data');
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

        // Update LocaleController (single source of truth for app language)
        final localeController = Get.find<LocaleController>();
        await localeController.changeLocale(lang);

        _showSuccess('language_updated_successfully');
        update();
      } else {
        _showError('failed_to_update_language');
      }
    } catch (e) {
      _showError('error_updating_language');
      DiagnosticLogger.instance.error('Error changing language: $e');
    } finally {
      isChangingLanguage.value = false;
    }
  }

  /// Update notification setting and save
  Future<void> updateNotification(String key, bool value) async {
    DiagnosticLogger.instance.error('🔄 [ProfileController] updateNotification called: $key = $value');

    if (user.value == null) {
      DiagnosticLogger.instance.error('❌ [ProfileController] User is null, cannot update notification');
      return;
    }

    // Get current user state BEFORE any potential reloads
    // Capture the reference to ensure we're working with the current reactive value
    final currentUser = user.value!;
    DiagnosticLogger.instance.debug('📝 [ProfileController] Current user state (from reactive value):');
    DiagnosticLogger.instance.debug('   User object hash: ${currentUser.hashCode}');
    DiagnosticLogger.instance.debug('   isDocumentNotify: ${currentUser.isDocumentNotify}');
    DiagnosticLogger.instance.debug('   isMaintenanceNotify: ${currentUser.isMaintenanceNotify}');
    DiagnosticLogger.instance.debug('   isChatNotify: ${currentUser.isChatNotify}');
    DiagnosticLogger.instance.debug('   isSupportTicketNotify: ${currentUser.isSupportTicketNotify}');

    // Double-check: Read from reactive value again to ensure it hasn't changed
    final doubleCheckUser = user.value!;
    if (currentUser.hashCode != doubleCheckUser.hashCode) {
      DiagnosticLogger.instance.warning(
        '⚠️ [ProfileController] WARNING: user.value changed during updateNotification!',
      );
      DiagnosticLogger.instance.debug('   Original hash: ${currentUser.hashCode}');
      DiagnosticLogger.instance.debug('   New hash: ${doubleCheckUser.hashCode}');
    }

    UserModel? updatedUser;
    switch (key) {
      case 'documents':
        updatedUser = currentUser.copyWith(isDocumentNotify: value);
        break;
      case 'maintenance':
        updatedUser = currentUser.copyWith(isMaintenanceNotify: value);
        break;
      case 'chat':
        updatedUser = currentUser.copyWith(isChatNotify: value);
        break;
      case 'tickets':
        updatedUser = currentUser.copyWith(isSupportTicketNotify: value);
        break;
      default:
        DiagnosticLogger.instance.warning('⚠️ [ProfileController] Unknown notification key: $key');
        return;
    }

    // updatedUser is guaranteed to be non-null here (default case returns early)
    // Update the reactive value FIRST to trigger UI update
    // Assigning a new object reference will trigger GetX observers
    user.value = updatedUser;

    DiagnosticLogger.instance.info('✅ [ProfileController] User updated in reactive state:');
    DiagnosticLogger.instance.debug('   isDocumentNotify: ${user.value!.isDocumentNotify}');
    DiagnosticLogger.instance.debug('   isMaintenanceNotify: ${user.value!.isMaintenanceNotify}');
    DiagnosticLogger.instance.debug('   isChatNotify: ${user.value!.isChatNotify}');
    DiagnosticLogger.instance.debug('   isSupportTicketNotify: ${user.value!.isSupportTicketNotify}');
    DiagnosticLogger.instance.debug('   User object hash after update: ${user.value!.hashCode}');

    // Save to storage AFTER updating reactive value
    await _saveUserToStorage();

    // Trigger GetX update for GetBuilder widgets (though Obx should auto-update)
    update();

    DiagnosticLogger.instance.debug('💾 [ProfileController] User saved to storage and UI updated');
  }

  /// Update user profile information (name, email, phone)
  Future<bool> updateUserInfo({
    String? userName,
    String? email,
    String? phone,
  }) async {
    if (user.value == null) {
      _showError('no_user_data');
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

      final success = result['success'] == true ||
          result['success'] == 'true' ||
          result['status'] == true ||
          result['status'] == 'true';
      if (success) {
        // Close the edit profile dialog first (if open)
        Get.back(closeOverlays: false);
        // Reload user data from storage (updated by repository)
        loadUser();
        // Ensure the UI updates immediately by triggering a rebuild
        update();
        _showSuccess('profile_updated_successfully');
        return true;
      } else {
        _showError('failed_to_update_profile');
        return false;
      }
    } catch (e) {
      _showError('error_updating_profile');
      DiagnosticLogger.instance.error('Error updating profile: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Save all settings to server
  /// Saves: Language, Notification preferences, Profile info
  /// Ensures all settings are validated, persisted locally, and synced to server
  Future<void> saveSettings() async {
    DiagnosticLogger.instance.error('🔵 [ProfileController] saveSettings() called');

    if (user.value == null) {
      DiagnosticLogger.instance.error('❌ [ProfileController] User is null, cannot save settings');
      _showError('no_user_data');
      return;
    }

    DiagnosticLogger.instance.info(
      '✅ [ProfileController] User found: ${user.value!.id} - ${user.value!.userName}',
    );
    isSaving.value = true;

    try {
      // Step 1: Sync language from LocaleController (single source of truth)
      // This ensures the language setting matches what's currently active in the app
      final localeController = Get.find<LocaleController>();
      final currentLanguage = localeController.currentLanguageCode;

      // Update user's language if it differs from LocaleController
      if (user.value!.language != currentLanguage) {
        DiagnosticLogger.instance.debug(
          '🔄 [ProfileController] Syncing language from LocaleController: $currentLanguage',
        );
        user.value = user.value!.copyWith(language: currentLanguage);
      }

      // Step 2: Ensure all local changes are saved to storage first
      await _saveUserToStorage();
      DiagnosticLogger.instance.debug('💾 [ProfileController] User data saved to local storage');

      // Step 3: Get current user from reactive state (has latest changes)
      final currentUser = user.value!;
      DiagnosticLogger.instance.debug(
        '👤 [ProfileController] Preparing to save settings for user: ${currentUser.id}',
      );
      DiagnosticLogger.instance.debug('   Language: ${currentUser.language}');
      DiagnosticLogger.instance.debug('   Notifications - Documents: ${currentUser.isDocumentNotify}');
      DiagnosticLogger.instance.debug(
        '   Notifications - Maintenance: ${currentUser.isMaintenanceNotify}',
      );
      DiagnosticLogger.instance.debug('   Notifications - Chat: ${currentUser.isChatNotify}');
      DiagnosticLogger.instance.info(
        '   Notifications - Support Tickets: ${currentUser.isSupportTicketNotify}',
      );

      // Step 4: Save all settings to API
      DiagnosticLogger.instance.info('📡 [ProfileController] Calling updateProfile() API...');
      final result = await _profileRepository.updateProfile(
        userId: currentUser.id,
        userName: currentUser.userName,
        email: currentUser.email,
        phone: currentUser.phone,
        language: currentUser.language,
        profileImage: currentUser.profileImage,
        isDocumentNotify: currentUser.isDocumentNotify,
        isMaintenanceNotify: currentUser.isMaintenanceNotify,
        isChatNotify: currentUser.isChatNotify,
        isSupportTicketNotify: currentUser.isSupportTicketNotify,
        // Note: twoFaMethod is not included in Save Settings request
      );

      DiagnosticLogger.instance.debug('📥 [ProfileController] Received result from updateProfile()');
      DiagnosticLogger.instance.debug('   Success: ${result['success']}');
      DiagnosticLogger.instance.debug('   Message: ${result['message'] ?? result['error']}');

      if (result['success'] == true) {
        // Step 5: Force reload user data from storage (updated by repository after API success)
        // This ensures we have the latest data from the server
        forceReloadUser();

        // Step 6: Ensure UI updates immediately
        update();

        DiagnosticLogger.instance.info('✅ [ProfileController] All settings saved successfully');
        DiagnosticLogger.instance.error('   Settings persisted to: Local storage + Server API');
        _showSuccess('settings_saved_successfully');
      } else {
        DiagnosticLogger.instance.error(
          '❌ [ProfileController] Failed to save settings: ${result['error']}',
        );
        _showError('failed_to_save_settings');
      }
    } catch (e, stackTrace) {
      DiagnosticLogger.instance.error('❌ [ProfileController] Exception in saveSettings(): $e');
      DiagnosticLogger.instance.error('📚 [ProfileController] Stack trace: $stackTrace');
      _showError('error_saving_settings');
    } finally {
      isSaving.value = false;
      DiagnosticLogger.instance.debug('🏁 [ProfileController] saveSettings() completed');
    }
  }

  /// Logout action
  /// Calls logout API, then clears all storage and navigates to auth screen
  Future<void> logout() async {
    SessionExpiryService.beginForcedSignOut();
    try {
      DiagnosticLogger.instance.info('🚪 Starting logout process...');

      // Call logout API first
      final result = await _authRepository.logout();

      if (result['success'] == true) {
        DiagnosticLogger.instance.warning('✅ Logout API successful: ${result['message']}');
      } else {
        DiagnosticLogger.instance.warning('⚠️  Logout API failed: ${result['error']}');
        // Still proceed with clearing storage even if API fails
      }

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().clearStateOnLogout();
      }
      user.value = null;

      // Clear all storage regardless of API result
      await _storage.clearAll();
      DiagnosticLogger.instance.info('✅ All storage cleared');

      // Navigate to auth screen
      AuthNavigation.replaceStackWithAuth();
      DiagnosticLogger.instance.error('✅ Navigated to auth screen');
    } catch (e) {
      DiagnosticLogger.instance.error('❌ Error during logout: $e');
      // Even if there's an error, try to clear storage and navigate
      try {
        await _storage.clearAll();
        AuthNavigation.replaceStackWithAuth();
      } catch (clearError) {
        DiagnosticLogger.instance.error('❌ Error clearing storage: $clearError');
        _showError('failed_to_logout_please_try_again');
      }
    }
  }

  Future<void> _saveUserToStorage() async {
    if (user.value != null) {
      await _storage.saveUserData(user.value!.toJson());
      DiagnosticLogger.instance.debug('💾 [ProfileController] User data saved to storage successfully');
    }
  }

  // -------------------------------------------------------------------------
  // POPUP MESSAGES
  // -------------------------------------------------------------------------

  void _showError(String messageKey) {
    MessagePopupController.showError(
      messageKey: messageKey,
      titleKey: 'error',
    );
  }

  void _showSuccess(String messageKey) {
    MessagePopupController.showSuccess(
      messageKey: messageKey,
      titleKey: '',
    );
  }
}
