// core/widgets/security_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_shadows.dart';
import '../../data/models/user_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../presentation/profile/controllers/two_fa_management_controller.dart';
import '../../presentation/profile/controllers/profile_controller.dart';

class SecurityCard extends StatelessWidget {
  final UserModel user;
  final Function(String screen)? onNavigate;

  const SecurityCard({super.key, required this.user, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    // Get ProfileController if it exists to reactively rebuild when user changes
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppShadows.shadowProfileCard,
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "security".tr,
            style: AppTextStyles.cardHeaderText.copyWith(
              color: AppColors.neutralInk900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16.h),

          // Change Password
          _item(
            icon: Icons.lock_outline,
            title: "change_password".tr,
            iconPath: 'assets/images/chanage_pass_icon.svg',
            onTap: () {
              // Navigate to change password screen using GetX routing
              Get.toNamed(AppRoutes.CHANGE_PASSWORD);
            },
          ),

          // 2FA Status - Make this reactive
          profileController != null
              ? Obx(() {
                  // Use the reactive user from ProfileController if available
                  final currentUser = profileController.user.value ?? user;
                  return _item(
                    icon: Icons.verified_user_outlined,
                    title: "two_factor_auth".tr,
                    iconPath: 'assets/images/auth_settings.svg',
                    suffix: _twoFAStatus(currentUser),
                    onTap: () => _handle2FATap(context, currentUser),
                  );
                })
              : _item(
                  icon: Icons.verified_user_outlined,
                  title: "two_factor_auth".tr,
                  iconPath: 'assets/images/auth_settings.svg',
                  suffix: _twoFAStatus(user),
                  onTap: () => _handle2FATap(context, user),
                ),

          // Trusted Devices
          _item(
            icon: Icons.security,
            title: "trusted_devices".tr,
            iconPath: 'assets/images/trusted.svg',
            onTap: () => Get.toNamed(AppRoutes.TRUSTED_DEVICES),
          ),

          // Document Password
          _item(
            icon: Icons.message,
            title: "document_password".tr,
            iconPath: 'assets/images/chanage_pass_icon.svg',
            onTap: () => Get.toNamed(AppRoutes.DOCUMENT_PASSWORD),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // 2FA TAP HANDLER
  // -----------------------------------------------------------------------------
  void _handle2FATap(BuildContext context, UserModel currentUser) {
    // Initialize controller if not already in memory
    if (!Get.isRegistered<TwoFAManagementController>()) {
      Get.put(TwoFAManagementController());
    }

    final controller = Get.find<TwoFAManagementController>();

    if (currentUser.is2FAEnabled) {
      // 2FA is active - navigate directly to deactivation verification screen
      //controller.startDeactivation();
      Get.toNamed(AppRoutes.TWO_FA_DEACTIVATION_VERIFICATION);
    } else {
      // 2FA is inactive - navigate to activation screen
      controller.startActivation();
      Get.toNamed(AppRoutes.TWO_FA_ACTIVATION);
    }
  }

  // -----------------------------------------------------------------------------
  // ITEM BUILDER
  // -----------------------------------------------------------------------------
  Widget _item({
    required IconData icon,
    required String title,
    required String iconPath,
    Widget? suffix,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 20.w,
              height: 20.w,
              colorFilter: const ColorFilter.mode(
                AppColors.neutralInk500,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 12.w),

            Expanded(
              child: Text(
                title,
                style: AppTextStyles.cardText.copyWith(
                  color: AppColors.neutralInk900,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (suffix != null) suffix,

            Icon(
              Icons.chevron_right,
              size: 20.sp,
              color: AppColors.neutralInk400,
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // TWO FACTOR AUTH BADGE
  // -----------------------------------------------------------------------------
  Widget _twoFAStatus(UserModel currentUser) {
    final bool active = currentUser.is2FAEnabled;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: .12)
            : AppColors.neutralInk300.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        active ? "active".tr : "inactive".tr,
        style: AppTextStyles.caption.copyWith(
          color: active ? AppColors.success : AppColors.neutralInk500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
