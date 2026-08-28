// presentation/auth/views/forgot_change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/casazero_logo.dart';
import '../../../core/widgets/password_input.dart';
import '../controllers/forgot_change_password_controller.dart';

class ForgotChangePasswordScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String message) onSuccess;

  const ForgotChangePasswordScreen({
    super.key,
    required this.onBack,
    required this.onSuccess,
  });

  @override
  State<ForgotChangePasswordScreen> createState() =>
      _ForgotChangePasswordScreenState();
}

class _ForgotChangePasswordScreenState extends State<ForgotChangePasswordScreen> {
  late final ForgotChangePasswordController _ctrl;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ForgotChangePasswordController>();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _ctrl.bindTextControllers(
      newPassword: _newPasswordController,
      confirmPassword: _confirmPasswordController,
    );
  }

  @override
  void dispose() {
    _ctrl.unbindTextControllers();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
        child: InkWell(
          onTap: widget.onBack,
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

  Widget _buildFormContent() {
    return GetBuilder<ForgotChangePasswordController>(
      builder: (ctrl) {
        return Obx(
          () => AbsorbPointer(
            absorbing: ctrl.isCompleted.value,
            child: Column(
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
                  'create_new_password'.tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 32.h),
                Column(
                  children: [
                    PasswordInputField(
                      label: 'new_password'.tr,
                      controller: _newPasswordController,
                      isVisible: ctrl.showNewPassword,
                      onToggle: () => ctrl.togglePasswordVisibility('new'),
                    ),
                    SizedBox(height: 20.h),
                    PasswordInputField(
                      label: 'confirm_password'.tr,
                      controller: _confirmPasswordController,
                      isVisible: ctrl.showConfirmPassword,
                      onToggle: () => ctrl.togglePasswordVisibility('confirm'),
                    ),
                    Obx(() {
                      if (!ctrl.hasPasswordInput.value) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          SizedBox(height: 20.h),
                          _passwordRequirements(ctrl),
                        ],
                      );
                    }),
                    Obx(() {
                      if (!ctrl.showPasswordMatch.value) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          SizedBox(height: 12.h),
                          _passwordMatchIndicator(ctrl),
                        ],
                      );
                    }),
                  ],
                ),
                SizedBox(height: 32.h),
                Obx(() => _submitButton(ctrl)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _passwordRequirements(ForgotChangePasswordController ctrl) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'password_requirements'.tr,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 8.h),
          ...ctrl.passwordRequirements.asMap().entries.map((entry) {
            final index = entry.key;
            final req = entry.value;
            return Row(
              children: [
                Container(
                  width: 16.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: req.isMet
                        ? const Color(0xFF22C55E)
                        : Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: req.isMet
                      ? Icon(
                          Icons.check,
                          size: 12.sp,
                          color: Colors.white,
                        )
                      : null,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    req.label.tr,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: req.isMet
                          ? const Color(0xFF22C55E)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
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

  Widget _passwordMatchIndicator(ForgotChangePasswordController ctrl) {
    final match = ctrl.passwordsMatch;
    return Row(
      children: [
        Icon(
          match ? Icons.check : Icons.close,
          color: match ? const Color(0xFF22C55E) : const Color(0xFFE11D48),
          size: 16.sp,
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            match ? 'passwords_match'.tr : 'passwords_no_match'.tr,
            style: TextStyle(
              fontSize: 11.sp,
              color: match ? const Color(0xFF22C55E) : const Color(0xFFE11D48),
            ),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _submitButton(ForgotChangePasswordController ctrl) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: ctrl.canSubmit && !ctrl.isLoading.value
            ? () => ctrl.handleResetPassword(onSuccess: widget.onSuccess)
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
