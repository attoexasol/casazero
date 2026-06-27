import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CasaZeroLogo extends StatelessWidget {
  final String assetPath;
  final bool showTagline;

  /// optional max logo width (relative to screen)
  final double maxLogoWidthFactor;

  /// optional max container height
  final double containerHeight;

  const CasaZeroLogo({
    super.key,
    required this.assetPath,
    this.maxLogoWidthFactor = 0.6,
    this.containerHeight = 120,
    this.showTagline = true,
  });

  bool get _isSvg => assetPath.toLowerCase().endsWith('.svg');

  static const double _svgAspectRatio = 56 / 307;

  double _resolveLogoWidth(double screenWidth) {
    const designScreenWidth = 390.0;
    const designLogoWidth = 360.0;
    const defaultFactor = 0.6;

    final containerMaxWidth = screenWidth * 0.9;
    final logoWidth = designLogoWidth *
        (screenWidth / designScreenWidth) *
        (maxLogoWidthFactor / defaultFactor);

    if (screenWidth < 360) {
      return logoWidth.clamp(0.0, containerMaxWidth);
    }

    return logoWidth;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoWidth = _resolveLogoWidth(screenWidth);
    final logoHeight = logoWidth * _svgAspectRatio;
    final resolvedContainerHeight = containerHeight.h;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: screenWidth * 0.9,
          height: resolvedContainerHeight,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: _isSvg
              ? Builder(
                  builder: (context) {
                    try {
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
                              child: Center(
                                child: SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.w,
                                  ),
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
                      return Container(
                        width: logoWidth,
                        height: resolvedContainerHeight * 0.8,
                        alignment: Alignment.center,
                        child: Text(
                          'CasaZero',
                          style: TextStyle(
                            fontSize: 32.sp,
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
                  width: logoWidth,
                  height: resolvedContainerHeight * 0.8,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ [CasaZeroLogo] Error loading image: $error');
                    return Container(
                      width: logoWidth,
                      height: resolvedContainerHeight * 0.8,
                      alignment: Alignment.center,
                      child: Text(
                        'CasaZero',
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
        ),
        SizedBox(height: 12.h),
        if (showTagline)
          Text(
            'smart_living'.tr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15.sp,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
