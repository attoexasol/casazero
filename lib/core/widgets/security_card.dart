// core/widgets/security_card.dart

import 'package:flutter/material.dart';
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.shadowPremium,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Text(
            "security".tr,
            style: AppTextStyles.CardHeaderText.copyWith(
              color: AppColors.neutralInk900,
            ),
          ),
          const SizedBox(height: 16),

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
  // 2FA MANAGEMENT DIALOG (When Active)
  // -----------------------------------------------------------------------------
  void _show2FAManagementDialog(
    BuildContext context,
    TwoFAManagementController controller,
  ) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text('two_factor_auth'.tr, style: AppTextStyles.h4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: AppColors.success,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
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
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Current Method: ${controller.current2FAMethodDisplay}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.neutralInk700,
                            ),
                          ),
                          Text(
                            controller.getMaskedContact(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutralInk500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Change Method Button
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
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('change_2fa_method'.tr),
              ),

              const SizedBox(height: 12),

              // Deactivate Button
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
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('deactivate_2fa'.tr),
              ),
            ],
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
        insetPadding: EdgeInsets.all(5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.cancelActivation();
                      Get.back();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to receive verification codes',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutralInk500,
                ),
              ),
              const SizedBox(height: 24),

              // Method Options
              ...controller.twoFactorMethods.map((method) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMethodTile(method, controller),
                );
              }),
            ],
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutralInk300, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandSage100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getMethodIcon(method.type.toString()),
                color: AppColors.brandSage600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutralInk500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.neutralInk400),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'deactivate_2fa'.tr,
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.neutralInk900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Warning Message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                    ),
                    const SizedBox(height: 8),
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

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: AppColors.neutralInk300),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.neutralInk700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back(); // Close warning dialog

                        // Start deactivation process
                        await controller.startDeactivation();

                        // Navigate to verification screen
                        Get.toNamed(AppRoutes.TWO_FA_DEACTIVATION_VERIFICATION);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'continue'.tr,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsequenceItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                AppColors.neutralInk500,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                style: AppTextStyles.cardText.copyWith(
                  color: AppColors.neutralInk900,
                ),
              ),
            ),

            if (suffix != null) suffix,

            const Icon(
              Icons.chevron_right,
              size: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withOpacity(.12)
            : AppColors.neutralInk300.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
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
