import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

import '../../../data/models/user_model.dart';
import '../../../presentation/profile/controllers/profile_controller.dart';
import '../../app/theme/app_shadows.dart';

class NotificationSettingsCard extends StatelessWidget {
  final UserModel user;

  const NotificationSettingsCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    // Initialize user in ProfileController if null (only once, outside Obx)
    // Use postFrameCallback to avoid calling during build
    if (profileController.user.value == null) {
      // Try loading from storage first (synchronous check)
      profileController.loadUser();
      // If still null after loading, sync from prop in next frame
      if (profileController.user.value == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (profileController.user.value == null) {
            profileController.user.value = user;
            print('📥 [NotificationCard] User initialized from prop');
          }
        });
      }
    }

    return Obx(() {
      // Directly access the reactive user value - Obx will track changes
      // Access user.value directly in Obx to ensure reactivity
      final reactiveUser = profileController.user.value;

      // If still null, use prop (shouldn't happen after initialization)
      if (reactiveUser == null) {
        return const SizedBox.shrink(); // Don't render if no user
      }

      // Access notification values directly from reactive user to ensure Obx tracks them
      final isDocumentNotify = reactiveUser.isDocumentNotify;
      final isMaintenanceNotify = reactiveUser.isMaintenanceNotify;
      final isChatNotify = reactiveUser.isChatNotify;
      final isSupportTicketNotify = reactiveUser.isSupportTicketNotify;

      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.shadowProfileCard,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "notification_preferences".tr,
              style: AppTextStyles.CardHeaderText,
            ),
            const SizedBox(height: 4),
            Text(
              "notification_desc".tr,
              style: AppTextStyles.cardText.copyWith(
                color: AppColors.neutralInk500,
              ),
            ),
            const SizedBox(height: 16),

            _buildSwitch(
              key: const ValueKey('documents'),
              icon: Icons.description_outlined,
              label: "documents".tr,
              value: isDocumentNotify,
              onChanged: (v) {
                print('🔘 [NotificationCard] Documents switch toggled: $v');
                profileController.updateNotification('documents', v);
              },
            ),
            const SizedBox(height: 12),

            _buildSwitch(
              key: const ValueKey('maintenance'),
              icon: Icons.build_outlined,
              label: "maintenance".tr,
              value: isMaintenanceNotify,
              onChanged: (v) {
                print('🔘 [NotificationCard] Maintenance switch toggled: $v');
                profileController.updateNotification('maintenance', v);
              },
            ),
            const SizedBox(height: 12),

            _buildSwitch(
              key: const ValueKey('chat'),
              icon: Icons.chat_bubble_outline,
              label: "chat_messages".tr,
              value: isChatNotify,
              onChanged: (v) {
                print('🔘 [NotificationCard] Chat switch toggled: $v');
                profileController.updateNotification('chat', v);
              },
            ),
            const SizedBox(height: 12),

            _buildSwitch(
              key: const ValueKey('tickets'),
              icon: Icons.support_agent_outlined,
              label: "support_tickets".tr,
              value: isSupportTicketNotify,
              onChanged: (v) {
                print('🔘 [NotificationCard] Tickets switch toggled: $v');
                profileController.updateNotification('tickets', v);
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSwitch({
    Key? key,
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          Switch(
            value: value,
            onChanged: (newValue) {
              print(
                '🔘 [NotificationCard] Switch tapped: $label = $newValue (was $value)',
              );
              // Call the callback immediately to update state
              onChanged(newValue);
              print(
                '✅ [NotificationCard] Switch callback executed for: $label',
              );
            },
          ),
        ],
      ),
    );
  }
}
