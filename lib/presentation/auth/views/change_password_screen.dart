// presentation/auth/views/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../controllers/change_password_controller.dart';

class ChangePasswordScreen extends GetView<ChangePasswordController> {
  final VoidCallback onBack;
  final Function(String message) onSuccess;

  const ChangePasswordScreen({
    super.key,
    required this.onBack,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDescription(),
                  SizedBox(height: 32.h),
                  _buildPasswordFields(),
                  // Password Requirements
                  Obx(() {
                    if (!controller.hasPasswordInput.value) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        SizedBox(height: 20.h),
                        _buildPasswordRequirements(),
                      ],
                    );
                  }),
                  // Password Match Indicator
                  Obx(() {
                    if (!controller.showPasswordMatch.value) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        SizedBox(height: 12.h),
                        _buildPasswordMatchIndicator(),
                      ],
                    );
                  }),
                  SizedBox(height: 32.h),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.neutralLine200, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: Icon(Icons.chevron_left, size: 24.sp),
                color: AppColors.neutralInk900,
                onPressed: onBack,
              ),
              SizedBox(width: 8.w),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'secure_your_account'.tr,
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.neutralInk900,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'first_login_password_change'.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutralInk500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // DESCRIPTION
  // ============================================================================

  Widget _buildDescription() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.brandSage50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandSage300, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.brandSage600, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'first_login_password_change'.tr,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutralInk700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // PASSWORD FIELDS
  // ============================================================================

  Widget _buildPasswordFields() {
    return Column(
      children: [
        // Current Password Field
        Obx(
          () => CustomTextField(
            label: 'current_password'.tr,
            hint: '••••••••',
            controller: controller.currentPasswordController,
            obscureText: !controller.showCurrentPassword.value,
            backgroundColor: AppColors.surfaceWhite,
            borderColor: AppColors.neutralLine200,
            textColor: AppColors.neutralInk900,
            labelColor: AppColors.neutralInk900,
            suffixIcon: IconButton(
              icon: Icon(
                controller.showCurrentPassword.value
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: AppColors.neutralInk500,
              ),
              onPressed: () => controller.togglePasswordVisibility('current'),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        // New Password Field
        Obx(
          () => CustomTextField(
            label: 'new_password'.tr,
            hint: '••••••••',
            controller: controller.newPasswordController,
            obscureText: !controller.showNewPassword.value,
            backgroundColor: AppColors.surfaceWhite,
            borderColor: AppColors.neutralLine200,
            textColor: AppColors.neutralInk900,
            labelColor: AppColors.neutralInk900,
            suffixIcon: IconButton(
              icon: Icon(
                controller.showNewPassword.value
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: AppColors.neutralInk500,
              ),
              onPressed: () => controller.togglePasswordVisibility('new'),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        // Confirm Password Field
        Obx(
          () => CustomTextField(
            label: 'confirm_password'.tr,
            hint: '••••••••',
            controller: controller.confirmPasswordController,
            obscureText: !controller.showConfirmPassword.value,
            backgroundColor: AppColors.surfaceWhite,
            borderColor: AppColors.neutralLine200,
            textColor: AppColors.neutralInk900,
            labelColor: AppColors.neutralInk900,
            suffixIcon: IconButton(
              icon: Icon(
                controller.showConfirmPassword.value
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: AppColors.neutralInk500,
              ),
              onPressed: () => controller.togglePasswordVisibility('confirm'),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // PASSWORD REQUIREMENTS
  // ============================================================================

  Widget _buildPasswordRequirements() {
    return Obx(() {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.neutralInk300,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutralLine200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'password_requirements'.tr,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutralInk700,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            ...controller.passwordRequirements.map((req) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Container(
                      width: 16.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: req.isMet
                            ? AppColors.success
                            : AppColors.neutralInk300,
                        shape: BoxShape.circle,
                      ),
                      child: req.isMet
                          ? Icon(
                              Icons.check,
                              size: 12.sp,
                              color: AppColors.surfaceWhite,
                            )
                          : null,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        req.label.tr,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: req.isMet
                              ? AppColors.success
                              : AppColors.neutralInk700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  // ============================================================================
  // PASSWORD MATCH INDICATOR
  // ============================================================================

  Widget _buildPasswordMatchIndicator() {
    return Obx(() {
      final _ = controller.showPasswordMatch.value;
      final match = controller.passwordsMatch;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: match
              ? AppColors.success.withOpacity(0.1)
              : AppColors.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: match
                ? AppColors.success.withOpacity(0.3)
                : AppColors.danger.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              match ? Icons.check_circle : Icons.error_outline,
              color: match ? AppColors.success : AppColors.danger,
              size: 16.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              match ? 'passwords_match'.tr : 'passwords_no_match'.tr,
              style: AppTextStyles.bodySmall.copyWith(
                color: match ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ============================================================================
  // SAVE BUTTON
  // ============================================================================

  Widget _buildSaveButton() {
    return GetBuilder<ChangePasswordController>(
      builder: (ctrl) {
        return Obx(
          () => CustomButton(
            text: 'change_password'.tr,
            onPressed: ctrl.canSubmit && !ctrl.isLoading.value
                ? () => ctrl.handleChangePassword(onSuccess: onSuccess)
                : null,
            isLoading: ctrl.isLoading.value,
            backgroundColor: AppColors.brandSage500,
            textColor: AppColors.surfaceWhite,
            height: 48.h,
          ),
        );
      },
    );
  }
}
