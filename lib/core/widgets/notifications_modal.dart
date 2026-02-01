import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_shadows.dart';
import '../../core/controllers/message_popup_controller.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../data/models/feed_item_model.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/services/download_service.dart';
import '../../presentation/main/main_scaffold.dart';

/// Modal Bottom Sheet for displaying all notifications
/// Converted from React NotificationsScreen.tsx
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
  String _filter = 'all'; // 'all', 'document', 'maintenance', 'chat', 'ticket'
  final DownloadService _downloadService = Get.find<DownloadService>();

  @override
  Widget build(BuildContext context) {
    // Fixed height: 75% of screen height
    final fixedHeight = MediaQuery.of(context).size.height * 0.80;

    return SizedBox(
      height: fixedHeight,
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
                      top: 12.h,
                      bottom: 16.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                      : 'markAllRead'.tr,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.brandSage600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        
                        // Bottom row: Filter tabs
                        if (unreadCount > 0) SizedBox(height: 8.h),
                        SingleChildScrollView(
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
                              _buildFilterTab(
                                'maintenance',
                                'maintenance'.tr,
                              ),
                              SizedBox(width: 8.w),
                              _buildFilterTab('chat', 'chat'.tr),
                              SizedBox(width: 8.w),
                              _buildFilterTab(
                                'ticket',
                                'supportTickets'.tr.isEmpty
                                    ? 'Tickets'
                                    : 'supportTickets'.tr,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Notification List (SCROLLABLE)
                Expanded(
                  child: Obx(() {
                    final notifications = widget.controller.feedItems;
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
    );
  }

  Widget _buildFilterTab(String filter, String label) {
    final isSelected = _filter == filter;

    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandSage600 : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20.r), // rounded-full
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
            color: isSelected
                ? AppColors.surfaceWhite
                : AppColors.neutralInk700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<FeedItemModel> _getFilteredNotifications(
    List<FeedItemModel> notifications,
  ) {
    if (_filter == 'all') return notifications;

    return notifications.where((notif) {
      final type = notif.type.toLowerCase();
      switch (_filter) {
        case 'document':
          return type == 'document' || type == 'documents';
        case 'maintenance':
          return type == 'maintenance';
        case 'chat':
          return type == 'chat' || type == 'message' || type == 'messages';
        case 'ticket':
          return type == 'ticket' || type == 'tickets';
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
            SizedBox(height: 8.h),
            Text(
              'no_notifications_desc'.tr.isEmpty
                  ? 'You\'re all caught up!'
                  : 'no_notifications_desc'.tr,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.neutralInk400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<FeedItemModel> notifications) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        children: notifications.asMap().entries.map((entry) {
          final index = entry.key;
          final notification = entry.value;
          return _NotificationCard(
                notification: notification,
                onMarkAsRead: () =>
                    widget.controller.markNotificationAsRead(notification.id),
                onAction: () => _handleAction(notification),
                onDelete: () => _deleteNotification(notification),
              )
              .animate(delay: (index * 50).ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.2, end: 0, duration: 300.ms);
        }).toList(),
      ),
    );
  }

  void _handleAction(FeedItemModel notification) {
    // Mark as read first
    widget.controller.markNotificationAsRead(notification.id);

    // Navigate to appropriate screen based on type
    final type = notification.type.toLowerCase();

    // Close modal first
    Navigator.of(context).pop();

    // Handle document notifications - download and open with native chooser
    if (type == 'document' || type == 'documents') {
      _handleDocumentNotification(notification);
    } else if (type == 'maintenance') {
      widget.controller.navigateToScreen(AppScreen.maintenance);
    } else if (type == 'chat' || type == 'message' || type == 'messages') {
      // Chat screen not implemented yet, use existing handler
      widget.controller.onNotificationChat(notification);
    } else if (type == 'ticket' || type == 'tickets') {
      // Tickets screen not implemented yet, use existing handler
      widget.controller.onNotificationAssistance(notification);
    }
  }

  /// Handle document notification - download and open with native "Open with" chooser
  /// Same functionality as document card view button
  Future<void> _handleDocumentNotification(FeedItemModel notification) async {
    try {
      // Check if notification has a URL
      if (notification.url == null || notification.url!.isEmpty) {
        widget.controller.navigateToScreen(AppScreen.documents);
        MessagePopupController.showError(
          messageKey: 'documentUrlNotAvailable',
          titleKey: 'downloadFailed',
        );
        return;
      }

      // Generate filename from notification
      final fileName = _generateFileName(notification);
      final fileId = notification.id;

      print('📥 [Notification] Starting download: $fileName');
      print('📥 [Notification] URL: ${notification.url}');

      MessagePopupController.showDownloading(
        messageKey: 'downloading'.tr + ': ' + notification.localizedDisplayTitle,
        titleKey: 'downloading',
      );

      final result = await _downloadService.downloadDocument(
        fileUrl: notification.url!,
        fileName: fileName,
        fileId: fileId,
      );

      if (result['success'] == true) {
        final filePath = result['filePath'] as String;
        MessagePopupController.closePopup();
        print('✅ [Notification] Download successful: $filePath');
        await Future.delayed(const Duration(milliseconds: 500));
        await _showOpenFileBottomSheet(filePath, notification.displayTitle);
      } else {
        MessagePopupController.closePopup();
        MessagePopupController.showError(
          messageKey: 'downloadError',
          titleKey: 'downloadFailed',
        );
        print('❌ [Notification] Download failed: ${result['error']}');
      }
    } catch (e) {
      print('❌ [Notification] Error downloading document: $e');
      MessagePopupController.closePopup();
      MessagePopupController.showError(
        messageKey: 'downloadError',
        titleKey: 'downloadFailed',
      );
    }
  }

  /// Generate filename from notification URL or title
  String _generateFileName(FeedItemModel notification) {
    if (notification.url != null && notification.url!.isNotEmpty) {
      final urlParts = notification.url!.split('/');
      if (urlParts.isNotEmpty) {
        final lastPart = urlParts.last;
        if (lastPart.contains('.')) {
          return lastPart;
        }
      }
    }

    // Fallback: generate from title
    final cleanTitle = notification.displayTitle
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    
    // Try to extract extension from URL
    String extension = 'pdf'; // Default extension
    if (notification.url != null && notification.url!.isNotEmpty) {
      final url = notification.url!;
      final lastDot = url.lastIndexOf('.');
      if (lastDot != -1 && lastDot < url.length - 1) {
        final ext = url.substring(lastDot + 1).toLowerCase();
        if (ext.length <= 5) { // Reasonable extension length
          extension = ext;
        }
      }
    }

    return '$cleanTitle.$extension';
  }

  /// Show native "Open with" chooser with available apps to open the file
  /// Uses open_filex which shows native Android chooser or iOS share sheet
  Future<void> _showOpenFileBottomSheet(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        MessagePopupController.showError(
          messageKey: 'fileNotFound',
          titleKey: 'openFileFailed',
        );
        return;
      }

      // Use open_filex to show native "Open with" chooser
      // This will show all available apps that can open the file type
      print('📂 [Notification] Opening native "Open with" chooser for file: $fileName');
      final result = await OpenFilex.open(filePath);

      print('📂 [Notification] Open file result: ${result.type} - ${result.message}');

      // Handle the result
      if (result.type == ResultType.noAppToOpen) {
        MessagePopupController.showWarning(
          messageKey: 'noAppToOpen',
          titleKey: 'openFileFailed',
        );
      } else if (result.type == ResultType.error || result.type == ResultType.fileNotFound) {
        MessagePopupController.showError(
          messageKey: 'openFileError',
          titleKey: 'openFileFailed',
        );
      }
    } catch (e) {
      print('❌ [Notification] Error showing file chooser: $e');
      MessagePopupController.showError(
        messageKey: 'openFileError',
        titleKey: 'openFileFailed',
      );
    }
  }

  void _deleteNotification(FeedItemModel notification) {
    MessagePopupController.showInfo(
      messageKey: 'delete_functionality_coming_soon',
      titleKey: 'notifications',
    );
  }
}

/// Individual notification card matching React design
class _NotificationCard extends StatelessWidget {
  final FeedItemModel notification;
  final VoidCallback onMarkAsRead;
  final VoidCallback onAction;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onMarkAsRead,
    required this.onAction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    final type = notification.type.toLowerCase();

    // Get icon and colors based on type
    IconData iconData;
    Color iconColor;

    if (type == 'document' || type == 'documents') {
      iconData = Icons.description_outlined;
      iconColor = AppColors.brandSage600;
    } else if (type == 'maintenance') {
      iconData = Icons.build_outlined;
      iconColor = AppColors.warning;
    } else if (type == 'chat' || type == 'message' || type == 'messages') {
      iconData = Icons.chat_bubble_outline;
      iconColor = AppColors.info;
    } else if (type == 'ticket' || type == 'tickets') {
      iconData = Icons.support_agent_outlined;
      iconColor = AppColors.success;
    } else {
      iconData = Icons.description_outlined;
      iconColor = AppColors.neutralInk500;
    }

    // Get action label based on type (localized)
    String? actionLabel;
    if (type == 'maintenance') {
      actionLabel = 'viewTask'.tr;
    } else if (type == 'document' || type == 'documents') {
      actionLabel = 'viewDocument'.tr;
    } else if (type == 'chat' || type == 'message' || type == 'messages') {
      actionLabel = 'openChat'.tr;
    } else if (type == 'ticket' || type == 'tickets') {
      actionLabel = 'viewTicket'.tr;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isRead
            ? AppColors.surfaceWhite
            : AppColors.brandSage50.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isRead ? AppColors.neutralLine200 : AppColors.brandSage300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(iconData, size: 20.sp, color: iconColor),
            ),

            SizedBox(width: 12.w),

            // Content
            Expanded(
              child: Obx(() {
                final localeController = Get.find<LocaleController>();
                final _ = localeController.locale; // Trigger reactivity

                final displayTitle = notification.localizedDisplayTitle;
                final displayContent = notification.localizedDisplayContent;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutralInk800,
                            ),
                          ),
                        ),
                        if (!isRead) ...[
                          SizedBox(width: 8.w),
                          Container(
                            width: 8.w,
                            height: 8.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.brandSage600,
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: 4.h),

                    // Description
                    Text(
                      displayContent,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.neutralInk500,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    // Timestamp
                    Text(
                      notification.timeAgo,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.neutralInk400,
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Action buttons - Fixed size and aligned
                    Row(
                      children: [
                        // Left side: Primary and secondary actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // View button (Primary action)
                            if (actionLabel != null)
                              Builder(
                                builder: (context) {
                                  final label = actionLabel!;
                                  return SizedBox(
                                    height: 32.h,
                                    child: OutlinedButton(
                                      onPressed: onAction,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.brandSage600,
                                        side: BorderSide(
                                          color: AppColors.brandSage300,
                                          width: 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 0,
                                        ),
                                        minimumSize: Size(80.w, 32.h),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        label,
                                        style: AppTextStyles.caption.copyWith(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.brandSage600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // Mark as Read button (Secondary action)
                            if (!isRead) ...[
                              if (actionLabel != null) SizedBox(width: 8.w),
                              SizedBox(
                                height: 32.h,
                                child: TextButton(
                                  onPressed: onMarkAsRead,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 0,
                                    ),
                                    minimumSize: Size(80.w, 32.h),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'markAsRead'.tr.isEmpty
                                        ? 'Mark as read'
                                        : 'markAsRead'.tr,
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 12.sp,
                                      color: AppColors.neutralInk700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Spacer to push Delete button to far right
                        const Spacer(),

                        // Delete button (Destructive action) - Fixed at far right
                        SizedBox(
                          width: 32.w,
                          height: 32.h,
                          child: IconButton(
                            onPressed: onDelete,
                            icon: SvgPicture.asset(
                              'assets/images/delete.svg',
                              width: 18.sp,
                              height: 18.sp,
                              fit: BoxFit.contain,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 32.w,
                              minHeight: 32.h,
                            ),
                            tooltip: 'Delete',
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
    );
  }
}
