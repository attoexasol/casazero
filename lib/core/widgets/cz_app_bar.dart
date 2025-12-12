import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_colors.dart';
import 'building_selector_capsule.dart';
import 'cz_notification_bell.dart';

class CZAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton; // Updated parameter name for clarity
  final bool showNotification;
  final bool showBuildingSelector;
  final bool centerLogo;
  final bool transparent;

  final int notificationCount;

  final VoidCallback? onBackPressed; // Updated parameter name for clarity
  final VoidCallback? onBuildingTap;
  final VoidCallback? onNotificationTap;

  final List<Widget>? actions;

  const CZAppBar({
    super.key,
    this.title,
    this.showBackButton = false, // Updated
    this.showNotification = true,
    this.showBuildingSelector = true,
    this.centerLogo = false,
    this.transparent = false,
    this.notificationCount = 2,
    this.onBackPressed, // Updated
    this.onBuildingTap,
    this.onNotificationTap,
    this.actions,
  });

  @override
  Size get preferredSize => Size.fromHeight(70.h);

  @override
  Widget build(BuildContext context) {
    final double statusBar = MediaQuery.of(context).padding.top;
    final double topPadding = (statusBar * 0.00).h;

    return Container(
      height: 70.h + topPadding,
      padding: EdgeInsets.only(left: 14.w, right: 14.w, top: topPadding),
      decoration: BoxDecoration(
        color: transparent ? Colors.transparent : AppColors.surfaceWhite,
        boxShadow: transparent
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
      ),
      child: Row(
        children: centerLogo
            ? _buildCenteredLogoLayout()
            : _buildDefaultLayout(),
      ),
    );
  }

  List<Widget> _buildDefaultLayout() {
    return [
      /// BACK BUTTON
      if (showBackButton)
        GestureDetector(
          onTap: onBackPressed ?? () => debugPrint("Back pressed"),
          child: Container(
            padding: EdgeInsets.all(8.w),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 20.sp,
              color: AppColors.neutralInk700,
            ),
          ),
        ).animate().fadeIn().scaleXY(begin: 0.8),

      if (showBackButton) SizedBox(width: 8.w),

      /// CASA ZERO LOGO
      Image.asset("assets/images/logo_green.png", height: 25.h)
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: -0.1, duration: 400.ms),

      SizedBox(width: 10.w),

      /// TITLE or BUILDING SELECTOR
      Expanded(
        child: AnimatedSwitcher(
          duration: 250.ms,
          child: showBuildingSelector
              ? BuildingSelectorCapsule(
                  key: const ValueKey("selector"),
                  label: title ?? "",
                  onTap: onBuildingTap,
                )
              : Text(
                  title ?? "",
                  key: const ValueKey("title"),
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralInk900,
                    letterSpacing: -0.3,
                  ),
                ),
        ),
      ),

      SizedBox(width: 6.w),

      /// CUSTOM USER ACTION buttons
      if (actions != null) ...actions!,

      /// NOTIFICATION BELL
      if (showNotification)
        CZNotificationBell(
          count: notificationCount,
          onTap: onNotificationTap,
        ).animate().fadeIn().scaleXY(begin: 0.8),
    ];
  }

  List<Widget> _buildCenteredLogoLayout() {
    return [
      /// If back button is needed
      if (showBackButton)
        GestureDetector(
          onTap: onBackPressed ?? () => debugPrint("Back pressed"),
          child: Container(
            padding: EdgeInsets.all(8.w),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 20.sp,
              color: AppColors.neutralInk700,
            ),
          ),
        ).animate().fadeIn().scaleXY(begin: 0.8),

      if (showBackButton) SizedBox(width: 12.w),

      /// CENTER LOGO
      Expanded(
        child: Center(
          child: Image.asset("assets/images/logo_green.png", height: 28.h)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.1, duration: 400.ms),
        ),
      ),

      SizedBox(width: 12.w),

      /// RIGHT SIDE: custom actions + notification bell
      _buildRightSide(),
    ];
  }

  Widget _buildRightSide() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (actions != null) ...actions!,
        if (showNotification)
          CZNotificationBell(
            count: notificationCount,
            onTap: onNotificationTap,
          ).animate().fadeIn().scaleXY(begin: 0.8),
      ],
    );
  }
}
