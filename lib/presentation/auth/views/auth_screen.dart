import 'package:casazero/core/widgets/casazero_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/localization/locale_controller.dart';

class AuthScreen extends GetView<AuthController> {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LocaleController localeController = Get.find();

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

          // Language Selector
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8.h,
            right: 24.w,
            child: Obx(() => _buildLanguageSelector(localeController)),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 448.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CasaZeroLogo(
                          assetPath: 'assets/images/white_logo.png',
                          maxLogoWidthFactor: 0.4,
                        ),
                        SizedBox(height: 40.h),
                        _buildLoginCard(),
                        SizedBox(height: 32.h),
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

  Widget _buildLanguageSelector(LocaleController localeController) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language, color: Colors.white, size: 16.sp),
              SizedBox(width: 4.w),
              _buildLangButton('IT', 'it', localeController),
              _buildLangButton('EN', 'en', localeController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangButton(
    String label,
    String lang,
    LocaleController localeController,
  ) {
    final isActive = localeController.currentLanguageCode == lang;
    return GestureDetector(
      onTap: () => controller.changeLanguage(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.9) : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isActive ? AppColors.brandSage500 : Colors.white,
          ),
        ),
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

  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(32.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'email'.tr,
                hint: 'email_placeholder'.tr,
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                backgroundColor: Colors.white.withOpacity(0.9),
                borderColor: Colors.white.withOpacity(0.4),
                textColor: const Color(0xFF1a1a1a),
              ),
              SizedBox(height: 20.h),
              Obx(
                () => CustomTextField(
                  label: 'password'.tr,
                  hint: '••••••••',
                  controller: controller.passwordController,
                  obscureText: controller.obscurePassword.value,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  borderColor: Colors.white.withOpacity(0.4),
                  textColor: const Color(0xFF1a1a1a),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscurePassword.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                  onSubmitted: (_) => controller.login(),
                ),
              ),
              SizedBox(height: 12.h),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: controller.forgotPassword,
                  child: Text(
                    'forgot_password'.tr,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.8),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Obx(
                () => CustomButton(
                  text: 'sign_in'.tr,
                  onPressed: controller.login,
                  isLoading: controller.isLoading.value,
                  backgroundColor: AppColors.brandSage800,
                  height: 48.h,
                ),
              ),
              SizedBox(height: 24.h),
              _buildDemoModeDivider(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoModeDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1.h, color: Colors.white.withOpacity(0.2)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            'demo_mode'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1.h, color: Colors.white.withOpacity(0.2)),
        ),
      ],
    );
  }

  Widget _buildCopyright() {
    return Text(
      'copyright'.tr,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.6)),
    );
  }
}
