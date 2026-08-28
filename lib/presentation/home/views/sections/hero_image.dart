import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    _imageScaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
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

  /// Hero height scaled to viewport (design: 500px @ 844px height), clamped for
  /// small phones so the section is neither clipped nor oversized.
  double _heroHeight(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    const designViewportHeight = 844.0;
    const designHeroHeight = 500.0;
    final proportionalHeight =
        viewportHeight * (designHeroHeight / designViewportHeight);
    return proportionalHeight.clamp(280.h, 500.h);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final heroHeight = _heroHeight(context);

    return Obx(() {
      final residencePhoto = controller.residenceData.value?['residence_photo'];
      final imageUrl = ImageUrlBuilder.buildResidenceImageUrl(residencePhoto);

      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ClipRect(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildImageStack(imageUrl, heroHeight),
              ),
            ),
          );
        },
      );
    });
  }

  /// Build the complete image stack with all overlays and effects
  Widget _buildImageStack(String imageUrl, double heroHeight) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      width: double.infinity,
      height: heroHeight,
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
              child: _buildImage(imageUrl, heroHeight),
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
                    radius: 0.9, // Larger radius to cover top area
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            // ============================================================================
            // LAYER 4: ENHANCED VIGNETTE (Stronger Edge Darkening)
            // ============================================================================
            // Corner-focused vignette: outer stops stay transparent so top/bottom
            // edges do not show dark bands where the edge-fade overlays end.
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.4, 0.65, 0.72, 0.82, 0.92, 1.0],
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
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.03),
                      Colors.black.withValues(alpha: 0.03), // Keep same at 75%
                      Colors.black.withValues(alpha: 
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
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.00), // Stronger at center
                      Colors.white.withValues(alpha: 0.00),
                      Colors.white.withValues(alpha: 0.00),
                      Colors.white.withValues(alpha: 0.0),
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
            // ============================================================================
            // LAYER 7: BOTTOM FADE
            // ============================================================================
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.surfaceWhite,
                        AppColors.surfaceWhite.withValues(alpha: 0.85),
                        AppColors.surfaceWhite.withValues(alpha: 0.50),
                        AppColors.surfaceWhite.withValues(alpha: 0.15),
                        AppColors.surfaceWhite.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.20, 0.45, 0.75, 1.0],
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
            Positioned(
              top: -1,
              left: 0,
              right: 0,
              height: 61,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.surfaceWhite,
                        AppColors.surfaceWhite.withValues(alpha: 0.85),
                        AppColors.surfaceWhite.withValues(alpha: 0.50),
                        AppColors.surfaceWhite.withValues(alpha: 0.15),
                        AppColors.surfaceWhite.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.20, 0.45, 0.75, 1.0],
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
  Widget _buildImage(String imageUrl, double heroHeight) {
    // Slight top bleed prevents a sub-pixel gap between cover-fit image and clip edge.
    const topBleed = 2.0;
    final imageHeight = heroHeight + topBleed;

    if (imageUrl.isNotEmpty) {
      return SizedBox(
        height: heroHeight,
        width: double.infinity,
        child: ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: imageHeight,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              placeholder: (context, url) => Container(
                width: double.infinity,
                height: imageHeight,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) =>
                  _buildFallbackImage(heroHeight, topBleed: topBleed),
            ),
          ),
        ),
      );
    } else {
      return _buildFallbackImage(heroHeight, topBleed: topBleed);
    }
  }

  /// Build fallback asset image
  Widget _buildFallbackImage(double heroHeight, {double topBleed = 0}) {
    final imageHeight = heroHeight + topBleed;

    if (topBleed > 0) {
      return SizedBox(
        height: heroHeight,
        width: double.infinity,
        child: ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            child: Image.asset(
              'assets/images/residence_hero.jpeg',
              width: double.infinity,
              height: imageHeight,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: imageHeight,
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
            ),
          ),
        ),
      );
    }

    return Image.asset(
      'assets/images/residence_hero.jpeg',
      width: double.infinity,
      height: heroHeight,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: heroHeight,
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
