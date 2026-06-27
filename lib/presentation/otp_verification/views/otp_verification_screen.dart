// presentation/otp_verification/views/otp_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../controllers/otp_verification_controller.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../app/theme/app_colors.dart';

class OtpVerificationScreen extends GetView<OtpVerificationController> {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/login_bg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 48.h,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 430.w),
                    child: Column(
                      children: [
                        _buildLogo(),
                        SizedBox(height: 48.h),
                        _buildOtpCard(),
                        SizedBox(height: 24.h),
                        _buildCancelButton(),
                        SizedBox(height: 24.h),
                        _buildCopyright(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 240.w,
          height: 80.h,
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/white_logo.png',
            width: 180.w,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'smart_living'.tr,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14.sp,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40.r),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 16.h),
              _buildAlert(),
              SizedBox(height: 24.h),
              _buildMethodInfo(),
              SizedBox(height: 24.h),
              _buildOtpInput(),
              SizedBox(height: 16.h),
              _buildResendSection(),
              SizedBox(height: 24.h),
              _buildVerifyButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: const LinearGradient(
              colors: [AppColors.brandSage500, AppColors.brandSage600],
            ),
          ),
          child: Icon(_getMethodIconData(), color: Colors.white, size: 24.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'verify_identity'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Obx(
                () => Text(
                  controller.methodDisplayName,
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlert() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white, size: 18.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Obx(
              () => Text(
                controller.instructionText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodInfo() {
    return Obx(() {
      final method = controller.twoFaMethod.value;

      if (method == 'authenticator') {
        return Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.phone_android,
                  color: Colors.white,
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'open_authenticator_app'.tr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13.sp,
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
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                method == 'email' ? Icons.email_outlined : Icons.sms_outlined,
                color: Colors.white,
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
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    controller.maskedContact.value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildOtpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'enter_6_digit_code'.tr,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller.otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 8.w,
              color: AppColors.neutralInk900,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(
                fontSize: 32.sp,
                letterSpacing: 8.w,
                color: Colors.grey[400],
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 20.h,
              ),
              counterText: '',
            ),
            onSubmitted: (_) => controller.verifyOTP(),
          ),
        ),
      ],
    );
  }

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
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13.sp,
                ),
              )
            else
              TextButton(
                onPressed: controller.resendOTP,
                child: Text(
                  'resend_code'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildVerifyButton() {
    return Obx(
      () => CustomButton(
        text: 'verify_continue'.tr,
        onPressed: controller.verifyOTP,
        isLoading: controller.isLoading.value,
        backgroundColor: AppColors.brandSage800,
      ),
    );
  }

  Widget _buildCancelButton() {
    return Obx(
      () => TextButton(
        onPressed: controller.cancelVerification,
        child: Text(
          controller.fromDocumentPassword.value
              ? 'cancel'.tr
              : 'cancel_logout'.tr,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14.sp),
        ),
      ),
    );
  }

  Widget _buildCopyright() {
    return Text(
      'copyright'.tr,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.6)),
    );
  }

  IconData _getMethodIconData() {
    switch (controller.twoFaMethod.value) {
      case 'email':
        return Icons.email_outlined;
      case 'sms':
        return Icons.sms_outlined;
      case 'authenticator':
        return Icons.phone_android;
      default:
        return Icons.security;
    }
  }
}
