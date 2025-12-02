import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../presentation/profile/controllers/profile_controller.dart';

class LogoutSection extends StatelessWidget {
  final VoidCallback onLogoutTap;

  const LogoutSection({super.key, required this.onLogoutTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.shadowPremium,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _saveSettingsButton(context),
          const SizedBox(height: 12),
          _logoutButton(context),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SAVE SETTINGS BUTTON
  // -------------------------------------------------------------------------
  Widget _saveSettingsButton(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();

    return Obx(() {
      final isLoading = controller.isSaving.value;

      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandSage600,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.save),
        label: Text(
          isLoading ? 'saving'.tr : 'save_settings'.tr,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: isLoading ? null : () => controller.saveSettings(),
      );
    });
  }

  // -------------------------------------------------------------------------
  // LOGOUT BUTTON
  // -------------------------------------------------------------------------
  Widget _logoutButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.danger.withOpacity(.1),
        foregroundColor: AppColors.danger,
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.logout),
      label: Text(
        "logout".tr,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.danger,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: () => _showLogoutDialog(context),
    );
  }

  // -------------------------------------------------------------------------
  // LOGOUT CONFIRMATION POPUP
  // -------------------------------------------------------------------------

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "confirm_logout".tr,
          style: AppTextStyles.h4,
        ),
        content: Text(
          "are_you_sure_logout".tr,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutralInk700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("cancel".tr),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onLogoutTap();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text("logout".tr),
          ),
        ],
      ),
    );
  }
}