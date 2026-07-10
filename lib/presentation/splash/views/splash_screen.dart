// lib/presentation/splash/views/splash_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final logoWidth = (190.w).clamp(140.w, screenSize.width * 0.46);
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
                    _SplashCubeLogo(width: logoWidth),
                    SizedBox(height: 24.h),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 42.sp,
                          color: _textColor,
                          fontFamily: 'Inter',
                          height: 1.0,
                        ),
                        children: [
                          TextSpan(
                            text: 'CASA',
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2.5,
                            ),
                          ),
                          TextSpan(
                            text: 'ZERO',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
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
                    SizedBox(height: 18.h),
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
                    SizedBox(height: 22.h),
                    Text(
                      'La tua casa, sempre con te.',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
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

/// Loads the highest-resolution frame from the ICO for crisp rendering.
class _SplashCubeLogo extends StatefulWidget {
  final double width;

  const _SplashCubeLogo({required this.width});

  @override
  State<_SplashCubeLogo> createState() => _SplashCubeLogoState();
}

class _SplashCubeLogoState extends State<_SplashCubeLogo> {
  static const _icoPath = 'assets/images/casa_zero_ai.ico';
  static const _pngFallbackPath = 'assets/images/thumb_cubo.png';

  ui.Image? _image;
  bool _usePngFallback = false;

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadLogo() async {
    try {
      final data = await rootBundle.load(_icoPath);
      final frame = _largestIcoFrameAsRgba(data.buffer.asUint8List());
      if (!mounted || frame == null) {
        if (mounted) setState(() => _usePngFallback = true);
        return;
      }

      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        frame.rgba,
        frame.width,
        frame.height,
        ui.PixelFormat.rgba8888,
        completer.complete,
      );
      final image = await completer.future;
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    } catch (_) {
      if (mounted) setState(() => _usePngFallback = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_usePngFallback) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final cacheWidth = (widget.width * dpr).round();
      return Image.asset(
        _pngFallbackPath,
        width: widget.width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        cacheWidth: cacheWidth,
        alignment: Alignment.center,
      );
    }

    final image = _image;
    if (image == null) {
      return SizedBox(width: widget.width, height: widget.width);
    }

    final aspectRatio = image.height / image.width;
    return SizedBox(
      width: widget.width,
      height: widget.width * aspectRatio,
      child: RawImage(
        image: image,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        alignment: Alignment.center,
      ),
    );
  }

  ({Uint8List rgba, int width, int height})? _largestIcoFrameAsRgba(
    Uint8List icoBytes,
  ) {
    if (icoBytes.length < 6) return null;

    final header = ByteData.sublistView(icoBytes);
    if (header.getUint16(0, Endian.little) != 0 ||
        header.getUint16(2, Endian.little) != 1) {
      return null;
    }

    final imageCount = header.getUint16(4, Endian.little);
    var bestArea = 0;
    var bestOffset = 0;
    var bestSize = 0;

    for (var i = 0; i < imageCount; i++) {
      final entryOffset = 6 + (i * 16);
      if (entryOffset + 16 > icoBytes.length) return null;

      final width = icoBytes[entryOffset] == 0 ? 256 : icoBytes[entryOffset];
      final height =
          icoBytes[entryOffset + 1] == 0 ? 256 : icoBytes[entryOffset + 1];
      final dataSize = header.getUint32(entryOffset + 8, Endian.little);
      final dataOffset = header.getUint32(entryOffset + 12, Endian.little);
      final area = width * height;

      if (area > bestArea) {
        bestArea = area;
        bestOffset = dataOffset;
        bestSize = dataSize;
      }
    }

    if (bestSize == 0 || bestOffset + bestSize > icoBytes.length) {
      return null;
    }

    return _icoDibToRgba(icoBytes.sublist(bestOffset, bestOffset + bestSize));
  }

  ({Uint8List rgba, int width, int height})? _icoDibToRgba(Uint8List dib) {
    if (dib.length < 40) return null;

    final dibHeader = ByteData.sublistView(dib);
    final headerSize = dibHeader.getUint32(0, Endian.little);
    if (headerSize < 40 || dib.length < headerSize) return null;

    final width = dibHeader.getInt32(4, Endian.little);
    final storedHeight = dibHeader.getInt32(8, Endian.little);
    if (width <= 0 || storedHeight <= 0) return null;

    final height = storedHeight ~/ 2;
    final bitCount = dibHeader.getUint16(14, Endian.little);
    if (bitCount != 32) return null;

    final rowSize = width * 4;
    final xorSize = rowSize * height;
    if (headerSize + xorSize > dib.length) return null;

    final andRowSize = ((width + 31) ~/ 32) * 4;
    final andOffset = headerSize + xorSize;
    final hasAndMask = andOffset + (andRowSize * height) <= dib.length;

    final rgba = Uint8List(width * height * 4);

    for (var y = 0; y < height; y++) {
      final srcRow = height - 1 - y;
      final srcRowOffset = headerSize + (srcRow * rowSize);
      final andRowOffset = andOffset + (srcRow * andRowSize);

      for (var x = 0; x < width; x++) {
        final srcPixel = srcRowOffset + (x * 4);
        final blue = dib[srcPixel];
        final green = dib[srcPixel + 1];
        final red = dib[srcPixel + 2];
        var alpha = dib[srcPixel + 3];

        if (hasAndMask) {
          final andByte = dib[andRowOffset + (x ~/ 8)];
          final andBit = (andByte >> (7 - (x % 8))) & 1;
          if (andBit == 1) alpha = 0;
        }

        final dst = (y * width + x) * 4;
        rgba[dst] = red;
        rgba[dst + 1] = green;
        rgba[dst + 2] = blue;
        rgba[dst + 3] = alpha;
      }
    }

    return (rgba: rgba, width: width, height: height);
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
    final strokeWidth = (base / 390).clamp(0.95, 1.25);

    final strokePaint = Paint()
      ..color = _strokeColor.withValues(alpha: 0.38)
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
