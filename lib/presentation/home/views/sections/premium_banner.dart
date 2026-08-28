import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_text_styles.dart';

/// What's New Banner Widget
/// Converted from React with Framer Motion animations
/// Matches pixel-perfect design with exact animations and effects
class PremiumBanner extends StatefulWidget {
  const PremiumBanner({super.key});

  @override
  State<PremiumBanner> createState() => _PremiumBannerState();
}

class _PremiumBannerState extends State<PremiumBanner>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // ============================================================================
    // ENTRY ANIMATION SETUP
    // ============================================================================
    // Entry Animation: opacity 0→1, translateY -20px→0, 500ms duration
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Fade animation (opacity 0 → 1)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOut,
      ),
    );

    // Slide animation (translateY -20px → 0)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -20 / 100), // -20px relative to height
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOut,
      ),
    );

    // ============================================================================
    // ROTATION ANIMATION SETUP
    // ============================================================================
    // Continuous subtle rotation loop: 0° → 10° → -10° → 0°
    // Duration: 2 seconds, infinite repeat, 5 seconds delay between loops
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Rotation sequence: 0° → 10° → -10° → 0°
    // Convert degrees to turns: 10° = 10/360 = 0.0278 turns
    const double maxRotationTurns = 10 / 360; // 10 degrees in turns
    
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: maxRotationTurns)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: maxRotationTurns, end: -maxRotationTurns)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -maxRotationTurns, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(_rotationController);

    // Start entry animation immediately
    _entryController.forward();

    // Start rotation animation immediately, then repeat with delay between loops
    _startRotationAnimation();
  }

  /// Start rotation animation with delay between loops
  void _startRotationAnimation() {
    _rotationController.forward().then((_) {
      if (mounted) {
        // Wait 5 seconds before starting next cycle
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _rotationController.reset();
            _startRotationAnimation(); // Repeat cycle
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildBanner(),
      ),
    );
  }

  /// Build the main banner container
  Widget _buildBanner() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite, // Pure white background
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutralLine200.withValues(alpha: 0.5), // 50% opacity
            width: 1, // 1px thickness
          ),
        ),
        boxShadow: AppShadows.shadowSm, // Subtle elevation (shadow-sm)
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 24, // Horizontal padding: 24px
        vertical: 16, // Vertical padding: 16px
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 448.w),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  /// Build inner layout with icon and text
  Widget _buildContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align items to top (start)
      children: [
        // ============================================================================
        // ANIMATED ICON CONTAINER (Left)
        // ============================================================================
        _buildAnimatedIconContainer(),

        const SizedBox(width: 12), // Gap between icon and text: 12px

        // ============================================================================
        // TEXT CONTENT
        // ============================================================================
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2), // Top margin offset: 2px (mt-0.5)
            child: _buildTextContent(),
          ),
        ),
      ],
    );
  }

  /// Build animated icon container with gradient and rotation
  Widget _buildAnimatedIconContainer() {
    return RotationTransition(
      turns: _rotationAnimation,
      child: Container(
        width: 40, // Width: 40px
        height: 40, // Height: 40px
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), // Large rounded corners (rounded-2xl)
          gradient: const LinearGradient(
            begin: Alignment.topLeft, // Direction: top-left → bottom-right
            end: Alignment.bottomRight,
            colors: [
              AppColors.brandSage500, // From: brand-sage-500
              AppColors.accentLime500, // To: accent-lime-500
            ],
          ),
          boxShadow: AppShadows.shadowLg, // Medium shadow (shadow-lg)
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome, // Sparkles icon
            color: Colors.white, // Icon color: white
            size: 20, // Icon size: 20px
          ),
        ),
      ),
    );
  }

  /// Build text content with proper styling
  Widget _buildTextContent() {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.neutralInk800, // Normal text: neutral-ink-800
          fontSize: 14.sp,
          height: 1.5, // Line height: relaxed
        ),
        children: [
          TextSpan(
            text: 'whats_new: '.tr,
            style: const TextStyle(
              fontWeight: FontWeight.w500, // Font weight: medium
              color: AppColors.neutralInk900, // Color: neutral-ink-900
            ),
          ),
          TextSpan(
            text: 'ai_document_analysis'.tr,
          ),
        ],
      ),
    );
  }
}

