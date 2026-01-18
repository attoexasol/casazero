import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/home_controller.dart';
import '../../../../core/utils/image_url_builder.dart';
import '../../../../app/theme/app_colors.dart';

/// Hero Image Widget
/// Converted from React with Framer Motion animations
/// Matches pixel-perfect design with exact animations and effects
class HeroImage extends StatefulWidget {
  const HeroImage({super.key});

  @override
  State<HeroImage> createState() => _HeroImageState();
}

class _HeroImageState extends State<HeroImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _imageScaleAnimation;

  @override
  void initState() {
    super.initState();

    // ============================================================================
    // ANIMATION SETUP
    // ============================================================================
    // Container Animation: opacity 0→1, scale 0.98→1, 600ms duration, 200ms delay
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Fade animation (opacity 0 → 1)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Scale animation (0.98 → 1.0)
    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Image hover scale effect (1.0 → 1.05, 700ms, smooth easing)
    _imageScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Start animation with 200ms delay
    Future.delayed(const Duration(milliseconds: 200), () {
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
      final residencePhoto = controller.residenceData.value?['residence_photo'];
      final imageUrl = ImageUrlBuilder.buildResidenceImageUrl(residencePhoto);

      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildImageStack(imageUrl),
            ),
          );
        },
      );
    });
  }

  /// Build the complete image stack with all overlays and effects
  Widget _buildImageStack(String imageUrl) {
    return ClipRect(
      child: Container(
        margin: const EdgeInsets.only(top: 5),
        width: double.infinity,
        height: 500, // Fixed height: 500px equivalent
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
          // ============================================================================
          // MAIN IMAGE CONTAINER
          // ============================================================================
          // Base layer: Image with scale animation (hover effect equivalent)
          ScaleTransition(
            scale: _imageScaleAnimation,
            child: _buildImage(imageUrl),
          ),

          // ============================================================================
          // TOP GRADIENT OVERLAY (Header Fade)
          // ============================================================================
          // Gradient: rgb(250, 249, 246) solid → 80% at 10% → transparent at 25%
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.10, 0.25],
                  colors: [
                    const Color(0xFFFAF9F6), // rgb(250, 249, 246) - solid
                    const Color(0xFFFAF9F6).withOpacity(0.8), // 80% opacity at 10%
                    const Color(0xFFFAF9F6).withOpacity(0.0), // transparent at 25%
                  ],
                ),
              ),
            ),
          ),

          // ============================================================================
          // BOTTOM WHITE FADE
          // ============================================================================
          // Gradient: transparent (top) → white (bottom)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // ============================================================================
          // DECORATIVE GLOW EFFECT (Top Right)
          // ============================================================================
          // Position absolute top right, 128x128, accent lime 20% opacity, circular, blurred
          Positioned(
            top: -64, // Center of 128px circle
            right: -64, // Center of 128px circle
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentLime500.withOpacity(0.2), // 20% opacity
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentLime500.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Build the main image widget (API or fallback)
  Widget _buildImage(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      // Use API image if available
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 500,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: double.infinity,
          height: 500,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackImage(),
      );
    } else {
      // Fallback to asset image
      return _buildFallbackImage();
    }
  }

  /// Build fallback asset image
  Widget _buildFallbackImage() {
    return Image.asset(
      'assets/images/residence_hero.jpeg',
      width: double.infinity,
      height: 500,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: 500,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }
}
