// presentation/profile/views/document_password_2fa_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/responsive_alert_dialog.dart';
import '../../otp_verification/controllers/otp_verification_controller.dart';
import '../../profile/controllers/document_password_controller.dart';

class DocumentPassword2FAVerificationScreen extends GetView<OtpVerificationController> {
  const DocumentPassword2FAVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackButton();
      },
      child: Scaffold(
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
                    _buildMethodInfo(),
                    SizedBox(height: 24.h),
                    _buildOtpInput(),
                    SizedBox(height: 16.h),
                    _buildResendSection(),
                    SizedBox(height: 32.h),
                    _buildVerifyButton(),
                    SizedBox(height: 16.h),
                    _buildCancelButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                onPressed: () => _handleBackButton(),
              ),
              SizedBox(width: 8.w),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'verify_to_save_document_password'.tr,
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.neutralInk900,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'verify_document_password_subtitle'.tr,
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
            child: Obx(
              () => Text(
                controller.instructionText,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutralInk700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // METHOD INFO
  // ============================================================================

  Widget _buildMethodInfo() {
    return Obx(() {
      final method = controller.twoFaMethod.value;

      if (method == 'authenticator') {
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.neutralInk300,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neutralLine200, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.brandSage500,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.phone_android,
                  color: AppColors.surfaceWhite,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'authenticator_app'.tr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neutralInk900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'open_authenticator_app'.tr,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neutralInk500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // Email / SMS UI
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.neutralInk300,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutralLine200, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: AppColors.brandSage500,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                method == 'email' ? Icons.email_outlined : Icons.sms_outlined,
                color: AppColors.surfaceWhite,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method == 'email' ? 'sent_to_email'.tr : 'sent_to_phone'.tr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutralInk500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    controller.maskedContact.value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutralInk900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ============================================================================
  // OTP INPUT
  // ============================================================================

  Widget _buildOtpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'enter_6_digit_code'.tr,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutralInk900,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neutralLine200, width: 1),
          ),
          child: TextField(
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
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(
                fontSize: 32.sp,
                letterSpacing: 8,
                color: AppColors.neutralInk400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 20.h,
              ),
              counterText: '',
            ),
            onSubmitted: (_) => _handleVerify(),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // RESEND SECTION
  // ============================================================================

  Widget _buildResendSection() {
    return Obx(() {
      final method = controller.twoFaMethod.value;
      final seconds = controller.countdown.value;

      if (method == 'authenticator') {
        return const SizedBox.shrink();
      }

      return Center(
        child: Column(
          children: [
            if (seconds > 0)
              Text(
                'resend_code_in'.tr.replaceAll('{seconds}', seconds.toString()),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutralInk500,
                ),
              )
            else
              TextButton(
                onPressed: controller.resendOTP,
                child: Text(
                  'resend_code'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.brandSage600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  // ============================================================================
  // VERIFY BUTTON
  // ============================================================================

  Widget _buildVerifyButton() {
    return Obx(
      () => CustomButton(
        text: 'verify_continue'.tr,
        onPressed: _handleVerify,
        isLoading: controller.isLoading.value,
        backgroundColor: AppColors.brandSage500,
        textColor: AppColors.surfaceWhite,
        height: 48.h,
      ),
    );
  }

  // ============================================================================
  // CANCEL BUTTON
  // ============================================================================

  Widget _buildCancelButton() {
    return Center(
      child: TextButton(
        onPressed: _handleCancel,
        child: Text(
          'cancel'.tr,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutralInk500,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // HANDLERS
  // ============================================================================

  void _handleVerify() {
    final code = controller.otpController.text.trim();

    if (code.isEmpty) {
      return;
    }

    if (code.length != 6) {
      return;
    }

    // Use the existing verifyOTP method which handles document password flow
    controller.verifyOTP();
  }

  void _handleCancel() {
    Get.dialog(
      Builder(
        builder: (_) => ResponsiveAlertDialog(
          scrollable: true,
          clipBehavior: Clip.antiAlias,
          title: Text(
            'cancel_verification'.tr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          content: Text(
            'document_password_2fa_cancel_message'.tr,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'no'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                try {
                  final documentPasswordController =
                      Get.find<DocumentPasswordController>();
                  documentPasswordController.cancel2FAFlow();
                } catch (e) {
                  // Controller might not be found, that's okay
                }
                Get.back(result: false);
              },
              child: Text(
                'yes'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 8.h,
          ),
          contentPadding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
          titlePadding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
        ),
      ),
    );
  }

  // ============================================================================
  // BACK BUTTON HANDLER
  // ============================================================================

  void _handleBackButton() {
    // Cancel document password flow - return false result
    try {
      final documentPasswordController = Get.find<DocumentPasswordController>();
      documentPasswordController.cancel2FAFlow();
    } catch (e) {
      // Controller might not be found, that's okay
    }
    // Return false to indicate cancellation
    Get.back(result: false);
  }
}
