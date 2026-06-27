import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/localization/locale_controller.dart';

/// Welcome User Section Widget
/// Converted from React with Framer Motion animations
/// Matches pixel-perfect design with exact typography, spacing, and animations
class WelcomeUserSection extends StatefulWidget {
  final dynamic user;

  const WelcomeUserSection({super.key, required this.user});

  @override
  State<WelcomeUserSection> createState() => _WelcomeUserSectionState();
}

class _WelcomeUserSectionState extends State<WelcomeUserSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // ============================================================================
    // WELCOME TEXT ANIMATION SETUP
    // ============================================================================
    // Animation: opacity 0→1, translateY +20px→0, 500ms duration, 400ms delay
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Fade animation (opacity 0 → 1)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Slide animation (translateY +20px → 0)
    _slideAnimation = Tween<double>(
      begin: 20.h,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation with 400ms delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final localeController = Get.find<LocaleController>();

      // Get user's first name
      final firstName = widget.user?.firstName ?? 'User';

      // Build welcome text based on language
      final welcomeText = 'welcome'.tr + ' $firstName';

      // Access reactive locale property to trigger updates on language change
      final _ = localeController.locale;

      return FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: child,
            );
          },
          child: _buildContainer(welcomeText),
        ),
      );
    });
  }

  /// Build outer container with padding, max-width, and negative top margin
  Widget _buildContainer(String welcomeText) {
    return Container(
      color: AppColors.surfaceWhite,
      padding: EdgeInsets.only(
        top: 16.h,
        left: 24.w,
        right: 24.w,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 448.w),
          child: Transform.translate(
            offset: Offset(0, -16.h),
            child: _buildWelcomeText(welcomeText),
          ),
        ),
      ),
    );
  }

  /// Build welcome text with exact typography styling
  Widget _buildWelcomeText(String welcomeText) {
    return Text(
      welcomeText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.33,
        color: AppColors.neutralInk500,
        fontFamily: AppTextStyles.fontFamily,
        height: 1.4,
      ),
      softWrap: true,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
