// presentation/profile/views/two_fa_management_screen.dart
// REDESIGNED WITH REACT-INSPIRED UI - ALL FUNCTIONALITY PRESERVED

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/two_fa_management_controller.dart';

class TwoFAManagementScreen extends GetView<TwoFAManagementController> {
  const TwoFAManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      // Header with back button and title
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Obx(() {
              // Show setup flow
              if (controller.isInSetupMode.value) {
                if (controller.selectedMethod.value != null) {
                  return _buildSetupStep();
                } else {
                  return _buildMethodSelection();
                }
              }

              // Show deactivation flow
              if (controller.isInDeactivationMode.value) {
                return _buildDeactivationFlow();
              }

              // This shouldn't be reached as we open directly to method selection
              return _buildMethodSelection();
            }),
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
              // Back button
              IconButton(
                icon: Icon(Icons.chevron_left, size: 24.sp),
                color: AppColors.neutralInk900,
                onPressed: () {
                  if (controller.isInSetupMode.value) {
                    if (controller.selectedMethod.value != null) {
                      // Go back to method selection
                      controller.selectedMethod.value = null;
                      controller.verificationCodeController.clear();
                    } else {
                      // Cancel and close
                      controller.cancelActivation();
                      Get.back();
                    }
                  } else if (controller.isInDeactivationMode.value) {
                    controller.cancelDeactivation();
                    Get.back();
                  } else {
                    Get.back();
                  }
                },
              ),

              SizedBox(width: 8.w),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Text(
                      'two_factor_auth'.tr,
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.neutralInk900,
                        fontWeight: FontWeight.w600,
                      ),
                    )),
                    SizedBox(height: 2.h),
                    Text(
                      'enhance_account_security'.tr,
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
      ),
    );
  }

  // ============================================================================
  // PROGRESS INDICATOR (Step Tracker)
  // ============================================================================

  Widget _buildProgressIndicator() {
    final steps = ['select', 'setup', 'verify', 'success'];
    int currentStepIndex = 0;

    // Determine current step based on state
    if (controller.selectedMethod.value == null) {
      currentStepIndex = 0; // Select method
    } else if (controller.verificationCodeController.text.isEmpty) {
      currentStepIndex = 1; // Setup (viewing QR or instructions)
    } else {
      currentStepIndex = 2; // Verify
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < currentStepIndex;
          final isCurrent = index == currentStepIndex;
          final isLast = index == 3;

          return Expanded(
            child: Row(
              children: [
                // Step circle
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? AppColors.brandSage600
                              : AppColors.neutralLine200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20.sp,
                          )
                              : Text(
                            '${index + 1}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isCurrent
                                  ? Colors.white
                                  : AppColors.neutralInk400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ).animate(target: isCurrent ? 1 : 0).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 300.ms,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _getStepLabel(index),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.neutralInk500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2.h,
                      margin: EdgeInsets.only(top: 20.h),
                      color: isCompleted
                          ? AppColors.brandSage500
                          : AppColors.neutralLine200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getStepLabel(int index) {
    switch (index) {
      case 0:
        return 'Select';
      case 1:
        return 'Setup';
      case 2:
        return 'Verify';
      case 3:
        return 'Success';
      default:
        return '';
    }
  }

  // ============================================================================
  // METHOD SELECTION (Step 1)
  // ============================================================================

  Widget _buildMethodSelection() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProgressIndicator(),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Info Card
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.brandSage50,
                        AppColors.surfaceWhite,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.brandSage300.withOpacity(0.3),
                    ),
                    boxShadow: AppShadows.shadowPremium,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: AppColors.brandSage100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          color: AppColors.brandSage600,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'two_factor_info'.tr,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neutralInk700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),

                SizedBox(height: 24.h),

                // Method Options
                ...controller.twoFactorMethods.asMap().entries.map((entry) {
                  final index = entry.key;
                  final method = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildMethodCard(method),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (100 + index * 50).ms)
                      .slideX(begin: 0.2, delay: (100 + index * 50).ms);
                }),

                SizedBox(height: 80.h), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(method) {
    final isRecommended = method.type.name == 'authenticator';

    return InkWell(
      onTap: () => controller.selectMethod(method),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.neutralLine200,
            width: 1,
          ),
          boxShadow: AppShadows.shadowPremium,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: AppColors.brandSage100,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                _getMethodIcon(method.type.name),
                color: AppColors.brandSage600,
                size: 24.sp,
              ),
            ),

            SizedBox(width: 16.w),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          method.name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutralInk900,
                          ),
                        ),
                      ),
                      if (isRecommended)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandSage600,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'Recommended',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    method.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutralInk500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.w),

            // Chevron
            Icon(
              Icons.chevron_right,
              color: AppColors.neutralInk400,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon(String type) {
    switch (type) {
      case 'email':
        return Icons.email_outlined;
      case 'sms':
        return Icons.sms_outlined;
      case 'authenticator':
        return Icons.key;
      default:
        return Icons.security;
    }
  }

  // ============================================================================
  // SETUP STEP (Step 2 - QR Code or Instructions)
  // ============================================================================

  Widget _buildSetupStep() {
    final method = controller.selectedMethod.value!;
    final isAuthenticator = method.type.name == 'authenticator';

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProgressIndicator(),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Method Title Card
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm50,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.neutralLine200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: AppColors.brandSage100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          _getMethodIcon(method.type.name),
                          color: AppColors.brandSage600,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
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
                            Text(
                              method.description,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.neutralInk500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                SizedBox(height: 24.h),

                // Show QR Code for Authenticator or Instructions for SMS/Email
                if (isAuthenticator)
                  _buildAuthenticatorSetup()
                else
                  _buildEmailSMSInstructions(),

                SizedBox(height: 24.h),

                // Verification Code Input
                CustomTextField(
                  controller: controller.verificationCodeController,
                  label: 'verification_code'.tr,
                  hint: 'Enter 6-digit code',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),

                SizedBox(height: 24.h),

                // Verify Button
                Obx(() => CustomButton(
                  text: controller.isProcessing.value
                      ? 'verifying'.tr
                      : 'verify'.tr,
                  onPressed: controller.isProcessing.value
                      ? null
                      : controller.verifyAndActivate,
                  isLoading: controller.isProcessing.value,
                )),

                SizedBox(height: 80.h), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatorSetup() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(48.w),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandSage600),
            ),
          ),
        );
      }

      if (controller.qrCodeData.value.isEmpty) {
        return const SizedBox();
      }

      return Column(
        children: [
          // QR Code Card
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.neutralLine200),
              boxShadow: AppShadows.shadowPremium,
            ),
            child: Column(
              children: [
                Text(
                  'scan_qr_code_title'.tr,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16.h),

                // QR Code
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.neutralLine200),
                  ),
                  child: _buildQRCode(
                    controller.qrCodeData.value,
                    controller.totpSecret.value,
                    controller.otpauthUrl.value,
                  ),
                ),

                SizedBox(height: 16.h),

                // Manual entry section
                Text(
                  'or_enter_manually'.tr,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutralInk500,
                  ),
                ),
                SizedBox(height: 8.h),

                // Secret key with copy button
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.neutralLine200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          controller.totpSecret.value,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, size: 18.sp),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: controller.totpSecret.value),
                          );
                          Get.snackbar(
                            'Copied',
                            'Secret key copied to clipboard',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.brandSage600,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms),

          SizedBox(height: 16.h),

          // Instructions
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm50,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionStep('1', 'setup_step_1'.tr),
                SizedBox(height: 8.h),
                _buildInstructionStep('2', 'setup_step_2'.tr),
                SizedBox(height: 8.h),
                _buildInstructionStep('3', 'setup_step_3'.tr),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24.w,
          height: 24.w,
          decoration: BoxDecoration(
            color: AppColors.brandSage600,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
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

  Widget _buildQRCode(String qrData, String secret, String otpauthUrl) {
    try {
      if (otpauthUrl.isNotEmpty && otpauthUrl.startsWith('otpauth://')) {
        return QrImageView(
          data: otpauthUrl,
          version: QrVersions.auto,
          size: 200.w,
          backgroundColor: Colors.white,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
        );
      }

      if (qrData.isNotEmpty) {
        try {
          final decodedData = base64Decode(qrData);
          final dataUrl = String.fromCharCodes(decodedData);

          if (dataUrl.startsWith('otpauth://')) {
            return QrImageView(
              data: dataUrl,
              version: QrVersions.auto,
              size: 200.w,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            );
          }
        } catch (e) {
          print('Error decoding base64 QR data: $e');
        }
      }

      return Container(
        width: 200.w,
        height: 200.w,
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm50,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            'Unable to generate QR code',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutralInk500,
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error generating QR code: $e');
      return Container(
        width: 200.w,
        height: 200.w,
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm50,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            'QR code error',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.danger,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildEmailSMSInstructions() {
    final method = controller.selectedMethod.value!;
    final isSMS = method.type.name == 'sms';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.neutralLine200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSMS ? Icons.sms : Icons.email,
                color: AppColors.brandSage600,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  isSMS ? 'sms_2fa_instructions'.tr : 'email_2fa_instructions'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'A verification code will be sent when you tap Verify below',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutralInk500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ============================================================================
  // DEACTIVATION FLOW
  // ============================================================================

  Widget _buildDeactivationFlow() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 24.h),

          // Warning Icon
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 40.sp,
            ),
          ),

          SizedBox(height: 24.h),

          Text(
            'deactivate_2fa'.tr,
            style: AppTextStyles.h4,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16.h),

          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
              ),
            ),
            child: Text(
              'deactivation_warning'.tr,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutralInk700,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: 32.h),

          // Verification Code Input
          CustomTextField(
            controller: controller.verificationCodeController,
            label: 'verification_code'.tr,
            hint: 'Enter 6-digit code',
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),

          SizedBox(height: 24.h),

          // Deactivate Button
          Obx(() => CustomButton(
            text: 'verify_and_deactivate'.tr,
            onPressed: controller.isProcessing.value
                ? null
                : controller.verifyAndDeactivate,
            isLoading: controller.isProcessing.value,
          )),

          SizedBox(height: 16.h),

          // Cancel Button
          TextButton(
            onPressed: () {
              controller.cancelDeactivation();
              Get.back();
            },
            child: Text(
              'cancel'.tr,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutralInk500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}