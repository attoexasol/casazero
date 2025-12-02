import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

import '../../../data/models/user_model.dart';
import '../../app/theme/app_shadows.dart';
import '../utils/permissions.dart';

class AdminSettingsCard extends StatelessWidget {
  final UserModel user;
  final Function(String screen)? onNavigate;

  const AdminSettingsCard({
    super.key,
    required this.user,
    this.onNavigate,
  });

  bool get isAdmin =>
      user.role == Role.admin || user.role == Role.manager;

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.shadowPremium,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("admin_settings".tr, style: AppTextStyles.h4),
          const SizedBox(height: 6),
          Text(
            "admin_settings_desc".tr,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),

          // Building Management
          _item(
            icon: Icons.apartment_rounded,
            label: "building_management".tr,
            onTap: () => onNavigate?.call("buildings"),
          ),

          // User Management
          _item(
            icon: Icons.group_outlined,
            label: "user_management".tr,
            onTap: () => onNavigate?.call("users"),
          ),

          // System Config (Admin only)
          if (user.role == Role.admin)
            _item(
              icon: Icons.settings_suggest_outlined,
              label: "system_configuration".tr,
              onTap: () => onNavigate?.call("system-config"),
            ),
        ],
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.neutralInk500),
            const SizedBox(width: 12),

            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutralInk900,
                ),
              ),
            ),

            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.neutralInk400,
            ),
          ],
        ),
      ),
    );
  }
}
