import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

import '../../../data/models/user_model.dart';
import '../../../presentation/profile/controllers/profile_controller.dart';
import '../../app/theme/app_shadows.dart';

class NotificationSettingsCard extends StatelessWidget {
  final UserModel user;

  const NotificationSettingsCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    return Obx(() {
      // Use the observable user from ProfileController if available, otherwise use the prop
      final currentUser = profileController.user.value ?? user;

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
            Text("notification_preferences".tr, style: AppTextStyles.CardHeaderText),
            const SizedBox(height: 4),
            Text(
              "notification_desc".tr,
              style: AppTextStyles.cardText.copyWith(
                color: AppColors.neutralInk500,
              ),
            ),
            const SizedBox(height: 16),

            _buildSwitch(
              icon: Icons.description_outlined,
              label: "documents".tr,
              value: currentUser.isDocumentNotify,
              onChanged: (v) {
                profileController.updateNotification('documents', v);
              },
            ),

            _buildSwitch(
              icon: Icons.build_outlined,
              label: "maintenance".tr,
              value: currentUser.isMaintenanceNotify,
              onChanged: (v) {
                profileController.updateNotification('maintenance', v);
              },
            ),

            _buildSwitch(
              icon: Icons.chat_bubble_outline,
              label: "chat_messages".tr,
              value: currentUser.isChatNotify,
              onChanged: (v) {
                profileController.updateNotification('chat', v);
              },
            ),

            _buildSwitch(
              icon: Icons.support_agent_outlined,
              label: "support_tickets".tr,
              value: currentUser.isSupportTicketNotify,
              onChanged: (v) {
                profileController.updateNotification('tickets', v);
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSwitch({
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.neutralInk500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.cardText.copyWith(
                color: AppColors.neutralInk900,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged)
        ],
      ),
    );
  }
}