import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_shadows.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../data/models/feed_item_model.dart';
import '../../core/constants/push_types.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/services/notification_manager.dart';

/// Modal Bottom Sheet for displaying all notifications
/// Converted from React NotificationsScreen.tsx
class NotificationsModal {
  /// Show the notifications modal bottom sheet (always fetches fresh notifications when opened)
  static void show(BuildContext context) {
    final controller = Get.find<HomeController>();
    controller.fetchNotifications();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => _NotificationsModalContent(controller: controller),
    );
  }
}

/// Content widget for the notifications modal
/// Matches React NotificationsScreen component design
class _NotificationsModalContent extends StatefulWidget {
  final HomeController controller;

  const _NotificationsModalContent({required this.controller});

  @override
  State<_NotificationsModalContent> createState() =>
      _NotificationsModalContentState();
}

class _NotificationsModalContentState
    extends State<_NotificationsModalContent> {
  /// Reactive so the list Obx rebuilds when the selected tab changes.
  final RxString _filter = 'all'.obs; // all | document | maintenance | chat | ticket

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.paddingOf(context);
    final modalMaxWidth = screenSize.width >= 600 ? 560.0 : screenSize.width;
    final modalHeight = (screenSize.height * 0.80)
        .clamp(320.0, screenSize.height - viewPadding.top - 16);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: modalMaxWidth,
          maxHeight: modalHeight,
        ),
        child: SizedBox(
          width: modalMaxWidth,
          height: modalHeight,
          child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
          boxShadow: AppShadows.shadowLg,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Handle bar
                Padding(
                  padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
                  child: Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppColors.neutralInk300,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                ),

                // Header with filter tabs and mark all as read (FIXED)
                Obx(() {
                  final unreadCount = widget.controller.unreadCount.value;
                  final _ = _filter.value; // rebuild selected tab styling

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withOpacity(0.95),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.neutralLine100,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      left: 24.w,
                      right: 24.w,
                      top: 8.h,
                      bottom: 10.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top row: Mark all as read button (right-aligned)
                        if (unreadCount > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: _markAllAsRead,
                                icon: Icon(
                                  Icons.check_circle_outline,
                                  size: 16.sp,
                                  color: AppColors.brandSage600,
                                ),
                                label: Text(
                                  'markAllRead'.tr.isEmpty
                                      ? 'Mark all read'
                                      : 'notification_mark_all_read'.tr,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.brandSage600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),

                        // Filter tabs
                        if (unreadCount > 0) SizedBox(height: 4.h),
                        SizedBox(
                          height: 36.h,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterTab(
                                  'all',
                                  'all'.tr.isEmpty ? 'All' : 'all'.tr,
                                ),
                                SizedBox(width: 8.w),
                                _buildFilterTab('document', 'documents'.tr),
                                SizedBox(width: 8.w),
                                _buildFilterTab('maintenance', 'maintenance'.tr),
                                SizedBox(width: 8.w),
                                _buildFilterTab('chat', 'chat'.tr),
                                SizedBox(width: 8.w),
                                _buildFilterTab('ticket', 'ticket'.tr),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Notification List (SCROLLABLE)
                Expanded(
                  child: Obx(() {
                    final _ = _filter.value;
                    final notifications = widget.controller.feedItems.toList();
                    final filteredNotifications = _getFilteredNotifications(
                      notifications,
                    );

                    return filteredNotifications.isEmpty
                        ? _buildEmptyState()
                        : _buildNotificationList(filteredNotifications);
                  }),
                ),
              ],
            ),

            // Close button (absolute top-right corner)
            // Positioned(
            //   top: 0.h,
            //   right: 8.w,
            //   child: IconButton(
            //     padding: EdgeInsets.zero,
            //     constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            //     onPressed: () => Navigator.of(context).pop(),
            //     icon: Icon(
            //       Icons.close,
            //       color: AppColors.neutralInk500,
            //       size: 24.sp,
            //     ),
            //     splashRadius: 22,
            //   ),
            // ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label) {
    final isSelected = _filter.value == filter;

    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => _filter.value = filter,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandSage600 : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandSage600
                  : AppColors.neutralLine200,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12.sp,
              height: 1.2,
              color: isSelected
                  ? AppColors.surfaceWhite
                  : AppColors.neutralInk700,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  List<FeedItemModel> _getFilteredNotifications(
    List<FeedItemModel> notifications,
  ) {
    final filter = _filter.value;
    if (filter == 'all') return notifications;

    // Use the same type helpers as FCM / navigation (PushTypes + model getters)
    // so every API/FCM alias lands in the correct tab.
    return notifications.where((notif) {
      switch (filter) {
        case 'document':
          return PushTypes.isDocument(notif.type);
        case 'maintenance':
          return notif.isMaintenanceType;
        case 'chat':
          return notif.isChatNotification;
        case 'ticket':
          return notif.isTicketType;
        default:
          return true;
      }
    }).toList();
  }

  void _markAllAsRead() {
    final unreadNotifications = widget.controller.feedItems
        .where((n) => !n.isRead)
        .toList();

    for (final notification in unreadNotifications) {
      widget.controller.markNotificationAsRead(notification.id);
    }
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<FeedItemModel> notifications) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: Column(
        children: notifications.asMap().entries.map((entry) {
          final index = entry.key;
          final notification = entry.value;
          return _NotificationCard(
                notification: notification,
                onTap: () => _handleAction(notification),
                onDelete: () => _deleteNotification(notification),
              )
              .animate(delay: (index * 50).ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.15, end: 0, duration: 300.ms);
        }).toList(),
      ),
    );
  }

  void _handleAction(FeedItemModel notification) {
    widget.controller.markNotificationAsRead(notification.id);

    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<NotificationManager>()) return;
      Get.find<NotificationManager>().handleNotificationNavigation(
        notification.toNavigationPayload(),
      );
    });
  }

  Future<void> _deleteNotification(FeedItemModel notification) async {
    await widget.controller.deleteNotification(notification.id);
  }
}

/// Individual notification card — tap opens the relevant section and marks as read.
class _NotificationCard extends StatelessWidget {
  final FeedItemModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = notification.type.toLowerCase();

    IconData iconData;
    Color iconColor;

    if (type == 'document' || type == 'documents') {
      iconData = Icons.description_outlined;
      iconColor = AppColors.brandSage600;
    } else if (notification.isMaintenanceType) {
      iconData = Icons.build_outlined;
      iconColor = AppColors.warning;
    } else if (type == 'chat' ||
        type == 'message' ||
        type == 'messages' ||
        notification.isChatNotification) {
      iconData = Icons.chat_bubble_outline;
      iconColor = AppColors.info;
    } else if (type == 'ticket' || type == 'tickets') {
      iconData = Icons.support_agent_outlined;
      iconColor = AppColors.success;
    } else {
      iconData = Icons.description_outlined;
      iconColor = AppColors.neutralInk500;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.surfaceWhite,
          width: 1,
        ),
      ),
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10.r),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 10.h, 0, 10.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(iconData, size: 17.sp, color: iconColor),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(child: _NotificationCardBody(notification: notification)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 6.h, right: 4.w),
              child: _NotificationIconButton(
                onPressed: onDelete,
                icon: SvgPicture.asset(
                  'assets/images/delete.svg',
                  width: 16.sp,
                  height: 16.sp,
                  fit: BoxFit.contain,
                ),
                tooltip: 'delete'.tr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCardBody extends StatelessWidget {
  const _NotificationCardBody({required this.notification});

  final FeedItemModel notification;

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;

    return Obx(() {
      final localeController = Get.find<LocaleController>();
      final _ = localeController.locale;

      final displayTitle = notification.localizedCenterTitle;
      final displayContent = notification.localizedCenterSubtitle;
      final showContent = displayContent.isNotEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  displayTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13.sp,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralInk800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isRead) ...[
                SizedBox(width: 6.w),
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandSage600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (showContent) ...[
            SizedBox(height: 4.h),
            Text(
              displayContent,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12.sp,
                height: 1.3,
                color: AppColors.neutralInk500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 6.h),
          Text(
            notification.timeAgo,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11.sp,
              color: AppColors.neutralInk400,
            ),
          ),
        ],
      );
    });
  }
}

class _NotificationIconButton extends StatelessWidget {
  const _NotificationIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28.w,
      height: 28.w,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: 28.w,
          minHeight: 28.w,
        ),
        tooltip: tooltip,
        splashRadius: 16.r,
      ),
    );
  }
}
