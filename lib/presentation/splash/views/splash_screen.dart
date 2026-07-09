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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/casa_zero_ai.ico',
                    width: 180.w,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 24.h),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 38.sp,
                        color: _textColor,
                        fontFamily: 'Inter',
                        height: 1.0,
                      ),
                      children: [
                        TextSpan(
                          text: 'CASA',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            letterSpacing: 8.sp,
                          ),
                        ),
                        TextSpan(
                          text: 'ZERO',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Container(
                    width: 150.w,
                    height: 3.h,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFE53935),
                          Color(0xFFFFB300),
                          Color(0xFF43A047),
                          Color(0xFF8E24AA),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    'La tua casa, sempre con te.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
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

    final strokePaint = Paint()
      ..color = _strokeColor.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final base = math.min(size.width, size.height);

    const cubes = <_CubePlacement>[
      // Large partial cube — top-left
      _CubePlacement(x: -0.06, y: 0.09, sizeFactor: 0.54),
      // Large partial cube — top-right
      _CubePlacement(x: 1.04, y: 0.07, sizeFactor: 0.50),
      // Small cube — upper-left
      _CubePlacement(x: 0.15, y: 0.19, sizeFactor: 0.14),
      // Small cube — lower-left
      _CubePlacement(x: 0.11, y: 0.67, sizeFactor: 0.13),
      // Large partial cube — bottom-left
      _CubePlacement(x: -0.10, y: 0.90, sizeFactor: 0.47),
      // Tall partial cube — bottom-right
      _CubePlacement(x: 1.06, y: 0.60, sizeFactor: 0.37, heightScale: 1.4),
      // Small cube — bottom-right
      _CubePlacement(x: 0.89, y: 0.83, sizeFactor: 0.14),
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
