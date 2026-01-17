// presentation/auth/views/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../core/widgets/casazero_logo.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  final VoidCallback onBack;
  final Function(String message) onSuccess;

  const ForgotPasswordScreen({
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
    return GetBuilder<ForgotPasswordController>(
      builder: (ctrl) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'reset_password'.tr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'reset_password_description'.tr,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),

            // FORM FIELDS
            Column(
              children: [
                // Email Field
                CustomTextField(
                  label: 'email'.tr,
                  hint: 'email_placeholder'.tr,
                  controller: ctrl.emailController,
                  keyboardType: TextInputType.emailAddress,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  borderColor: Colors.white.withOpacity(0.4),
                  textColor: const Color(0xFF1a1a1a),
                ),
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
  // SUBMIT BUTTON
  // --------------------------
  Widget _submitButton(ForgotPasswordController ctrl) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: ctrl.canSubmit && !ctrl.isLoading.value
            ? () => ctrl.handleResetPassword(onSuccess: onSuccess)
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
                'reset_password'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
