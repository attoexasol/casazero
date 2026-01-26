import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CasaZeroLogo extends StatelessWidget {
  final String assetPath;
  final bool showTagline; // new parameter

  /// optional max logo width (relative to screen)
  final double maxLogoWidthFactor; // 0.5 = 50% of screen width

  /// optional max container height
  final double containerHeight;

  const CasaZeroLogo({
    super.key,
    required this.assetPath,
    this.maxLogoWidthFactor = 0.6, // default: logo uses 60% of screen width
    this.containerHeight = 120, // Increased from 100 to 120 for more prominence
    this.showTagline = true, // default: show the text
  });

  /// Check if asset is SVG
  bool get _isSvg => assetPath.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final logoWidth = screenWidth; // * maxLogoWidthFactor;

    return Column(
      mainAxisSize: MainAxisSize.min, // Prevent overflow by using min size
      children: [
        Container(
          width: screenWidth * 0.9, // Reduced container width to 90% of screen
          height: containerHeight,
          alignment: Alignment.center,
          color: Colors.transparent, // Explicitly transparent - no background
          child: _isSvg
              ? Builder(
                  builder: (context) {
                    try {
                      // SVG aspect ratio is approximately 307:56 (5.5:1)
                      // Calculate height based on width to maintain aspect ratio
                      final logoWidth = 360.0;
                      final logoHeight =
                          logoWidth *
                          (56 / 307); // Maintain SVG aspect ratio (~100px)

                      print('🖼️ [CasaZeroLogo] Loading SVG: $assetPath');
                      print(
                        '🖼️ [CasaZeroLogo] Logo dimensions: ${logoWidth}x$logoHeight',
                      );

                      return SizedBox(
                        width: logoWidth,
                        height: logoHeight,
                        child: SvgPicture.asset(
                          assetPath,
                          width: logoWidth,
                          height: logoHeight,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          placeholderBuilder: (context) {
                            print('⏳ [CasaZeroLogo] SVG loading...');
                            return Container(
                              width: logoWidth,
                              height: logoHeight,
                              color: Colors.transparent,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          semanticsLabel: 'CasaZero Logo',
                        ),
                      );
                    } catch (e, stackTrace) {
                      print('❌ [CasaZeroLogo] Error loading SVG logo: $e');
                      print('📚 [CasaZeroLogo] Stack trace: $stackTrace');
                      // Fallback: Show a placeholder or text
                      return Container(
                        width: 360,
                        height: containerHeight * 0.8,
                        alignment: Alignment.center,
                        child: const Text(
                          'CasaZero',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }
                  },
                )
              : Image.asset(
                  assetPath,
                  width: 360, // Reduced logo size
                  height:
                      containerHeight * 0.8, // Add height constraint for PNG
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ [CasaZeroLogo] Error loading image: $error');
                    return Container(
                      width: 360,
                      height: containerHeight * 0.8,
                      alignment: Alignment.center,
                      child: const Text(
                        'CasaZero',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        if (showTagline)
          Text(
            'smart_living'.tr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15, // Slightly increased from 14 to 15
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500, // Added slight weight for prominence
            ),
          ),
      ],
    );
  }
}
