// lib/presentation/splash/views/splash_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  static const _backgroundColor = Color(0xFFFAF7F4);
  static const _textColor = Color(0xFF4D4D4D);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final logoWidth = (180.w).clamp(130.w, screenSize.width * 0.44);
    final dividerWidth = (150.w).clamp(120.w, screenSize.width * 0.42);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            painter: _SplashBackgroundPainter(),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/casa_zero_ai.ico',
                      width: logoWidth,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      alignment: Alignment.center,
                    ),
                    SizedBox(height: 22.h),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 38.sp,
                          color: _textColor,
                          fontFamily: 'Inter',
                          height: 1.05,
                        ),
                        children: [
                          TextSpan(
                            text: 'CASA',
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              letterSpacing: 9.sp,
                            ),
                          ),
                          TextSpan(
                            text: 'ZERO',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5.sp,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      width: dividerWidth,
                      height: 3.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1.5.r),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFE53935),
                            Color(0xFFFFB300),
                            Color(0xFF43A047),
                            Color(0xFF8E24AA),
                          ],
                          stops: [0.0, 0.33, 0.66, 1.0],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'La tua casa, sempre con te.',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.2.sp,
                        height: 1.35,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  const _SplashBackgroundPainter();

  static const _backgroundColor = Color(0xFFFAF7F4);
  static const _strokeColor = Color(0xFFD7CEC6);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _backgroundColor,
    );

    final base = math.min(size.width, size.height);
    final strokeWidth = (base / 390).clamp(0.85, 1.1);

    final strokePaint = Paint()
      ..color = _strokeColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    const cubes = <_CubePlacement>[
      // Large partial cube — top-left
      _CubePlacement(x: -0.07, y: 0.08, sizeFactor: 0.52),
      // Large partial cube — top-right
      _CubePlacement(x: 1.05, y: 0.06, sizeFactor: 0.48),
      // Small cube — upper-left (kept away from center)
      _CubePlacement(x: 0.12, y: 0.16, sizeFactor: 0.13),
      // Small cube — lower-left
      _CubePlacement(x: 0.09, y: 0.69, sizeFactor: 0.12),
      // Large partial cube — bottom-left
      _CubePlacement(x: -0.11, y: 0.91, sizeFactor: 0.45),
      // Tall partial cube — bottom-right
      _CubePlacement(x: 1.07, y: 0.61, sizeFactor: 0.36, heightScale: 1.4),
      // Small cube — bottom-right
      _CubePlacement(x: 0.91, y: 0.85, sizeFactor: 0.13),
    ];

    for (final cube in cubes) {
      final center = Offset(cube.x * size.width, cube.y * size.height);
      final side = base * cube.sizeFactor;
      canvas.drawPath(
        _buildIsometricCubeOutline(
          center,
          side,
          heightScale: cube.heightScale,
        ),
        strokePaint,
      );
    }
  }

  static Path _buildIsometricCubeOutline(
    Offset center,
    double side, {
    double heightScale = 1.0,
  }) {
    final halfWidth = side / 2;
    final halfDepth = side / 4;
    final height = side * heightScale;

    final topFaceCenter = Offset(center.dx, center.dy - height / 2);
    final bottomFaceCenter = Offset(center.dx, center.dy + height / 2);

    final path = Path();

    _addDiamond(path, topFaceCenter, halfWidth, halfDepth);
    _addDiamond(path, bottomFaceCenter, halfWidth, halfDepth);

    _connectVerticalEdge(
      path,
      topFaceCenter,
      bottomFaceCenter,
      halfWidth,
      halfDepth,
      _VerticalCorner.top,
    );
    _connectVerticalEdge(
      path,
      topFaceCenter,
      bottomFaceCenter,
      halfWidth,
      halfDepth,
      _VerticalCorner.right,
    );
    _connectVerticalEdge(
      path,
      topFaceCenter,
      bottomFaceCenter,
      halfWidth,
      halfDepth,
      _VerticalCorner.bottom,
    );
    _connectVerticalEdge(
      path,
      topFaceCenter,
      bottomFaceCenter,
      halfWidth,
      halfDepth,
      _VerticalCorner.left,
    );

    return path;
  }

  static void _addDiamond(
    Path path,
    Offset center,
    double halfWidth,
    double halfDepth,
  ) {
    path.moveTo(center.dx, center.dy - halfDepth);
    path.lineTo(center.dx + halfWidth, center.dy);
    path.lineTo(center.dx, center.dy + halfDepth);
    path.lineTo(center.dx - halfWidth, center.dy);
    path.close();
  }

  static void _connectVerticalEdge(
    Path path,
    Offset topCenter,
    Offset bottomCenter,
    double halfWidth,
    double halfDepth,
    _VerticalCorner corner,
  ) {
    final top = switch (corner) {
      _VerticalCorner.top => Offset(topCenter.dx, topCenter.dy - halfDepth),
      _VerticalCorner.right => Offset(topCenter.dx + halfWidth, topCenter.dy),
      _VerticalCorner.bottom => Offset(topCenter.dx, topCenter.dy + halfDepth),
      _VerticalCorner.left => Offset(topCenter.dx - halfWidth, topCenter.dy),
    };
    final bottom = switch (corner) {
      _VerticalCorner.top =>
        Offset(bottomCenter.dx, bottomCenter.dy - halfDepth),
      _VerticalCorner.right =>
        Offset(bottomCenter.dx + halfWidth, bottomCenter.dy),
      _VerticalCorner.bottom =>
        Offset(bottomCenter.dx, bottomCenter.dy + halfDepth),
      _VerticalCorner.left =>
        Offset(bottomCenter.dx - halfWidth, bottomCenter.dy),
    };

    path.moveTo(top.dx, top.dy);
    path.lineTo(bottom.dx, bottom.dy);
  }

  @override
  bool shouldRepaint(covariant _SplashBackgroundPainter oldDelegate) => false;
}

enum _VerticalCorner { top, right, bottom, left }

class _CubePlacement {
  final double x;
  final double y;
  final double sizeFactor;
  final double heightScale;

  const _CubePlacement({
    required this.x,
    required this.y,
    required this.sizeFactor,
    this.heightScale = 1.0,
  });
}
