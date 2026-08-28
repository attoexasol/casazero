import 'package:casazero/core/widgets/casazero_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../controllers/auth_controller.dart';
import '../../../core/controllers/message_popup_controller.dart';
import '../../../core/logging/diagnostic_logger.dart';
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
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.3),
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
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 448.w),
                    child: Obx(() {
                      final _ = localeController.locale;
                      return Column(
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
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

          // Language selector on top so SafeArea does not block taps
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8.h,
            right: 24.w,
            child: _buildLanguageSelector(localeController),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(LocaleController localeController) {
    const switchDuration = Duration(milliseconds: 280);
    const switchCurve = Curves.easeInOutCubic;
    final segmentWidth = 42.w;
    final segmentHeight = 30.h;

    return Obx(() {
      final isItalian = localeController.isItalian;

      return ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, color: Colors.white, size: 16.sp),
                SizedBox(width: 6.w),
                SizedBox(
                  width: segmentWidth * 2,
                  height: segmentHeight,
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: switchDuration,
                        curve: switchCurve,
                        left: isItalian ? 0 : segmentWidth,
                        top: 0,
                        bottom: 0,
                        width: segmentWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _buildLangSegment(
                            label: 'IT',
                            lang: 'it',
                            isActive: isItalian,
                            width: segmentWidth,
                            height: segmentHeight,
                            duration: switchDuration,
                            curve: switchCurve,
                          ),
                          _buildLangSegment(
                            label: 'EN',
                            lang: 'en',
                            isActive: !isItalian,
                            width: segmentWidth,
                            height: segmentHeight,
                            duration: switchDuration,
                            curve: switchCurve,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLangSegment({
    required String label,
    required String lang,
    required bool isActive,
    required double width,
    required double height,
    required Duration duration,
    required Curve curve,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.changeLanguage(lang),
        borderRadius: BorderRadius.circular(20.r),
        splashColor: Colors.white.withValues(alpha: 0.12),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: duration,
              curve: curve,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.brandSage500 : Colors.white,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return KeyedSubtree(
      key: ValueKey(controller.hashCode),
      child: ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(32.r),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
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
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                borderColor: Colors.white.withValues(alpha: 0.4),
                textColor: const Color(0xFF1a1a1a),
              ),
              SizedBox(height: 20.h),
              Obx(
                () => CustomTextField(
                  label: 'password'.tr,
                  hint: '••••••••',
                  controller: controller.passwordController,
                  obscureText: controller.obscurePassword.value,
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  borderColor: Colors.white.withValues(alpha: 0.4),
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
                      color: Colors.white.withValues(alpha: 0.8),
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
              SizedBox(height: 16.h),
              _buildExportDiagnosticLog(),
              SizedBox(height: 24.h),
              _buildDemoModeDivider(),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildExportDiagnosticLog() {
    return Builder(
      builder: (context) {
        return Center(
          child: GestureDetector(
            onTap: () => _exportDiagnosticLog(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.ios_share,
                  size: 16.sp,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                SizedBox(width: 8.w),
                Text(
                  'export_diagnostic_log'.tr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportDiagnosticLog(BuildContext context) async {
    try {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      Rect? origin;
      if (box != null && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
      final bool ok = await DiagnosticLogger.instance.shareLogFile(
        shareOrigin: origin,
      );
      if (!ok) {
        await MessagePopupController.showError(
          messageKey: 'diagnostic_log_export_failed',
          titleKey: 'error',
        );
      }
    } catch (_) {
      try {
        await MessagePopupController.showError(
          messageKey: 'diagnostic_log_export_failed',
          titleKey: 'error',
        );
      } catch (_) {}
    }
  }

  Widget _buildDemoModeDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1.h, color: Colors.white.withValues(alpha: 0.2)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            'demo_mode'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1.h, color: Colors.white.withValues(alpha: 0.2)),
        ),
      ],
    );
  }

  Widget _buildCopyright() {
    return Text(
      'copyright'.tr,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12.sp, color: Colors.white.withValues(alpha: 0.6)),
    );
  }
}
