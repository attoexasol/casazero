// presentation/profile/views/two_fa_deactivation_verification_screen.dart
// REDESIGNED TO MATCH REACT VERSION WITH 3-STEP FLOW: WARNING -> VERIFY -> SUCCESS

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/tablet_centered_layout.dart';
import '../controllers/two_fa_management_controller.dart';

enum DeactivationStep { warning, verify, success }

class TwoFADeactivationVerificationScreen extends GetView<TwoFAManagementController> {
  const TwoFADeactivationVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize current step
    final currentStep = DeactivationStep.warning.obs;

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: Column(
        children: [
          _buildHeader(currentStep),
          Expanded(
            child: TabletCenteredLayout(
              child: Obx(() {
              switch (currentStep.value) {
                case DeactivationStep.warning:
                  return _buildWarningStep(currentStep);
                case DeactivationStep.verify:
                  return _buildVerifyStep(currentStep);
                case DeactivationStep.success:
                  return _buildSuccessStep();
              }
            }),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================

  Widget _buildHeader(Rx<DeactivationStep> currentStep) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutralLine200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, size: 24.sp),
                color: AppColors.neutralInk900,
                onPressed: () {
                  controller.cancelDeactivation();
                  Get.back();
                },
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'deactivate_2fa'.tr,
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.neutralInk900,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'verify_identity_to_deactivate'.tr,
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
  // STEP 1: WARNING
  // ============================================================================

  Widget _buildWarningStep(Rx<DeactivationStep> currentStep) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Column(
        children: [
          // Alert Banner
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3),
                width: 2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.danger.withValues(alpha: 0.05),
                  AppColors.surfaceWhite,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'security_warning'.tr,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'deactivation_warning'.tr,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutralInk700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

          SizedBox(height: 24.h),

          // Security Risks Card
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.neutralLine200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.danger,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'security_risks'.tr,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralInk900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'deactivating_will_result'.tr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutralInk500,
                  ),
                ),
                SizedBox(height: 16.h),
                ..._buildSecurityRisks(),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: -0.1, end: 0),

          SizedBox(height: 24.h),

          // Better Alternatives Card
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.brandSage300),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandSage50,
                  AppColors.surfaceWhite,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield,
                      color: AppColors.brandSage600,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'better_alternatives'.tr,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralInk900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildAlternativeItem('alternative_switch_method'.tr),
                SizedBox(height: 8.h),
                _buildAlternativeItem('alternative_update_backup'.tr),
                SizedBox(height: 8.h),
                _buildAlternativeItem('alternative_contact_support'.tr),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: -0.1, end: 0),

          SizedBox(height: 32.h),

          // Action Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    controller.cancelDeactivation();
                    Get.back();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    side: BorderSide(color: AppColors.neutralInk300),
                  ),
                  child: Text(
                    'cancel'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutralInk700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  return OutlinedButton(
                    onPressed: controller.isProcessing.value
                        ? null
                        : () async {
                      controller.isProcessing.value = true;

                      // SEND OTP directly (only if email/sms)
                      if (controller.current2FAMethod.value == 'email' ||
                          controller.current2FAMethod.value == 'sms') {
                        await controller.sendDeactivationOTP();
                      }

                      controller.isProcessing.value = false;

                      // Move to VERIFY step
                      currentStep.value = DeactivationStep.verify;
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      side: BorderSide(color: AppColors.danger),
                      foregroundColor: AppColors.danger,
                    ),
                    child: controller.isProcessing.value
                        ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.danger),
                      ),
                    )
                        : Text(
                      'continue_deactivation'.tr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              )

            ],
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
        ],
      ),
    );
  }

  List<Widget> _buildSecurityRisks() {
    final risks = [
      {
        'title': 'increase_vulnerability'.tr,
        'description': 'increase_vulnerability_desc'.tr,
      },
      {
        'title': 'unauthorized_access'.tr,
        'description': 'unauthorized_access_desc'.tr,
      },
      {
        'title': 'data_breach_risk'.tr,
        'description': 'data_breach_risk_desc'.tr,
      },
      {
        'title': 'identity_theft'.tr,
        'description': 'identity_theft_desc'.tr,
      },
    ];

    return risks.asMap().entries.map((entry) {
      final index = entry.key;
      final risk = entry.value;
      final isLast = index == risks.length - 1;

      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                margin: EdgeInsets.only(top: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      risk['title']!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neutralInk900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      risk['description']!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutralInk500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            SizedBox(height: 12.h),
            Divider(color: AppColors.neutralLine200, height: 1),
            SizedBox(height: 12.h),
          ],
        ],
      ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms);
    }).toList();
  }

  Widget _buildAlternativeItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.brandSage600,
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
    );
  }

  // ============================================================================
  // STEP 2: VERIFY
  // ============================================================================

  Widget _buildVerifyStep(Rx<DeactivationStep> currentStep) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Column(
        children: [
          // Security Notice
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.brandSage300),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandSage50,
                  AppColors.surfaceWhite,
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.brandSage100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield,
                    color: AppColors.brandSage600,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'verify_identity_to_deactivate'.tr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutralInk700,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

          SizedBox(height: 24.h),

          // OTP Input Card
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.neutralLine200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'enter_verification_code'.tr,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralInk900,
                  ),
                ),
                SizedBox(height: 8.h),
                Obx(() {
                  final isAuthenticator = controller.current2FAMethod.value == 'authenticator';
                  return Text(
                    isAuthenticator
                        ? 'otp_authenticator_instruction'.tr
                        : 'enter_current_two_factor_code'.tr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutralInk500,
                    ),
                  );
                }),
                SizedBox(height: 16.h),
                TextField(
                  controller: controller.otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: AppColors.neutralInk900,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: TextStyle(
                      fontSize: 32.sp,
                      letterSpacing: 8,
                      color: AppColors.neutralInk300,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    counterText: '',
                  ),
                  onChanged: (value) {
                    // Auto-submit when 6 digits entered
                    if (value.length == 6) {
                      FocusScope.of(Get.context!).unfocus();
                    }
                  },
                ),
                SizedBox(height: 8.h),
                Obx(() {
                  final isAuthenticator = controller.current2FAMethod.value == 'authenticator';
                  return Text(
                    isAuthenticator
                        ? 'open_authenticator_app'.tr
                        : controller.getMaskedContact(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutralInk500,
                    ),
                    textAlign: TextAlign.center,
                  );
                }),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: -0.1, end: 0),

          SizedBox(height: 24.h),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    currentStep.value = DeactivationStep.warning;
                    controller.otpController.clear();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    side: BorderSide(color: AppColors.neutralInk300),
                  ),
                  child: Text(
                    'back'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutralInk700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller.otpController,
                  builder: (context, value, child) {
                    return Obx(() => ElevatedButton(
                      onPressed: value.text.length != 6 || controller.isProcessing.value
                          ? null
                          : () => _handleVerify(currentStep),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        backgroundColor: AppColors.danger,
                        disabledBackgroundColor: AppColors.neutralInk300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: controller.isProcessing.value
                          ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
                        'deactivate'.tr,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ));
                  },
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        ],
      ),
    );
  }

  void _handleVerify(Rx<DeactivationStep> currentStep) async {
    // Call the controller's verify method
    final success = await controller.verifyAndDeactivate();

    // If successful, move to success step
    if (success) {
      currentStep.value = DeactivationStep.success;

      // Auto-redirect after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        Get.back();
      });
    }
  }

  // ============================================================================
  // STEP 3: SUCCESS
  // ============================================================================

  Widget _buildSuccessStep() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 40.sp,
                  ),
                ),
              ),
            )
                .animate()
                .scale(begin: Offset(0, 0), end: Offset(1, 1), duration: 400.ms, curve: Curves.elasticOut),

            SizedBox(height: 24.h),

            Text(
              'two_factor_deactivated'.tr,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.neutralInk900,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2, end: 0),

            SizedBox(height: 12.h),

            Text(
              'two_factor_deactivated_message'.tr,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutralInk500,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2, end: 0),

            SizedBox(height: 24.h),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.brandSage50,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield,
                    color: AppColors.brandSage600,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'reactivate_anytime'.tr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.brandSage600,
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}