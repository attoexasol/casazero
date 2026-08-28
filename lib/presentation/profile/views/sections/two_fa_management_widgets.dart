// presentation/profile/views/two_fa_management_widgets.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../controllers/two_fa_management_controller.dart';
import '../../../../core/logging/diagnostic_logger.dart';

class TwoFAManagementWidgets {

  // ============================================================================
  // ACTIVATION VERIFICATION
  // ============================================================================

  static void showActivationVerification(TwoFAManagementController controller) {
    final method = controller.selectedMethod.value!;
    final isAuthenticator = method.type.name == 'authenticator';

    Get.bottomSheet(
      Builder(
        builder: (sheetContext) {
          final viewInsets = MediaQuery.viewInsetsOf(sheetContext);
          final safePadding = MediaQuery.paddingOf(sheetContext);
          return Obx(
            () => Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + safePadding.bottom + viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.neutralInk300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            method.name,
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
                      method.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neutralInk500,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Show QR Code for Authenticator or Instructions for Email/SMS
                    if (isAuthenticator)
                      _buildAuthenticatorSetup(
                        controller,
                        controller.otpauthUrl.value,
                      )
                    else
                      _buildEmailSMSInstructions(controller),

                    const SizedBox(height: 24),

                    // Verification Code Input
                    CustomTextField(
                      controller: controller.verificationCodeController,
                      label: 'verification_code'.tr,
                      hint: 'Enter 6-digit code',
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      //inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),

                    const SizedBox(height: 24),

                    // Verify Button
                    CustomButton(
                      text: 'verify_and_activate'.tr,
                      onPressed: controller.isProcessing.value
                          ? null
                          : controller.verifyAndActivate,
                      isLoading: controller.isProcessing.value,
                    ),

                    const SizedBox(height: 16),

                    // Cancel Button
                    CustomButton(
                      text: 'cancel'.tr,
                      onPressed: () {
                        controller.cancelActivation();
                        Get.back();
                      },
                      // variant: ButtonVariant.outlined,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      isDismissible: false,
    );
  }

  static Widget _buildAuthenticatorSetup(TwoFAManagementController controller, String otpauthUrl) {
    if (controller.isLoading.value) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (controller.qrCodeData.value.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neutralInk300),
          ),
          child: Column(
            children: [
              Text(
                'Scan QR Code',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildQRCode(controller.qrCodeData.value, controller.totpSecret.value, otpauthUrl),
              const SizedBox(height: 16),
              Text(
                'Or enter this code manually:',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutralInk500,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                controller.totpSecret.value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brandSage50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.brandSage300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to set up:',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandSage600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Open your authenticator app\n'
                    '2. Scan the QR code above\n'
                    '3. Enter the 6-digit code below',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutralInk700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildQRCode(String qrData, String secret, String otpauthUrl) {
    try {
      // Use the otpauth URL directly if available
      if (otpauthUrl.isNotEmpty && otpauthUrl.startsWith('otpauth://')) {
        DiagnosticLogger.instance.debug('Using otpauth URL for QR display');
        return QrImageView(
          data: otpauthUrl,
          version: QrVersions.auto,
          size: 200,
          backgroundColor: Colors.white,
        );
      }

      // Fallback: Check if it's base64 SVG
      if (qrData.startsWith('data:image/svg+xml;base64,')) {
        final base64Data = qrData.split(',')[1];
        final decodedBytes = base64Decode(base64Data);
        final svgString = utf8.decode(decodedBytes);

        // Extract URI from SVG
        final uri = _extractURIFromSVG(svgString, secret);

        return QrImageView(
          data: uri,
          version: QrVersions.auto,
          size: 200,
          backgroundColor: Colors.white,
        );
      } else {
        // Regular text data
        return QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: 200,
          backgroundColor: Colors.white,
        );
      }
    } catch (e) {
      DiagnosticLogger.instance.error('Error displaying QR code: $e');
      return Container(
        width: 200,
        height: 200,
        color: AppColors.neutralLine100,
        child: const Center(child: Icon(Icons.error)),
      );
    }
  }

  static String _extractURIFromSVG(String svgString, String fallbackSecret) {
    // Try to extract otpauth:// URI from SVG data
    final regex = RegExp(r'otpauth://[^"<\s]+');
    final match = regex.firstMatch(svgString);
    if (match != null) {
      return match.group(0)!;
    }

    // Fallback: Create otpauth URL from secret
    // Format: otpauth://totp/CasaZero:account?secret=SECRET&issuer=CasaZero
    if (fallbackSecret.isNotEmpty) {
      DiagnosticLogger.instance.warning('⚠️ Creating fallback otpauth URL from secret');
      return 'otpauth://totp/CasaZero:User?secret=$fallbackSecret&issuer=CasaZero';
    }

    return fallbackSecret;
  }

  static Widget _buildEmailSMSInstructions(TwoFAManagementController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandSage50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandSage300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.brandSage600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Verification Code Sent',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandSage600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A verification code has been sent to ${controller.getMaskedContact()}. '
                'Please enter the code below to activate 2FA.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutralInk700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // DEACTIVATION VERIFICATION
  // ============================================================================

  static void showDeactivationVerification(TwoFAManagementController controller) {
    final isAuthenticator = controller.current2FAMethod.value == 'authenticator';

    Get.bottomSheet(
      Builder(
        builder: (sheetContext) {
          final viewInsets = MediaQuery.viewInsetsOf(sheetContext);
          final safePadding = MediaQuery.paddingOf(sheetContext);
          return Obx(
            () => Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + safePadding.bottom + viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.neutralInk300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'verify_your_identity'.tr,
                            style: AppTextStyles.h4,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            controller.cancelDeactivation();
                            Get.back();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the verification code to deactivate 2FA',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neutralInk500,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Current Method Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isAuthenticator
                                  ? 'Enter the code from your authenticator app'
                                  : 'A verification code has been sent to ${controller.getMaskedContact()}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.neutralInk700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // OTP Input
                    CustomTextField(
                      controller: controller.otpController,
                      label: 'verification_code'.tr,
                      hint: 'Enter 6-digit code',
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      //inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),

                    // Resend OTP (for email/SMS)
                    if (!isAuthenticator) ...[
                      const SizedBox(height: 16),
                      controller.countdown.value > 0
                          ? Text(
                              'Resend code in ${controller.countdown.value}s',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.neutralInk500,
                              ),
                            )
                          : TextButton(
                              onPressed: controller.isResending.value
                                  ? null
                                  : controller.resendDeactivationOTP,
                              child: Text('resend_code'.tr),
                            ),
                    ],

                    const SizedBox(height: 24),

                    // Verify and Deactivate Button
                    CustomButton(
                      text: 'verify_and_deactivate'.tr,
                      onPressed: controller.isProcessing.value
                          ? null
                          : controller.verifyAndDeactivate,
                      isLoading: controller.isProcessing.value,
                      backgroundColor: AppColors.danger,
                    ),

                    const SizedBox(height: 16),

                    // Cancel Button
                    CustomButton(
                      text: 'cancel'.tr,
                      onPressed: () {
                        controller.cancelDeactivation();
                        Get.back();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      isDismissible: false,
    );
  }
}