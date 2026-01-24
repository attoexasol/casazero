// presentation/first_login/views/first_login_setup_screen.dart (ENHANCED WITH 2FA)
import 'package:casazero/core/widgets/casazero_logo.dart';
import 'package:casazero/presentation/first_login/views/sections/first_login_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/controllers/message_popup_controller.dart';
import 'dart:ui';
import 'dart:convert'; // For base64Decode
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/first_login_controller.dart';
import '../../../data/models/two_factor_method_model.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../app/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';   //

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
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      children: [
                        CasaZeroLogo(
                          assetPath: 'assets/images/white_logo.png',
                          maxLogoWidthFactor: 0.4,
                        ),
                        const SizedBox(height: 32),
                        FirstLoginProgressBar(controller: controller),
                        const SizedBox(height: 24),
                        Obx(() => controller.currentStep.value == 1
                            ? _buildPasswordChangeCard()
                            : _build2FACard()),
                        const SizedBox(height: 24),
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
          width: 240,
          height: 80,
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/white_logo.png',
            width: 180,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'smart_living'.tr,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'first_login_setup'.tr,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'secure_your_account'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Obx(
          () => Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: controller.currentStep.value == 1 ? 0.5 : 1.0,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandSage500),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'change_password'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: controller.currentStep.value == 1
                      ? Colors.white
                      : Colors.white.withOpacity(0.7),
                  fontWeight: controller.currentStep.value == 1
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              Text(
                'two_factor_auth'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: controller.currentStep.value == 2
                      ? Colors.white
                      : Colors.white.withOpacity(0.7),
                  fontWeight: controller.currentStep.value == 2
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordChangeCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [AppColors.brandSage500, AppColors.brandSage600],
                      ),
                    ),
                    child: const Icon(Icons.lock, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'change_password'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'create_strong_password'.tr,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAlert(
                icon: Icons.info_outline,
                text: 'first_login_password_change'.tr,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
                    const SizedBox(height: 12),
                    _buildValidPasswordIndicator(),
                  ],
                );
              }),
              const SizedBox(height: 24),
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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [AppColors.brandSage500, AppColors.brandSage600],
                      ),
                    ),
                    child: const Icon(Icons.security, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'two_factor_auth'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'choose_security_method'.tr,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAlert(
                icon: Icons.shield_outlined,
                text: '2fa_security_notice'.tr,
              ),
              const SizedBox(height: 16),
              Obx(() => Column(
                children: controller.twoFactorMethods
                    .map((method) => _buildMethodCard(method))
                    .toList(),
              )),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.goBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('back'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: controller.setup2FA,
                      child: Text(
                        'skip_for_now'.tr,
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => controller.selectTwoFactorMethod(method),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getMethodIcon(method.icon),
                  color: Colors.white,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.7),
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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'configure_method'.tr,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (method.type == TwoFactorMethodType.authenticator)
                _buildAuthenticatorSetup()
              else if (method.type == TwoFactorMethodType.email)
                _buildEmailSetup()
              else if (method.type == TwoFactorMethodType.sms)
                  _buildSMSSetup(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.cancelMethodConfiguration,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
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
        const SizedBox(height: 16),
        if (controller.qrCodeData.value.isNotEmpty) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildQRCodeImage(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: controller.toggleManualEntry,
              icon: Icon(
                controller.showManualEntry.value
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white70,
                size: 18,
              ),
              label: Text(
                controller.showManualEntry.value
                    ? 'hide_manual_entry'.tr
                    : 'show_manual_entry'.tr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (controller.showManualEntry.value) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'manual_entry_key'.tr}:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          controller.totpSecret.value,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white, size: 18),
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
          const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.email, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.userEmail,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
          const SizedBox(height: 8),
          if (controller.verificationCountdown.value > 0)
            Center(
              child: Text(
                '${'resend_in'.tr} ${controller.verificationCountdown.value}s',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            )
          else
            Center(
              child: TextButton(
                onPressed: controller.sendVerificationCode,
                child: Text(
                  'resend_code'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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
        const SizedBox(height: 16),
        CustomTextField(
          label: 'phone_number'.tr,
          hint: '+1 (555) 123-4567',
          controller: controller.phoneNumberController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
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
          const SizedBox(height: 8),
          if (controller.verificationCountdown.value > 0)
            Center(
              child: Text(
                '${'resend_in'.tr} ${controller.verificationCountdown.value}s',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            )
          else
            Center(
              child: TextButton(
                onPressed: controller.sendVerificationCode,
                child: Text(
                  'resend_code'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: allMet
              ? Colors.green.withOpacity(0.2)
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: allMet
                ? Colors.green.withOpacity(0.4)
                : Colors.white.withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (allMet)
                  Row(
                    children: [
                      const Icon(Icons.check, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'complete'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...controller.passwordRequirements.map((req) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: req.isMet ? Colors.green : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                      child: req.isMet
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        req.label,
                        style: TextStyle(
                          color: req.isMet
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                          fontSize: 13,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'valid_password'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
        fontSize: 12,
        color: Colors.white.withOpacity(0.6),
      ),
    );
  }

  /// Build QR code image from base64 data
  /// The API returns: "data:image/svg+xml;base64,..."
  Widget _buildQRCodeImage() {
    final qrData = controller.qrCodeData.value;

    if (qrData.isEmpty) {
      return const SizedBox(
        width: 200,
        height: 200,
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
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        );
      }

      // Else assume PNG/JPG
      final base64String = qrData.split(',').last;
      final bytes = base64Decode(base64String);

      return Image.memory(
        bytes,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
      );
    } catch (e) {
      print("QR decode error: $e");
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.error, size: 48, color: Colors.red),
        ),
      );
    }
  }

}