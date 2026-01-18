import 'package:flutter/material.dart';
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
    // Using double for absolute pixel offset with Transform.translate
    _slideAnimation = Tween<double>(
      begin: 20.0, // +20px absolute offset (slide up into view)
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
      // ============================================================================
      // LANGUAGE-BASED TEXT LOGIC INTEGRATION POINT
      // ============================================================================
      // Get LocaleController to determine current language
      final localeController = Get.find<LocaleController>();
      final isItalian = localeController.isItalian;

      // Get user's first name
      final firstName = widget.user?.firstName ?? 'User';

      // Build welcome text based on language
      // Italian: "BENVENUTO " + firstName
      // English: "Welcome " + firstName
      final welcomeText = 'welcome'.tr + ' $firstName';

      // Access reactive locale property to trigger updates on language change
      final _ = localeController.locale;

      return FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value), // Absolute +20px → 0px
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
      color: AppColors.surfaceWhite, // Background color: white
      padding: const EdgeInsets.only(
        top: 16, // Top padding: 16px (pt-4)
        left: 24, // Horizontal padding: 24px (px-6)
        right: 24, // Horizontal padding: 24px (px-6)
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 448,
          ), // Max width: 448px (max-w-md)
          child: Transform.translate(
            offset: const Offset(0, -16), // Negative top margin: -16px (-mt-4)
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
      textAlign: TextAlign.center, // Text alignment: center
      style: TextStyle(
        fontSize: 22, // Font size: 1.375rem (~22px)
        fontWeight: FontWeight.w500, // Font weight: Medium (500)
        letterSpacing: -0.33, // Letter spacing: -0.015em (22 * -0.015 = -0.33)
        color: AppColors.neutralInk500, // Text color: neutral-ink-700
        fontFamily: AppTextStyles.fontFamily,
        height: 1.4, // Maintain vertical rhythm
      ),
      // Handle long names gracefully without overflow
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }
}
