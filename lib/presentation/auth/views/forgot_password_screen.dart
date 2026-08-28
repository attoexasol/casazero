// presentation/auth/views/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
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
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.3),
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
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 430.w),
                child: Column(
                  children: [
                    CasaZeroLogo(
                      assetPath: 'assets/images/white_logo.png',
                      maxLogoWidthFactor: 0.4,
                      showTagline: false,
                    ),
                    SizedBox(height: 40.h),
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
      padding: EdgeInsets.all(24.r),
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
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'back'.tr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14.sp,
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
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: Container(
              padding: EdgeInsets.all(32.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.05),
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
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'reset_password_description'.tr,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 32.h),

            // FORM FIELDS
            Column(
              children: [
                // Email Field
                CustomTextField(
                  label: 'email'.tr,
                  hint: 'email_placeholder'.tr,
                  controller: ctrl.emailController,
                  keyboardType: TextInputType.emailAddress,
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  borderColor: Colors.white.withValues(alpha: 0.4),
                  textColor: const Color(0xFF1a1a1a),
                ),
              ],
            ),

            SizedBox(height: 32.h),

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
      height: 48.h,
      child: ElevatedButton(
        onPressed: ctrl.canSubmit && !ctrl.isLoading.value
            ? () => ctrl.handleResetPassword(onSuccess: onSuccess)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ctrl.canSubmit
              ? AppColors.brandSage800
              : const Color(0xFF9CA3AF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 8,
          shadowColor: ctrl.canSubmit
              ? AppColors.brandSage800.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
        child: ctrl.isLoading.value
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'reset_password'.tr,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
