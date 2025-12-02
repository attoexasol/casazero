// presentation/profile/views/two_fa_activation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_shadows.dart';
import '../controllers/two_fa_management_controller.dart';
import '../../../data/models/two_factor_method_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TwoFAActivationScreen extends GetView<TwoFAManagementController> {
  const TwoFAActivationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent automatic popping
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Only allow manual back navigation, not automatic from controller
        if (!controller.isProcessing.value) {
          // Cancel activation if user manually goes back
          controller.cancelActivation();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceWhite,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Obx(() {
                    final step = _getCurrentStep();
                    return Column(
                      children: [
                        // Progress Indicator
                        _buildProgressIndicator(step),
                        const SizedBox(height: 32),

                        // Step Content
                        _buildStepContent(step, context),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================
  Widget _buildHeader(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Back Button
          InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: const Icon(
                Icons.chevron_left,
                size: 28,
                color: AppColors.neutralInk700,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'two_factor_auth'.tr,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.neutralInk900,
                  ),
                ),
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
    );
  }

  // ============================================================================
  // PROGRESS INDICATOR
  // ============================================================================
  Widget _buildProgressIndicator(int currentStep) {
    return Row(
      children: [
        for (int i = 0; i < 4; i++) ...[
          // Step Circle
          _buildStepCircle(i, currentStep),

          // Connector Line
          if (i < 3)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: i < currentStep
                      ? AppColors.brandSage500
                      : AppColors.neutralLine200,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStepCircle(int index, int currentStep) {
    final isActive = index == currentStep;
    final isCompleted = index < currentStep;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isCompleted || isActive
            ? AppColors.brandSage600
            : AppColors.neutralLine200,
        shape: BoxShape.circle,
        boxShadow: isActive ? AppShadows.shadowPremium : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(
          Icons.check,
          color: AppColors.surfaceWhite,
          size: 20,
        )
            : Text(
          '${index + 1}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isActive || isCompleted
                ? AppColors.surfaceWhite
                : AppColors.neutralInk400,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // STEP CONTENT
  // ============================================================================
  Widget _buildStepContent(int step, BuildContext context) {
    switch (step) {
      case 0:
        return _buildSelectMethodStep();
      case 1:
        return _buildSetupStep();
      case 2:
        return _buildVerifyStep();
      case 3:
        return _buildSuccessStep();
      default:
        return _buildSelectMethodStep();
    }
  }

  // ============================================================================
  // STEP 1: SELECT METHOD
  // ============================================================================
  Widget _buildSelectMethodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.brandSage50,
                AppColors.surfaceWhite,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.brandSage100,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandSage100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.brandSage600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
        ),
        const SizedBox(height: 24),

        // Methods List
        Obx(() {
          return Column(
            children: controller.twoFactorMethods.map((method) {
              return _buildMethodCard(method);
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildMethodCard(TwoFactorMethod method) {
    final isRecommended = method.type == TwoFactorMethodType.authenticator;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => controller.selectMethod(method),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.neutralLine200,
                width: 1,
              ),
              boxShadow: AppShadows.shadowPremium
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.brandSage100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getMethodIcon(method.type),
                    color: AppColors.brandSage600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _getMethodName(method.type),
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutralInk900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'recommended'.tr,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),
                      Text(
                        _getMethodDescription(method.type),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutralInk500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.neutralInk400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // STEP 2: SETUP
  // ============================================================================
  Widget _buildSetupStep() {
    return Obx(() {
      final method = controller.selectedMethod.value;
      if (method == null) return const SizedBox.shrink();

      if (method.type == TwoFactorMethodType.authenticator) {
        return _buildAuthenticatorSetup();
      } else {
        return _buildSmsEmailSetup(method);
      }
    });
  }

  Widget _buildAuthenticatorSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instructions Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.neutralLine200,
              width: 1,
            ),
            boxShadow: AppShadows.shadowPremium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'authenticator_app'.tr,
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.neutralInk900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'scan_qr_instructions'.tr,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutralInk700,
                ),
              ),
              const SizedBox(height: 16),

              // QR Code
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        color: AppColors.brandSage600,
                      ),
                    ),
                  );
                }

                if (controller.otpauthUrl.value.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.neutralLine200,
                        width: 2,
                      ),
                    ),
                    child: QrImageView(
                      data: controller.otpauthUrl.value,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: AppColors.surfaceWhite,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Manual Entry Key
        Obx(() {
          if (controller.totpSecret.value.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.neutralLine200,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'manual_entry_key'.tr,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutralInk500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.neutralLine200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          controller.totpSecret.value,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontFamily: 'monospace',
                            color: AppColors.neutralInk900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: controller.totpSecret.value),
                          );
                          Get.snackbar(
                            'success'.tr,
                            'copied_to_clipboard'.tr,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.success,
                            colorText: AppColors.surfaceWhite,
                            margin: const EdgeInsets.all(16),
                            borderRadius: 12,
                            duration: const Duration(seconds: 2),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.neutralLine200,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.copy,
                            size: 20,
                            color: AppColors.brandSage600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  controller.cancelActivation();
                  Get.back();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: AppColors.neutralLine200,
                    width: 1,
                  ),
                ),
                child: Text(
                  'back'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Move to verify step - we'll handle step change via controller
                  controller.isInSetupMode.value = false;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandSage600,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'continue'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.surfaceWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmsEmailSetup(TwoFactorMethod method) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Setup Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.neutralLine200,
              width: 1,
            ),
            boxShadow: AppShadows.shadowPremium
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getMethodName(method.type),
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.neutralInk900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                method.type == TwoFactorMethodType.sms
                    ? 'sms_setup_desc'.tr
                    : 'email_setup_desc'.tr,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutralInk700,
                ),
              ),
              const SizedBox(height: 16),

              // Contact Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      method.type == TwoFactorMethodType.sms
                          ? Icons.smartphone
                          : Icons.email_outlined,
                      color: AppColors.brandSage600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.type == TwoFactorMethodType.sms
                                ? controller.currentUser.value?.phone ?? '+39 345 123 4567'
                                : controller.currentUser.value?.email ?? 'user@example.com',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.neutralInk900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'verification_code_sent_to'.tr,
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
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  controller.cancelActivation();
                  Get.back();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: AppColors.neutralLine200,
                    width: 1,
                  ),
                ),
                child: Text(
                  'back'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                  await controller.sendActivationOTP();   // <-- SEND OTP

                  controller.isInSetupMode.value = false; // <-- MOVE TO VERIFY SCREEN
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandSage600,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.surfaceWhite,
                  ),
                )
                    : Text(
                  'send_code'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.surfaceWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // STEP 3: VERIFY
  // ============================================================================
  Widget _buildVerifyStep() {
    // Create a local observable for OTP text length to make the button reactive
    final otpLength = 0.obs;

    return Obx(() {
      final method = controller.selectedMethod.value;
      if (method == null) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Verification Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.neutralLine200,
                width: 1,
              ),
              boxShadow: AppShadows.shadowPremium
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'enter_verification_code'.tr,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.neutralInk900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  method.type == TwoFactorMethodType.authenticator
                      ? 'enter_authenticator_code'.tr
                      : method.type == TwoFactorMethodType.sms
                      ? 'enter_sms_code'.tr
                      : 'enter_email_code'.tr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutralInk500,
                  ),
                ),
                const SizedBox(height: 20),

                // OTP Input
                TextField(
                  controller: controller.verificationCodeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  onChanged: (value) {
                    // Update the observable when text changes to make button reactive
                    otpLength.value = value.length;
                  },
                  style: AppTextStyles.h3.copyWith(
                    letterSpacing: 8,
                    color: AppColors.neutralInk900,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    hintStyle: AppTextStyles.h3.copyWith(
                      letterSpacing: 8,
                      color: AppColors.neutralInk300,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceWarm50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.neutralLine200,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.neutralLine200,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.brandSage600,
                        width: 2,
                      ),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),

                // Resend OTP (for SMS/Email only)
                if (method.type != TwoFactorMethodType.authenticator) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await controller.sendActivationOTP();
                        Get.snackbar(
                          'success'.tr,
                          method.type == TwoFactorMethodType.sms
                              ? 'sms_sent'.tr
                              : 'email_sent'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.success,
                          colorText: AppColors.surfaceWhite,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                        );
                      },
                      child: Text(
                        'resend_code'.tr,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.brandSage600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.verificationCodeController.clear();
                    controller.isInSetupMode.value = true;
                    otpLength.value = 0; // Reset the length tracker
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: AppColors.neutralLine200,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'back'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutralInk700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isProcessing.value ||
                      otpLength.value != 6  // Use the reactive observable instead
                      ? null
                      : () async {
                    await controller.verifyAndActivate();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandSage600,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isProcessing.value
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surfaceWhite,
                    ),
                  )
                      : Text(
                    'verify'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.surfaceWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
              ),
            ],
          ),
        ],
      );
    });
  }

  // ============================================================================
  // STEP 4: SUCCESS
  // ============================================================================
  Widget _buildSuccessStep() {
    // Auto-close after showing success animation
    Future.delayed(const Duration(seconds: 2), () {
      // Force close the screen after success animation
      if (Get.isRegistered<TwoFAManagementController>() &&
          Get.currentRoute == '/two-fa-activation') {
        Navigator.of(Get.context!).pop();
      }
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),

          // Success Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.surfaceWhite,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Success Message
          Text(
            '2fa_enabled'.tr,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.neutralInk900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'two_factor_success_message'.tr,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutralInk500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================
  int _getCurrentStep() {
    final hasSelectedMethod = controller.selectedMethod.value != null;
    final isInSetup = controller.isInSetupMode.value;
    final isProcessing = controller.isProcessing.value;

    // Check if 2FA was just successfully enabled by checking the controller state
    // If we have a selected method, not in setup mode, not processing,
    // and 2FA is now enabled, then we're successful
    final is2FANowEnabled = controller.is2FAEnabled.value &&
        hasSelectedMethod &&
        !isInSetup &&
        !isProcessing;

    if (!hasSelectedMethod) {
      return 0; // Select
    } else if (isInSetup) {
      return 1; // Setup
    } else if (is2FANowEnabled) {
      return 3; // Success - 2FA was successfully activated
    } else {
      return 2; // Verify - waiting for verification
    }
  }

  IconData _getMethodIcon(TwoFactorMethodType type) {
    switch (type) {
      case TwoFactorMethodType.authenticator:
        return Icons.phone_android;
      case TwoFactorMethodType.sms:
        return Icons.sms;
      case TwoFactorMethodType.email:
        return Icons.email;
    }
  }

  String _getMethodName(TwoFactorMethodType type) {
    switch (type) {
      case TwoFactorMethodType.authenticator:
        return 'authenticator_app'.tr;
      case TwoFactorMethodType.sms:
        return 'sms_verification'.tr;
      case TwoFactorMethodType.email:
        return 'email_verification'.tr;
    }
  }

  String _getMethodDescription(TwoFactorMethodType type) {
    switch (type) {
      case TwoFactorMethodType.authenticator:
        return 'authenticator_app_desc'.tr;
      case TwoFactorMethodType.sms:
        return 'sms_verification_desc'.tr;
      case TwoFactorMethodType.email:
        return 'email_verification_desc'.tr;
    }
  }
}