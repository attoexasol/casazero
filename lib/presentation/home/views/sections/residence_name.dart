import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../controllers/home_controller.dart';

/// Residence Title Section Widget
/// Converted from React with Framer Motion animations
/// Matches pixel-perfect design with exact typography, spacing, and animations
class ResidenceName extends StatefulWidget {
  final dynamic user;

  const ResidenceName({super.key, required this.user});

  @override
  State<ResidenceName> createState() => _ResidenceNameState();
}

class _ResidenceNameState extends State<ResidenceName>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // ============================================================================
    // ENTRY ANIMATION SETUP
    // ============================================================================
    // Entry Animation: opacity 0→1, translateY -10px→0, 500ms duration, 100ms delay
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Fade animation (opacity 0 → 1)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Slide animation (translateY -10px → 0)
    // Using double for absolute pixel offset with Transform.translate
    _slideAnimation = Tween<double>(
      begin: -10.0, // -10px absolute offset
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation with 100ms delay
    Future.delayed(const Duration(milliseconds: 100), () {
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
    final controller = Get.find<HomeController>();

    return Obx(() {
      // Get residence name from controller only (no user name fallback)
      final name = controller.residenceData.value?['residence_name'] ?? 'Villa';

      // Prepend localized "Residence" label based on language settings
      final residenceName = '${'residence'.tr} $name';

      return FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value), // Absolute -10px → 0px
              child: child,
            );
          },
          child: _buildContainer(residenceName),
        ),
      );
    });
  }

  /// Build outer container with padding and max-width constraint
  Widget _buildContainer(String residenceName) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 24, // Top padding: 24px (pt-6)
        left: 24, // Horizontal padding: 24px (px-6)
        right: 24, // Horizontal padding: 24px (px-6)
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 448,
          ), // Max width: 448px (max-w-md)
          child: _buildTitleText(residenceName),
        ),
      ),
    );
  }

  /// Build title text with exact typography styling
  Widget _buildTitleText(String residenceName) {
    return Text(
      residenceName,
      textAlign: TextAlign.center, // Center aligned text
      style: TextStyle(
        fontSize: 28, // Font size: 1.75rem (~28px)
        fontWeight: FontWeight.w600, // Font weight: SemiBold (600)
        letterSpacing: -0.7, // Letter spacing: -0.025em (28 * -0.025 = -0.7)
        color: AppColors.neutralInk900, // Text color: neutral-ink-900
        fontFamily: AppTextStyles.fontFamily,
        height: 1.4, // Maintain vertical rhythm
      ),
      // Support long residence names gracefully (wrap or soft break)
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }
}
