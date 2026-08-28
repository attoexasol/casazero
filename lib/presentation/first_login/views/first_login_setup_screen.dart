// presentation/first_login/views/first_login_setup_screen.dart (ENHANCED WITH 2FA)
import 'package:casazero/core/widgets/casazero_logo.dart';
import 'package:casazero/presentation/first_login/views/sections/first_login_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/controllers/message_popup_controller.dart';
import 'dart:ui';
import 'dart:convert';
import '../controllers/first_login_controller.dart';
import '../../../data/models/two_factor_method_model.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../app/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:casazero/core/logging/diagnostic_logger.dart';

class FirstLoginSetupScreen extends GetView<FirstLoginController> {
  const FirstLoginSetupScreen({super.key});

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
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.3),
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
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 430.w),
                    child: Column(
                      children: [
                        CasaZeroLogo(
                          assetPath: 'assets/images/white_logo.png',
                          maxLogoWidthFactor: 0.4,
                        ),
                        SizedBox(height: 32.h),
                        FirstLoginProgressBar(controller: controller),
                        SizedBox(height: 24.h),
                        Obx(() => controller.currentStep.value == 1
                            ? _buildPasswordChangeCard()
                            : _build2FACard()),
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

  Widget _buildPasswordChangeCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40.r,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                    child: Icon(Icons.lock, color: Colors.white, size: 24.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'change_password'.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'create_strong_password'.tr,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildAlert(
                icon: Icons.info_outline,
                text: 'first_login_password_change'.tr,
              ),
              SizedBox(height: 16.h),
              Obx(
                    () => CustomTextField(
                  label: 'current_password'.tr,
                  hint: 'current_password'.tr,
                  controller: controller.currentPasswordController,
                  obscureText: !controller.showCurrentPassword.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.showCurrentPassword.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => controller.togglePasswordVisibility('current'),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Obx(
                    () => CustomTextField(
                  label: 'new_password'.tr,
                  hint: 'new_password'.tr,
                  controller: controller.newPasswordController,
                  obscureText: !controller.showNewPassword.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.showNewPassword.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => controller.togglePasswordVisibility('new'),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Obx(
                    () => CustomTextField(
                  label: 'confirm_password'.tr,
                  hint: 'confirm_password'.tr,
                  controller: controller.confirmPasswordController,
                  obscureText: !controller.showConfirmPassword.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.showConfirmPassword.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => controller.togglePasswordVisibility('confirm'),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Obx(() => controller.hasPasswordInput.value
                  ? _buildPasswordRequirements()
                  : const SizedBox.shrink()),
              Obx(() {
                if (!controller.hasPasswordInput.value) {
                  return const SizedBox.shrink();
                }
                final allMet = controller.passwordRequirements.every((req) => req.isMet);
                if (!allMet) return const SizedBox.shrink();
                return Column(
                  children: [
                    SizedBox(height: 12.h),
                    _buildValidPasswordIndicator(),
                  ],
                );
              }),
              SizedBox(height: 24.h),
              Obx(
                    () => CustomButton(
                  text: 'continue'.tr,
                  onPressed: controller.isPasswordFormValid.value
                      ? controller.changePassword
                      : null,
                  isLoading: controller.isLoading.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build2FACard() {
    return Obx(() {
      if (controller.isConfiguringMethod.value) {
        return _buildMethodConfigurationCard();
      }
      return _buildMethodSelectionCard();
    });
  }

  Widget _buildMethodSelectionCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40.r,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                    child: Icon(Icons.security, color: Colors.white, size: 24.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'two_factor_auth'.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'choose_security_method'.tr,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildAlert(
                icon: Icons.shield_outlined,
                text: '2fa_security_notice'.tr,
              ),
              SizedBox(height: 16.h),
              Obx(() => Column(
                children: controller.twoFactorMethods
                    .map((method) => _buildMethodCard(method))
                    .toList(),
              )),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.goBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text('back'.tr),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextButton(
                      onPressed: controller.setup2FA,
                      child: Text(
                        'skip_for_now'.tr,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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

  Widget _buildMethodCard(TwoFactorMethod method) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => controller.selectTwoFactorMethod(method),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _getMethodIcon(method.icon),
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
                      method.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      method.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodConfigurationCard() {
    final method = controller.selectedMethod.value;
    if (method == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40.r,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: controller.cancelMethodConfiguration,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'configure_method'.tr,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              if (method.type == TwoFactorMethodType.authenticator)
                _buildAuthenticatorSetup()
              else if (method.type == TwoFactorMethodType.email)
                _buildEmailSetup()
              else if (method.type == TwoFactorMethodType.sms)
                  _buildSMSSetup(),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.cancelMethodConfiguration,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Obx(
                          () => CustomButton(
                        text: 'verify_enable'.tr,
                        onPressed: controller.verify2FAMethod,
                        isLoading: controller.isLoading.value,
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

  Widget _buildAuthenticatorSetup() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAlert(
          icon: Icons.phone_android,
          text: 'scan_qr_instructions'.tr,
        ),
        SizedBox(height: 16.h),
        if (controller.qrCodeData.value.isNotEmpty) ...[
          Center(
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: _buildQRCodeImage(),
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: TextButton.icon(
              onPressed: controller.toggleManualEntry,
              icon: Icon(
                controller.showManualEntry.value
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white70,
                size: 18.sp,
              ),
              label: Text(
                controller.showManualEntry.value
                    ? 'hide_manual_entry'.tr
                    : 'show_manual_entry'.tr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
          if (controller.showManualEntry.value) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'manual_entry_key'.tr}:',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          controller.totpSecret.value,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14.sp,
                            color: Colors.white,
                            letterSpacing: 2.w,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.white, size: 18.sp),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: controller.totpSecret.value),
                          );
                          MessagePopupController.showSuccess(
                            messageKey: 'secret_copied',
                            titleKey: 'success',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 16.h),
        ],
        CustomTextField(
          label: 'verification_code'.tr,
          hint: '000000',
          controller: controller.verificationCodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          // onChanged: (val) {
          //   if (val.length <= 6) {
          //     controller.verificationCodeController.text =
          //         val.replaceAll(RegExp(r'\D'), '');
          //   }
          // },
        ),
      ],
    ));
  }

  Widget _buildEmailSetup() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAlert(
          icon: Icons.email_outlined,
          text: 'email_2fa_instructions'.tr,
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.email, color: Colors.white, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  controller.userEmail,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        if (!controller.isVerificationSent.value)
          CustomButton(
            text: 'send_verification_code'.tr,
            onPressed: controller.sendVerificationCode,
            isLoading: controller.isLoading.value,
          )
        else ...[
          CustomTextField(
            label: 'verification_code'.tr,
            hint: '000000',
            controller: controller.verificationCodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            onChanged: (val) {
              if (val.length <= 6) {
                controller.verificationCodeController.text =
                    val.replaceAll(RegExp(r'\D'), '');
              }
            },
          ),
          SizedBox(height: 8.h),
          if (controller.verificationCountdown.value > 0)
            Center(
              child: Text(
                '${'resend_in'.tr} ${controller.verificationCountdown.value}s',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12.sp,
                ),
              ),
            )
          else
            Center(
              child: TextButton(
                onPressed: controller.sendVerificationCode,
                child: Text(
                  'resend_code'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
        ],
      ],
    ));
  }

  Widget _buildSMSSetup() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAlert(
          icon: Icons.sms_outlined,
          text: 'sms_2fa_instructions'.tr,
        ),
        SizedBox(height: 16.h),
        CustomTextField(
          label: 'phone_number'.tr,
          hint: '+1 (555) 123-4567',
          controller: controller.phoneNumberController,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 16.h),
        if (!controller.isVerificationSent.value)
          CustomButton(
            text: 'send_verification_code'.tr,
            onPressed: controller.sendVerificationCode,
            isLoading: controller.isLoading.value,
          )
        else ...[
          CustomTextField(
            label: 'verification_code'.tr,
            hint: '000000',
            controller: controller.verificationCodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            onChanged: (val) {
              if (val.length <= 6) {
                controller.verificationCodeController.text =
                    val.replaceAll(RegExp(r'\D'), '');
              }
            },
          ),
          SizedBox(height: 8.h),
          if (controller.verificationCountdown.value > 0)
            Center(
              child: Text(
                '${'resend_in'.tr} ${controller.verificationCountdown.value}s',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12.sp,
                ),
              ),
            )
          else
            Center(
              child: TextButton(
                onPressed: controller.sendVerificationCode,
                child: Text(
                  'resend_code'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
        ],
      ],
    ));
  }

  IconData _getMethodIcon(String icon) {
    switch (icon) {
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

  Widget _buildAlert({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Obx(() {
      final allMet = controller.passwordRequirements.every((req) => req.isMet);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: allMet
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: allMet
                ? Colors.green.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'password_requirements'.tr}:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (allMet)
                  Row(
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 16.sp),
                      SizedBox(width: 4.w),
                      Text(
                        'complete'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            ...controller.passwordRequirements.map((req) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Container(
                      width: 20.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: req.isMet ? Colors.green : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                      child: req.isMet
                          ? Icon(Icons.check, color: Colors.white, size: 14.sp)
                          : null,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        req.label,
                        style: TextStyle(
                          color: req.isMet
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.7),
                          fontSize: 13.sp,
                          fontWeight:
                          req.isMet ? FontWeight.w500 : FontWeight.normal,
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

  Widget _buildValidPasswordIndicator() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              'valid_password'.tr,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
  }

  Widget _buildCopyright() {
    return Text(
      'copyright'.tr,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12.sp,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }

  /// Build QR code image from base64 data
  /// The API returns: "data:image/svg+xml;base64,..."
  Widget _buildQRCodeImage() {
    final qrData = controller.qrCodeData.value;

    if (qrData.isEmpty) {
      return SizedBox(
        width: 200.w,
        height: 200.h,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // Detect if SVG
      if (qrData.contains("image/svg+xml")) {
        // Extract base64
        final base64String = qrData.split(',').last;

        return SvgPicture.memory(
          base64Decode(base64String),
          width: 200.w,
          height: 200.h,
          fit: BoxFit.contain,
        );
      }

      // Else assume PNG/JPG
      final base64String = qrData.split(',').last;
      final bytes = base64Decode(base64String);

      return Image.memory(
        bytes,
        width: 200.w,
        height: 200.h,
        fit: BoxFit.contain,
      );
    } catch (e) {
      DiagnosticLogger.instance.debug("QR decode error: $e");
      return Container(
        width: 200.w,
        height: 200.h,
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.error, size: 48.sp, color: Colors.red),
        ),
      );
    }
  }

}