import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_shadows.dart';

class NotificationItem extends StatelessWidget {
  final dynamic item;
  final VoidCallback? onTap;

  const NotificationItem({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = item.isRead ?? false;
    
    Color borderColor;
    Color iconBgColor;
    Color iconColor;
    IconData icon;

    // TYPE MATCHING
    if (item.type == 'maintenance') {
      borderColor = AppColors.warning;
      iconBgColor = AppColors.warning.withOpacity(0.15);
      iconColor = AppColors.warning;
      icon = Icons.build;
    } else if (item.type == 'document') {
      borderColor = AppColors.brandSage500;
      iconBgColor = AppColors.brandSage100;
      iconColor = AppColors.brandSage600;
      icon = Icons.description;
    } else {
      borderColor = AppColors.info;
      iconBgColor = AppColors.info.withOpacity(0.15);
      iconColor = AppColors.info;
      icon = Icons.info_outline;
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
              children: [
                // ICON BOX
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),

                const SizedBox(width: 14),

                // TEXTS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
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
                        item.description,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
