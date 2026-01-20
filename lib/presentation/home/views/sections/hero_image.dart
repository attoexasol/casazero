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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Scale animation (0.98 → 1.0)
    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Image hover scale effect (1.0 → 1.05, 700ms, smooth easing)
    _imageScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
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
    return Container(
      margin: const EdgeInsets.only(top: 5),
      width: double.infinity,
      height: 500, // Fixed height: 500px equivalent
      decoration: BoxDecoration(
        // Outer glow/shadow effect for eye-catching depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRect(
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
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
            // LAYER 1: ENHANCED RADIAL GLOW (Dramatic Center Bloom)
            // ============================================================================
            // Creates eye-catching depth with stronger radial glow - extends to top
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.2), // Higher up to reach top better
                    radius: 1.5, // Larger radius to cover top area
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.20),
                      Colors.white.withOpacity(0.35),
                      Colors.white.withOpacity(0.30),
                      Colors.white.withOpacity(0.15), // Extends glow to edges
                    ],
                    stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            // ============================================================================
            // LAYER 3: DRAMATIC BOTTOM WHITE FADE (Strong Transition)
            // ============================================================================
            // More pronounced bottom fade for eye-catching contrast
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.40, 0.60, 0.75, 0.88, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.35),
                      Colors.white.withOpacity(0.65),
                      Colors.white.withOpacity(0.88),
                      Colors.white.withOpacity(0.98),
                    ],
                  ),
                ),
              ),
            ),

            // ============================================================================
            // LAYER 4: ENHANCED VIGNETTE (Stronger Edge Darkening)
            // ============================================================================
            // More dramatic vignette for eye-catching depth and focus
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.12),
                      Colors.black.withOpacity(0.20),
                      Colors.black.withOpacity(0.25),
                    ],
                    stops: const [0.0, 0.4, 0.65, 0.82, 0.92, 1.0],
                  ),
                ),
              ),
            ),

            // ============================================================================
            // LAYER 5: CONTRAST ENHANCEMENT OVERLAY
            // ============================================================================
            // Subtle overlay to boost contrast and make image pop
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.03),
                      Colors.black.withOpacity(0.06),
                    ],
                  ),
                ),
              ),
            ),

            // ============================================================================
            // LAYER 6: ENHANCED LIGHT BLOOM EFFECT (Top Center)
            // ============================================================================
            // Eye-catching light bloom from top center - more visible at top
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.9), // Higher up for top effect
                    radius: 1.8, // Larger radius for better coverage
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.25), // Stronger at center
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.15, 0.35, 0.55, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // ============================================================================
            // LAYER 7: TOP GRADIENT OVERLAY (Premium Header Fade) - PLACED LAST FOR VISIBILITY
            // ============================================================================
            // Stronger top fade for better contrast - placed LAST in stack to ensure visibility
            // This layer MUST cover the FULL top area - using pure white for maximum visibility
            // Positioned.fill ensures it covers the ENTIRE image area including top edge
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.01, 0.03, 0.08, 0.15, 0.25],
                      colors: [
                        Colors.white, // Pure white at top (100% opacity) - FULL COVERAGE AT 0%
                        Colors.white, // Keep white for first 1% to ensure full coverage
                        Colors.white.withOpacity(0.98), // 98% at 3%
                        Colors.white.withOpacity(0.85), // 85% at 8%
                        Colors.white.withOpacity(0.60), // 60% at 15%
                        Colors.white.withOpacity(0.0), // Transparent at 25%
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ============================================================================
            // LAYER 8: TOP EDGE GLOW (Additional Top Effect) - FINAL LAYER
            // ============================================================================
            // Extra top edge glow for maximum visibility - FINAL layer for top effects
            // Ensures the very top edge is fully covered - covers ENTIRE top area
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.01, 0.04, 0.08, 0.15],
                      colors: [
                        Colors.white.withOpacity(0.6), // Strong glow at very top (0%) - FULL COVERAGE
                        Colors.white.withOpacity(0.5), // Strong glow at 1%
                        Colors.white.withOpacity(0.3), // Medium glow at 4%
                        Colors.white.withOpacity(0.15), // Subtle glow at 8%
                        Colors.transparent, // Transparent at 15%
                      ],
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
          child: const Center(child: CircularProgressIndicator()),
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
