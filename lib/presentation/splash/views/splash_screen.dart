// lib/presentation/splash/views/splash_screen.dart
// Premium splash screen matching React design with constellation effects

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../app/theme/app_colors.dart';
import '../controllers/splash_controller.dart';

/// Design-proportional layout values (reference: 390×844 via ScreenUtil).
class _SplashMetrics {
  final double screenWidth;

  const _SplashMetrics._(this.screenWidth);

  factory _SplashMetrics.of(BuildContext context) {
    return _SplashMetrics._(MediaQuery.sizeOf(context).width);
  }

  double get logoSize => 320.w.clamp(0.0, screenWidth * 0.85);

  double get innerGlowSize => 400.w.clamp(0.0, screenWidth);

  double get centralOrbSize => 384.w.clamp(0.0, screenWidth);

  double get particleBaseRadius => 200.w;

  double get particleRadiusVariance => 100.w;

  double get particleDotSize => 4.w.clamp(2.w, 4.w);

  double get brandNameBottom => 128.h;

  double get loadingBottom => 64.h;

  double get gradientLineWidth => 200.w.clamp(0.0, screenWidth * 0.65);
}

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated gradient background
          const _AnimatedGradientBackground(),

          // Constellation particle effect
          const _ConstellationParticles(),

          // Central glowing orb
          const _CentralGlowOrb(),

          // Logo with animations
          const Center(child: _AnimatedLogo()),

          // Brand name text
          const _BrandNameText(),

          // Loading indicator
          const _LoadingIndicator(),
        ],
      ),
    );
  }
}

// Animated gradient background with pulsing effect
class _AnimatedGradientBackground extends StatefulWidget {
  const _AnimatedGradientBackground();

  @override
  State<_AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<_AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.white.withOpacity(
                  0.15 * (0.5 + _controller.value * 0.5),
                ),
                Colors.black,
              ],
              stops: const [0.0, 0.7],
            ),
          ),
        );
      },
    );
  }
}

// Constellation particles spreading from center
class _ConstellationParticles extends StatelessWidget {
  const _ConstellationParticles();

  @override
  Widget build(BuildContext context) {
    final metrics = _SplashMetrics.of(context);
    final particles = List.generate(30, (index) {
      final angle = (index / 30) * math.pi * 2;
      final radius = metrics.particleBaseRadius +
          math.Random(index).nextDouble() * metrics.particleRadiusVariance;
      return _ConstellationParticle(
        angle: angle,
        radius: radius,
        dotSize: metrics.particleDotSize,
        delay: Duration(
          milliseconds: (math.Random(index).nextDouble() * 500).toInt(),
        ),
        scale: 0.5 + math.Random(index).nextDouble() * 0.5,
      );
    });

    return Stack(children: particles);
  }
}

class _ConstellationParticle extends StatelessWidget {
  final double angle;
  final double radius;
  final double dotSize;
  final Duration delay;
  final double scale;

  const _ConstellationParticle({
    required this.angle,
    required this.radius,
    required this.dotSize,
    required this.delay,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final centerX = MediaQuery.of(context).size.width / 2;
    final centerY = MediaQuery.of(context).size.height / 2;

    return Positioned(
      left: centerX,
      top: centerY,
      child:
          Container(
            width: dotSize,
            height: dotSize,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ).animate().custom(
            duration: 1200.ms,
            delay: delay,
            curve: const Cubic(0.34, 1.56, 0.64, 1),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(
                  math.cos(angle) * radius * value,
                  math.sin(angle) * radius * value,
                ),
                child: Transform.scale(
                  scale: scale * value,
                  child: Opacity(
                    opacity: value < 0.5
                        ? value * 2
                        : 1.0 - (value - 0.5) * 0.8,
                    child: child,
                  ),
                ),
              );
            },
          ),
    );
  }
}

// Central glowing orb with pulsing animation
class _CentralGlowOrb extends StatefulWidget {
  const _CentralGlowOrb();

  @override
  State<_CentralGlowOrb> createState() => _CentralGlowOrbState();
}

class _CentralGlowOrbState extends State<_CentralGlowOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orbSize = _SplashMetrics.of(context).centralOrbSize;

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scaleValue = 1.0 + (_controller.value * 0.2);
          final opacityValue = 0.3 + (_controller.value * 0.2);

          return Transform.scale(
            scale: scaleValue,
            child: Container(
              width: orbSize,
              height: orbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(opacityValue),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated logo with 3D rotation and glow effects
class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo();

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    // Breathing animation
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    // Glow ring animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _SplashMetrics.of(context);
    final innerGlowSize = metrics.innerGlowSize;
    final logoSize = metrics.logoSize;

    return Stack(
          alignment: Alignment.center,
          children: [
            // Inner glow ring
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final scaleValue = 1.0 + (_glowController.value * 0.15);
                final opacityValue = 0.5 + (_glowController.value * 0.3);

                return Transform.scale(
                  scale: scaleValue,
                  child: Container(
                    width: innerGlowSize,
                    height: innerGlowSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(opacityValue),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Logo with breathing animation
            AnimatedBuilder(
              animation: _breathingController,
              builder: (context, child) {
                final scaleValue = 1.0 + (_breathingController.value * 0.03);

                return Transform.scale(
                  scale: scaleValue,
                  child: Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/images/white_logo.png'),
                        fit: BoxFit.contain,
                      ),
                      // boxShadow: [
                      //   BoxShadow(
                      //     color: Colors.white.withOpacity(0.5),
                      //     blurRadius: 30,
                      //     spreadRadius: 0,
                      //   ),
                      //],
                    ),
                  ),
                );
              },
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 100.ms, delay: 500.ms)
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1.0, 1.0),
          duration: 2500.ms,
          delay: 500.ms,
          curve: const Cubic(0.16, 1, 0.3, 1),
        )
        .custom(
          duration: 2500.ms,
          delay: 500.ms,
          curve: const Cubic(0.16, 1, 0.3, 1),
          builder: (context, value, child) {
            // 3D rotation effect (rotateY from -360 to 0)
            final rotationY = (-360 + (360 * value)) * (math.pi / 180);
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(rotationY),
              alignment: Alignment.center,
              child: child,
            );
          },
        );
  }
}

// Brand name text with gradient line
class _BrandNameText extends StatelessWidget {
  const _BrandNameText();

  @override
  Widget build(BuildContext context) {
    final metrics = _SplashMetrics.of(context);

    return Positioned(
      bottom: metrics.brandNameBottom,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
                'CASAZERO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  letterSpacing: 7.2.sp,
                  fontWeight: FontWeight.w300,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(duration: 800.ms, delay: 1500.ms)
              .slideY(begin: 0.3, end: 0, duration: 800.ms, delay: 1500.ms),
          SizedBox(height: 16.h),
          Container(
            height: 1.h,
            width: metrics.gradientLineWidth,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.white, Colors.transparent],
              ),
            ),
          ).animate().scaleX(
            begin: 0,
            end: 1.0,
            duration: 800.ms,
            delay: 1800.ms,
            curve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

// Premium loading indicator with sequential dots
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final loadingBottom = _SplashMetrics.of(context).loadingBottom;

    return Positioned(
      bottom: loadingBottom,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          4,
          (index) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: _LoadingDot(index: index),
          ),
        ),
      ).animate().fadeIn(duration: 600.ms, delay: 2000.ms),
    );
  }
}

class _LoadingDot extends StatefulWidget {
  final int index;

  const _LoadingDot({required this.index});

  @override
  State<_LoadingDot> createState() => _LoadingDotState();
}

class _LoadingDotState extends State<_LoadingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotBaseSize = 8.w;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = (_controller.value - (widget.index * 0.15)) % 1.0;
        final opacity = progress < 0.5
            ? 0.3 + (progress * 1.4)
            : 1.0 - ((progress - 0.5) * 1.4);
        final scale = progress < 0.5
            ? 1.0 + (progress * 0.8)
            : 1.4 - ((progress - 0.5) * 0.8);
        final dotSize = dotBaseSize * scale;

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(opacity.clamp(0.0, 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(opacity.clamp(0.0, 0.3)),
                    blurRadius: 8.r,
                    spreadRadius: 2.r,
                  ),
                ],
              ),
            ),
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(opacity.clamp(0.3, 1.0)),
              ),
            ),
          ],
        );
      },
    );
  }
}
