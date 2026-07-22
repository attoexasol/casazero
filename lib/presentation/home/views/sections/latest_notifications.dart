import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/feed_item_model.dart';
import '../../controllers/home_controller.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/services/notification_manager.dart';

/// Latest Notifications Widget - Converted from React latestnotification.tsx
/// Displays notification cards with premium styling matching React design
class LatestNotifications extends StatelessWidget {
  const LatestNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 448.w),
        child: Padding(
          padding: EdgeInsets.only(left: 24.w, right: 24.w, top: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'latest_notifications'.tr,
                      style: AppTextStyles.h4.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.01 * 18,
                        color: AppColors.neutralInk800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                        width: 8.w,
                        height: 8.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentLime500,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentLime500.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 2000.ms,
                    curve: Curves.easeInOut,
                  )
                  .then(delay: 3000.ms)
                  .scale(
                    begin: const Offset(1.1, 1.1),
                    end: const Offset(1, 1),
                    duration: 2000.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),

          SizedBox(height: 16.h),
          Obx(() {
            final feedItems = controller.feedItems;

            // Empty state
            if (feedItems.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32.r),
                  child: Text(
                    'no_notifications'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutralInk500,
                    ),
                  ),
                ),
              );
            }

            // Notification list with spacing (space-y-2.5 = 10px)
            return Column(
              children: feedItems.asMap().entries.map((entry) {
                final index = entry.key;
                final notification = entry.value as FeedItemModel;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < feedItems.length - 1 ? 10.h : 0,
                  ),
                  child:
                      _LatestNotificationCard(
                            notification: notification,
                            onTap: () {
                              controller.markNotificationAsRead(
                                notification.id,
                              );
                              if (Get.isRegistered<NotificationManager>()) {
                                Get.find<NotificationManager>()
                                    .handleNotificationNavigation(
                                  notification.toNavigationPayload(),
                                );
                              }
                            },
                          )
                          .animate(
                            delay: (600 + index * 100)
                                .ms, // delay: 0.6 + index * 0.1
                          )
                          .fadeIn(duration: 500.ms)
                          .slideX(begin: -20, end: 0, duration: 500.ms),
                );
              }).toList(),
            );
          }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual notification card matching React design
class _LatestNotificationCard extends StatefulWidget {
  final FeedItemModel notification;
  final VoidCallback? onTap;

  const _LatestNotificationCard({required this.notification, this.onTap});

  @override
  State<_LatestNotificationCard> createState() =>
      _LatestNotificationCardState();
}

class _LatestNotificationCardState extends State<_LatestNotificationCard> {
  bool _isHovered = false;

  // Shared border radius for card and sidebar
  static const double _cardRadius = 16.0;
  static final BorderRadius _cardBorderRadius = BorderRadius.circular(
    _cardRadius,
  );

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final isRead = notification.isRead;
    final type = notification.type.toLowerCase();

    // Determine colors based on type
    Color accentColor;
    Color iconColor;
    List<Color> iconGradientColors;
    List<Color> accentGradientColors;

    if (type == 'maintenance') {
      accentColor = AppColors.warning;
      iconColor = notification.priority == 'high'
          ? AppColors.warning
          : AppColors.neutralInk700;
      // Icon box gradient derived from accentColor (single source of truth)
      // Uses higher opacity values to accurately match the sidebar color intensity
      // Sidebar uses: 100% → 100% → 60% opacity, icon box uses proportional values
      iconGradientColors = [
        accentColor.withOpacity(0.8),
        accentColor.withOpacity(0.80),
        accentColor.withOpacity(0.45),
      ];
      accentGradientColors = [
        accentColor,
        accentColor,
        accentColor.withOpacity(0.8),
      ];
    } else if (type == 'document' || type == 'documents') {
      accentColor = AppColors.brandSage500;
      iconColor = AppColors.brandSage600;
      iconGradientColors = [
        AppColors.brandSage100,
        AppColors.brandSage50,
        AppColors.surfaceWhite,
      ];
      accentGradientColors = [
        AppColors.brandSage500,
        AppColors.brandSage500,
        AppColors.brandSage400,
      ];
    } else {
      accentColor = AppColors.info;
      iconColor = AppColors.info;
      iconGradientColors = [
        AppColors.info.withOpacity(0.2),
        AppColors.info.withOpacity(0.15),
        AppColors.info.withOpacity(0.05),
      ];
      accentGradientColors = [
        AppColors.info,
        AppColors.info,
        AppColors.info.withOpacity(0.6),
      ];
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          child: ClipRRect(
            borderRadius: _cardBorderRadius,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: _cardBorderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surfaceWhite, AppColors.surfaceWarm50],
                ),
                border: Border.all(
                  color: _isHovered
                      ? AppColors.neutralLine200
                      : AppColors.neutralLine200.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: _buildShadows(accentColor, _isHovered),
              ),
              child: Stack(
                children: [
                  // Left accent border (4px wide gradient) with matching border radius
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4, // w-1 = 4px
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: _cardBorderRadius.topLeft,
                        bottomLeft: _cardBorderRadius.bottomLeft,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: accentGradientColors,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Subtle glow effect on hover
                  if (_isHovered)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              accentColor.withOpacity(0.05),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: _cardBorderRadius,
                        ),
                      ),
                    ),

                  // Content
                  Padding(
                    padding: EdgeInsets.all(14.r),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon container (w-11 h-11 = 44px, rounded-xl = 12px)
                        _buildIconContainer(
                          type,
                          iconColor,
                          iconGradientColors,
                        ),

                        const SizedBox(width: 14), // gap-3.5 = 14px
                        // Content
                        Expanded(
                          child: Obx(() {
                            final localeController =
                                Get.find<LocaleController>();
                            final _ =
                                localeController.locale; // Trigger reactivity

                            final displayTitle = notification.localizedDisplayTitle;
                            final displayContent = notification.localizedDisplayContent;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  displayTitle,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.neutralInk800,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                SizedBox(height: 4.h),
                                // Description
                                Text(
                                  displayContent,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.neutralInk500,
                                    height: 1.5,
                                  ),
                                ),

                                const SizedBox(height: 6), // mb-1.5 = 6px
                                // Timestamp
                                Row(
                                  children: [
                                    Container(
                                      width: 4, // w-1 = 4px
                                      height: 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.neutralInk300,
                                      ),
                                    ),
                                    const SizedBox(width: 8), // gap-2 = 8px
                                    Text(
                                      notification.timeAgo,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.neutralInk400,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(
    String type,
    Color iconColor,
    List<Color> gradientColors,
  ) {
    IconData iconData;

    if (type == 'maintenance') {
      iconData = Icons.build_outlined; // Wrench icon
    } else if (type == 'document' || type == 'documents') {
      iconData = Icons.description_outlined; // FileText icon
    } else {
      iconData = Icons.info_outline; // AlertCircle icon
    }

    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Icon glow (blurred background)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: iconColor.withOpacity(0.3),
              ),
            ),
          ),
          // Icon
          Center(
            child: Icon(
              iconData,
              size: 20.sp,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  List<BoxShadow> _buildShadows(Color accentColor, bool isHovered) {
    if (isHovered) {
      return [
        BoxShadow(
          color: accentColor.withOpacity(0.16),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: accentColor.withOpacity(0.12),
          blurRadius: 32,
          offset: const Offset(0, 12),
          spreadRadius: -8,
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: accentColor.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: accentColor.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: -4,
        ),
      ];
    }
  }
}
