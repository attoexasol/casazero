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
      child: ClipRect(
        clipBehavior: Clip
            .antiAlias, // Smooth anti-aliased edges for better gradient blending
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
                    center: const Alignment(
                      0.0,
                      -0.2,
                    ), // Higher up to reach top better
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
            // Darkening stops before bottom edge to prevent dark line interference with bottom fade
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [
                      0.0,
                      0.5,
                      0.75,
                      1.0,
                    ], // Stop darkening at 75% to avoid bottom edge
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.03),
                      Colors.black.withOpacity(0.03), // Keep same at 75%
                      Colors.black.withOpacity(
                        0.0,
                      ), // Fade to transparent at bottom to avoid dark line
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
                    center: const Alignment(
                      0.0,
                      -0.9,
                    ), // Higher up for top effect
                    radius: 1.8, // Larger radius for better coverage
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.00), // Stronger at center
                      Colors.white.withOpacity(0.00),
                      Colors.white.withOpacity(0.00),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.15, 0.35, 0.55, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // ============================================================================
            // LAYER 7: SEAMLESS BOTTOM EDGE BLEND (Smooth Background Integration) - SECOND TO LAST
            // ============================================================================
            // Smooth bottom fade that blends seamlessly with app background (white)
            // EXACTLY mirrors the top fade (Layer 8) for perfect visual symmetry
            // Same structure, same stops (inverted direction), same colors, same quality
            // Placed second-to-last to ensure same visibility as top fade
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment
                          .topCenter, // Inverted direction to mirror top
                      stops: const [
                        0.0,
                        0.02,
                        0.05,
                        0.10,
                        0.18,
                        0.28,
                      ], // EXACTLY same stops as top fade
                      colors: [
                        AppColors
                            .surfaceWhite, // Full white at bottom - seamless blend with background (mirrors top 0%)
                        AppColors
                            .surfaceWhite, // Keep white for first 2% for smooth transition (mirrors top 2%)
                        AppColors.surfaceWhite.withOpacity(
                          0.90,
                        ), // 95% at 5% (EXACTLY mirrors top 5%)
                        AppColors.surfaceWhite.withOpacity(
                          0.65,
                        ), // 80% at 10% (EXACTLY mirrors top 10%)
                        AppColors.surfaceWhite.withOpacity(
                          0.15,
                        ), // 50% at 18% (EXACTLY mirrors top 18%)
                        AppColors.surfaceWhite.withOpacity(
                          0.0,
                        ), // Transparent at 28% (EXACTLY mirrors top 28%)
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ============================================================================
            // LAYER 8: SEAMLESS TOP EDGE BLEND (Smooth Background Integration) - PLACED LAST
            // ============================================================================
            // Smooth top fade that blends seamlessly with app background (white)
            // Long, natural gradient to eliminate visible edge - placed LAST for visibility
            // This creates an unbroken, continuous feel with the app header/background
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.02, 0.05, 0.10, 0.18, 0.28],
                      colors: [
                        AppColors
                            .surfaceWhite, // Full white at top - seamless blend with background
                        AppColors
                            .surfaceWhite, // Keep white for first 2% for smooth transition
                        AppColors.surfaceWhite.withOpacity(0.90), // 95% at 5%
                        AppColors.surfaceWhite.withOpacity(0.65), // 80% at 10%
                        AppColors.surfaceWhite.withOpacity(0.15), // 50% at 18%
                        AppColors.surfaceWhite.withOpacity(
                          0.0,
                        ), // Transparent at 28%
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
