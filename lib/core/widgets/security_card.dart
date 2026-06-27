// core/widgets/security_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_shadows.dart';
import '../../data/models/user_model.dart';
import '../../data/models/two_factor_method_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/repositories/profile_repository.dart';
import '../../presentation/profile/controllers/two_fa_management_controller.dart';
import '../../presentation/profile/controllers/profile_controller.dart';
import '../../presentation/profile/views/sections/two_fa_management_widgets.dart';

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
            style: AppTextStyles.CardHeaderText.copyWith(
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
  // RESPONSIVE DIALOG HELPERS
  // -----------------------------------------------------------------------------
  BoxConstraints _dialogConstraints(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final screenSize = MediaQuery.sizeOf(context);
    final maxWidth = screenSize.width >= 600
        ? 480.0
        : (screenSize.width - 32.w).clamp(280.w, 480.w);
    final maxHeight = (screenSize.height * 0.85 - viewInsets.bottom)
        .clamp(280.h, screenSize.height * 0.85);
    return BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight);
  }

  EdgeInsets _dialogInsetPadding(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h + bottom);
  }

  // -----------------------------------------------------------------------------
  // 2FA MANAGEMENT DIALOG (When Active)
  // -----------------------------------------------------------------------------
  void _show2FAManagementDialog(
    BuildContext context,
    TwoFAManagementController controller,
  ) {
    Get.dialog(
      Dialog(
        insetPadding: _dialogInsetPadding(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: ConstrainedBox(
          constraints: _dialogConstraints(context),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text('two_factor_auth'.tr, style: AppTextStyles.h4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24.sp),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: AppColors.success,
                      size: 32.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2FA is Active',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Current Method: ${controller.current2FAMethodDisplay}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.neutralInk700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            controller.getMaskedContact(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutralInk500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              OutlinedButton(
                onPressed: () {
                  Get.back(); // Close management dialog
                  if (!Get.isRegistered<ProfileRepository>()) {
                    Get.put(ProfileRepository());
                  }

                  if (!Get.isRegistered<TwoFAManagementController>()) {
                    Get.put(TwoFAManagementController());
                  }
                  controller.startActivation();
                  _showActivationDialog(context, controller);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text('change_2fa_method'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: 12.h),

              ElevatedButton(
                onPressed: () {
                  Get.back(); // Close management dialog
                  if (!Get.isRegistered<ProfileRepository>()) {
                    Get.put(ProfileRepository());
                  }

                  if (!Get.isRegistered<TwoFAManagementController>()) {
                    Get.put(TwoFAManagementController());
                  }
                  _showDeactivationWarningDialog(context, controller);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text('deactivate_2fa'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // ACTIVATION DIALOG (Method Selection)
  // -----------------------------------------------------------------------------

  void _showActivationDialog(
    BuildContext context,
    TwoFAManagementController controller,
  ) {
    controller.startActivation();

    Get.dialog(
      Dialog(
        insetPadding: _dialogInsetPadding(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: ConstrainedBox(
          constraints: _dialogConstraints(context),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'select_2fa_method'.tr,
                      style: AppTextStyles.h4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24.sp),
                    onPressed: () {
                      controller.cancelActivation();
                      Get.back();
                    },
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Choose how you want to receive verification codes',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutralInk500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 24.h),

              ...controller.twoFactorMethods.map((method) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _buildMethodTile(method, controller),
                );
              }),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildMethodTile(method, TwoFAManagementController controller) {
    return InkWell(
      onTap: () {
        Get.back(); // Close method selection dialog
        controller.selectMethod(method);
        // Show verification bottom sheet
        TwoFAManagementWidgets.showActivationVerification(controller);
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.neutralInk300, width: 1.w),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.brandSage100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                _getMethodIcon(method.type.toString()),
                color: AppColors.brandSage600,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    method.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutralInk500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.neutralInk400, size: 20.sp),
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon(String type) {
    print(type);
    switch (type) {
      case 'TwoFactorMethodType.email':
        return Icons.email_outlined;
      case 'TwoFactorMethodType.sms':
        return Icons.sms_outlined;
      case 'TwoFactorMethodType.authenticator':
        return Icons.phone_android;
      default:
        return Icons.security;
    }
  }

  // -----------------------------------------------------------------------------
  // DEACTIVATION WARNING DIALOG (When 2FA is Active)
  // -----------------------------------------------------------------------------
  void _showDeactivationWarningDialog(
    BuildContext context,
    TwoFAManagementController controller,
  ) {
    Get.dialog(
      Dialog(
        insetPadding: _dialogInsetPadding(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: ConstrainedBox(
          constraints: _dialogConstraints(context),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Warning Icon and Title
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 32.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'deactivate_2fa'.tr,
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.neutralInk900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consequences of Disabling 2FA:',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralInk900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    _buildConsequenceItem('Your account will be less secure'),
                    _buildConsequenceItem(
                      'Only password will be required to login',
                    ),
                    _buildConsequenceItem(
                      'You will be more vulnerable to unauthorized access',
                    ),
                    _buildConsequenceItem(
                      'Verification will be required to proceed',
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        side: BorderSide(color: AppColors.neutralInk300),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.neutralInk700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();

                        await controller.startDeactivation();

                        Get.toNamed(AppRoutes.TWO_FA_DEACTIVATION_VERIFICATION);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        minimumSize: Size(double.infinity, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'continue'.tr,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildConsequenceItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutralInk700,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
            ? AppColors.success.withOpacity(.12)
            : AppColors.neutralInk300.withOpacity(.15),
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
