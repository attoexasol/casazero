// presentation/auth/views/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../core/widgets/casazero_logo.dart';
import '../../../core/widgets/password_input.dart';
import '../controllers/change_password_controller.dart';

class ChangePasswordScreen extends GetView<ChangePasswordController> {
  final VoidCallback onBack;
  final VoidCallback onSuccess;

  const ChangePasswordScreen({
    super.key,
    required this.onBack,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(child: _buildContent()),
        ],
      ),
    );
  }

  // --------------------------
  // BACKGROUND
  // --------------------------
  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
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
      ),
    );
  }

  // --------------------------
  // MAIN CONTENT
  // --------------------------
  Widget _buildContent() {
    return Column(
      children: [
        _buildBackButton(),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    CasaZeroLogo(
                      assetPath: 'assets/images/white_logo.png',
                      maxLogoWidthFactor: 0.4,
                      showTagline: false,
                    ),
                    const SizedBox(height: 40),
                    _buildGlassCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.centerLeft,
        child:
            InkWell(
                  onTap: onBack,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'back'.tr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideX(begin: -0.2, delay: 200.ms),
      ),
    );
  }

  // --------------------------
  // GLASSMORPHIC CARD
  // --------------------------
  Widget _buildGlassCard() {
    return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: _buildFormContent(),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.2, delay: 400.ms);
  }

  // --------------------------
  // FORM CONTENT
  // --------------------------
  Widget _buildFormContent() {
    return GetBuilder<ChangePasswordController>(
      builder: (ctrl) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'secure_your_account'.tr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'first_login_password_change'.tr,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),

            // PASSWORD FIELDS
            Column(
              children: [
                // Current Password
                PasswordInputField(
                  label: 'current_password'.tr,
                  controller: ctrl.currentPasswordController,
                  isVisible: ctrl.showCurrentPassword,
                  onToggle: () => ctrl.togglePasswordVisibility('current'),
                ),

                const SizedBox(height: 20),

                // New Password
                PasswordInputField(
                  label: 'new_password'.tr,
                  controller: ctrl.newPasswordController,
                  isVisible: ctrl.showNewPassword,
                  onToggle: () => ctrl.togglePasswordVisibility('new'),
                ),

                const SizedBox(height: 20),

                // Confirm Password
                PasswordInputField(
                  label: 'confirm_password'.tr,
                  controller: ctrl.confirmPasswordController,
                  isVisible: ctrl.showConfirmPassword,
                  onToggle: () => ctrl.togglePasswordVisibility('confirm'),
                ),

                // Requirements
                Obx(() {
                  if (!ctrl.hasPasswordInput.value) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      _passwordRequirements(ctrl),
                    ],
                  );
                }),

                // Password Match
                Obx(() {
                  if (!ctrl.showPasswordMatch.value) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      _passwordMatchIndicator(ctrl),
                    ],
                  );
                }),
              ],
            ),

            const SizedBox(height: 32),

            // Submit Button
            Obx(() => _submitButton(ctrl)),
          ],
        );
      },
    );
  }

  // --------------------------
  // PASSWORD REQUIREMENTS
  // --------------------------
  Widget _passwordRequirements(ChangePasswordController ctrl) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'password_requirements'.tr,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          ...ctrl.passwordRequirements.asMap().entries.map((entry) {
            final index = entry.key;
            final req = entry.value;
            return Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: req.isMet
                            ? const Color(0xFF22C55E)
                            : Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: req.isMet
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      req.label.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: req.isMet
                            ? const Color(0xFF22C55E)
                            : Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                )
                .animate()
                .fadeIn(delay: (index * 50).ms)
                .slideX(begin: -0.1, delay: (index * 50).ms);
          }),
        ],
      );
    });
  }

  // --------------------------
  // MATCH INDICATOR
  // --------------------------
  Widget _passwordMatchIndicator(ChangePasswordController ctrl) {
    final match = ctrl.passwordsMatch;
    return Row(
      children: [
        Icon(
          match ? Icons.check : Icons.close,
          color: match ? const Color(0xFF22C55E) : const Color(0xFFE11D48),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          match ? 'passwords_match'.tr : 'passwords_no_match'.tr,
          style: TextStyle(
            fontSize: 11,
            color: match ? const Color(0xFF22C55E) : const Color(0xFFE11D48),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  // --------------------------
  // SUBMIT BUTTON
  // --------------------------
  Widget _submitButton(ChangePasswordController ctrl) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: ctrl.canSubmit && !ctrl.isLoading.value
            ? () => ctrl.handleChangePassword(onSuccess: onSuccess)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ctrl.canSubmit
              ? const Color(0xFF22C55E)
              : const Color(0xFF9CA3AF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: ctrl.canSubmit
              ? const Color(0xFF22C55E).withOpacity(0.4)
              : Colors.transparent,
        ),
        child: ctrl.isLoading.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'change_password'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
