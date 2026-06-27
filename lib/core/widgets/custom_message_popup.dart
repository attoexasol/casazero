import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../localization/locale_controller.dart';

/// Message types for different popup styles
enum MessageType { success, error, warning, info, confirmation }

/// Action button configuration
class PopupAction {
  final String labelKey;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const PopupAction({
    required this.labelKey,
    this.onPressed,
    this.isPrimary = false,
  });
}

/// Centralized custom popup widget that replaces SnackBars
/// Shows only the buttons needed for each scenario
class CustomMessagePopup extends StatelessWidget {
  final String titleKey;
  final String messageKey;
  final MessageType messageType;
  final PopupAction? primaryAction;
  final PopupAction? secondaryAction;

  const CustomMessagePopup({
    super.key,
    required this.titleKey,
    required this.messageKey,
    required this.messageType,
    this.primaryAction,
    this.secondaryAction,
  });

  double _resolveMaxWidth(double screenWidth) {
    if (screenWidth >= 600) return 360.0;
    return (screenWidth * 0.78).clamp(260.w, 360.w);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = _resolveMaxWidth(screenWidth);
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.fromLTRB(
        24.w,
        24.h,
        24.w,
        24.h + viewInsets.bottom,
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Obx(() {
            final _ = Get.find<LocaleController>().locale;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                SizedBox(height: 4.h),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    6.h,
                    16.w,
                    (primaryAction != null || secondaryAction != null) ? 0 : 16.h,
                  ),
                  child: Text(
                    messageKey.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutralInk700,
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 8.h),
                if (primaryAction != null || secondaryAction != null)
                  _buildActions(),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    IconData icon;
    Color iconColor;
    String title;

    switch (messageType) {
      case MessageType.success:
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        title = titleKey.isEmpty ? 'success'.tr : titleKey.tr;
        break;
      case MessageType.error:
        icon = Icons.error;
        iconColor = AppColors.danger;
        title = titleKey.isEmpty ? 'error'.tr : titleKey.tr;
        break;
      case MessageType.warning:
        icon = Icons.warning;
        iconColor = AppColors.warning;
        title = titleKey.isEmpty ? 'warning'.tr : titleKey.tr;
        break;
      case MessageType.info:
        icon = Icons.info;
        iconColor = AppColors.info;
        title = titleKey.isEmpty ? 'info'.tr : titleKey.tr;
        break;
      case MessageType.confirmation:
        icon = Icons.help_outline;
        iconColor = AppColors.neutralInk700;
        title = titleKey.isEmpty ? 'confirmation'.tr : titleKey.tr;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14.r),
          topRight: Radius.circular(14.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22.sp),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.neutralInk900,
                fontSize: 17.sp,
              ),
              textAlign: TextAlign.start,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final actions = <Widget>[];

    if (secondaryAction != null) {
      actions.add(
        Expanded(
          child: TextButton(
            onPressed: () {
              Get.back(result: false);
              secondaryAction?.onPressed?.call();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              secondaryAction!.labelKey.tr,
              style: AppTextStyles.button.copyWith(
                color: AppColors.neutralInk700,
                fontWeight: FontWeight.w800,
                fontSize: 14.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    if (primaryAction != null) {
      actions.add(
        SizedBox(
          height: 40.h,
          width: 90.w,
          child: ElevatedButton(
            onPressed: () {
              Get.back(result: true);
              primaryAction?.onPressed?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getPrimaryButtonColor(),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              primaryAction!.labelKey.tr,
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Row(
        children: actions.length > 1
            ? [const Spacer(), ...actions]
            : [const Spacer(), ...actions, const Spacer()],
      ),
    );
  }

  Color _getPrimaryButtonColor() {
    switch (messageType) {
      case MessageType.success:
        return AppColors.success;
      case MessageType.error:
        return AppColors.danger;
      case MessageType.warning:
        return AppColors.warning;
      case MessageType.info:
        return AppColors.info;
      case MessageType.confirmation:
        return AppColors.brandSage500;
    }
  }
}
