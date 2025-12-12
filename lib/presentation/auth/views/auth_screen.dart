import 'package:casazero/core/widgets/casazero_logo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/localization/locale_controller.dart';

class AuthScreen extends GetView<AuthController> {
  const AuthScreen({Key? key}) : super(key: key);

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
            top: 40,
            right: 24,
            child: Obx(() => _buildLanguageSelector(localeController)),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CasaZeroLogo(
                          assetPath: 'assets/images/white_logo.png',
                          maxLogoWidthFactor: 0.4,
                        ),
                        const SizedBox(height: 40),
                        _buildLoginCard(),
                        const SizedBox(height: 32),
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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, color: Colors.white, size: 16),
              const SizedBox(width: 4),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.9) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
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
      ],
    );
  }

  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 10),
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
              const SizedBox(height: 20),
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: controller.forgotPassword,
                  child: Text(
                    'forgot_password'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => CustomButton(
                  text: 'sign_in'.tr,
                  onPressed: controller.login,
                  isLoading: controller.isLoading.value,
                  backgroundColor: AppColors.brandSage500,
                  height: 48,
                ),
              ),
              const SizedBox(height: 24),
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
          child: Container(height: 1, color: Colors.white.withOpacity(0.2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'demo_mode'.tr,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.2)),
        ),
      ],
    );
  }

  Widget _buildCopyright() {
    return Text(
      'copyright'.tr,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
    );
  }
}
