import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_shadows.dart';
import '../../presentation/home/views/sections/notification_item.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../data/models/feed_item_model.dart';

/// Modal Bottom Sheet for displaying all notifications
class NotificationsModal {
  /// Show the notifications modal bottom sheet
  static void show(BuildContext context) {
    final controller = Get.find<HomeController>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => _NotificationsModalContent(
        controller: controller,
      ),
    );
  }
}

/// Content widget for the notifications modal
class _NotificationsModalContent extends StatelessWidget {
  final HomeController controller;

  const _NotificationsModalContent({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: AppShadows.shadowLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.neutralInk300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // Header
          Obx(() {
            final unreadCount = controller.feedItems
                .where((item) => !item.isRead)
                .length;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Notifications',
                        style: AppTextStyles.h4.copyWith(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.surfaceWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 24.sp,
                      color: AppColors.neutralInk700,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.neutralLine200,
          ),

          // Notification List
          Obx(() {
            final notifications = controller.feedItems;
            return Flexible(
              child: notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationList(notifications),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(48.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64.sp,
              color: AppColors.neutralInk300,
            ),
            SizedBox(height: 16.h),
            Text(
              'no_notifications'.tr,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutralInk500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<FeedItemModel> notifications) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      shrinkWrap: true,
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return NotificationItem(
          item: notifications[index],
          onTap: () => controller.markNotificationAsRead(notifications[index].id),
        );
      },
    );
  }
}

