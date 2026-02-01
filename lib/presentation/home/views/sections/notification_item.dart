import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../data/models/feed_item_model.dart';
import '../../../../core/localization/locale_controller.dart';

class NotificationItem extends StatelessWidget {
  final dynamic item;
  final VoidCallback? onTap;
  final VoidCallback? onChatPressed;
  final VoidCallback? onAssistancePressed;
  final VoidCallback? onAiSupportPressed;

  const NotificationItem({
    super.key,
    required this.item,
    this.onTap,
    this.onChatPressed,
    this.onAssistancePressed,
    this.onAiSupportPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = item.isRead ?? false;
    
    // Determine border color based on notification type for card styling
    Color borderColor;
    if (item.type == 'maintenance') {
      borderColor = AppColors.warning;
    } else if (item.type == 'document' || item.type == 'documents') {
      borderColor = AppColors.brandSage500;
    } else {
      borderColor = AppColors.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isRead
                  ? const [
                      AppColors.surfaceWhite,
                      AppColors.surfaceWarm50,
                    ]
                  : [
                      AppColors.surfaceWhite,
                      AppColors.brandSage50.withOpacity(0.3),
                    ],
            ),
            border: Border.all(
              color: isRead
                  ? AppColors.neutralLine200.withOpacity(0.4)
                  : borderColor.withOpacity(0.3),
              width: isRead ? 1 : 1.5,
            ),
            boxShadow: AppShadows.customColoredShadow(
              borderColor,
              opacity: isRead ? 0.08 : 0.12,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TEXTS (reactive to language changes)
                Expanded(
                  child: Obx(() {
                    // Get LocaleController to observe language changes
                    final localeController = Get.find<LocaleController>();
                    // Access reactive locale property to trigger updates on language change
                    final currentLocale = localeController.locale;
                    
                    // Use computed bilingual getters from model
                    // These getters check LocaleController internally, but we ensure reactivity here
                    final displayTitle = item is FeedItemModel 
                        ? item.localizedDisplayTitle 
                        : item.title;
                    final displayContent = item is FeedItemModel 
                        ? item.localizedDisplayContent 
                        : item.description;
                    
                    // Use currentLocale to ensure Obx tracks the change (triggers rebuild on language change)
                    final _ = currentLocale;
                    
                    // Get category icon for this notification type
                    final categoryIcon = _getNotificationIcon(item.type ?? '');
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Category icon on the LEFT of title
                            _buildCategoryIcon(categoryIcon, item.type ?? ''),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                displayTitle,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: isRead
                                      ? FontWeight.w600
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            // Unread indicator dot
                            if (!isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: borderColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: borderColor.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayContent,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isRead
                                ? AppColors.neutralInk500
                                : AppColors.neutralInk700,
                            fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.neutralInk300,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.timeAgo,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.neutralInk400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Action Buttons Row
                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: _buildActionButton(
                        //         label: 'Chat',
                        //         icon: Icons.chat_bubble_outline,
                        //         onPressed: onChatPressed != null
                        //             ? () => onChatPressed!()
                        //             : null,
                        //       ),
                        //     ),
                        //     const SizedBox(width: 8),
                        //     Expanded(
                        //       child: _buildActionButton(
                        //         label: 'Assistance',
                        //         icon: Icons.support_agent_outlined,
                        //         onPressed: onAssistancePressed != null
                        //             ? () => onAssistancePressed!()
                        //             : null,
                        //       ),
                        //     ),
                        //     const SizedBox(width: 8),
                        //     Expanded(
                        //       child: _buildActionButton(
                        //         label: 'AI Support',
                        //         icon: Icons.smart_toy_outlined,
                        //         onPressed: onAiSupportPressed != null
                        //             ? () => onAiSupportPressed!()
                        //             : null,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get notification icon based on type
  /// Returns appropriate icon for each notification category
  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'maintenance':
        return Icons.build_outlined; // wrench/tools icon
      case 'documents':
      case 'document':
        return Icons.description_outlined; // file/document icon
      case 'payments':
      case 'payment':
        return Icons.credit_card_outlined; // credit card/wallet icon
      case 'messages':
      case 'message':
        return Icons.chat_bubble_outline; // chat/message icon
      case 'booking':
      case 'bookings':
        return Icons.calendar_today_outlined; // calendar icon
      case 'security':
        return Icons.shield_outlined; // shield/lock icon
      case 'system':
        return Icons.notifications_outlined; // bell/info icon
      default:
        return Icons.notifications_outlined; // default bell icon
    }
  }

  /// Build category icon container
  /// Small circular icon (28-32px) with subtle background, aligned left of title
  Widget _buildCategoryIcon(IconData icon, String type) {
    // Use app primary color for icons
    final iconColor = AppColors.brandSage600;
    // Subtle circular background (8-12% opacity)
    final iconBgColor = AppColors.brandSage500.withOpacity(0.1);
    
    // Get semantic label for accessibility
    final semanticLabel = _getNotificationSemanticLabel(type);
    
    return Semantics(
      label: semanticLabel,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 18,
        ),
      ),
    );
  }

  /// Get semantic label for accessibility (localized)
  String _getNotificationSemanticLabel(String type) {
    switch (type.toLowerCase()) {
      case 'maintenance':
        return 'notification_type_maintenance'.tr;
      case 'documents':
      case 'document':
        return 'notification_type_document'.tr;
      case 'payments':
      case 'payment':
        return 'notification_type_payment'.tr;
      case 'messages':
      case 'message':
        return 'notification_type_message'.tr;
      case 'booking':
      case 'bookings':
        return 'notification_type_booking'.tr;
      case 'security':
        return 'notification_type_security'.tr;
      case 'system':
        return 'notification_type_system'.tr;
      default:
        return 'notification_type_generic'.tr;
    }
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandSage600,
          side: BorderSide(
            color: AppColors.brandSage300,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(0, 32),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.brandSage600),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.brandSage600,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
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
