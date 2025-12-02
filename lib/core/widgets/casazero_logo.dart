import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CasaZeroLogo extends StatelessWidget {
  final String assetPath;

  /// optional max logo width (relative to screen)
  final double maxLogoWidthFactor; // 0.5 = 50% of screen width

  /// optional max container height
  final double containerHeight;

  const CasaZeroLogo({
    super.key,
    required this.assetPath,
    this.maxLogoWidthFactor = 0.6, // default: logo uses 60% of screen width
    this.containerHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final logoWidth = screenWidth;// * maxLogoWidthFactor;

    return Column(
      children: [
        Container(
          width: screenWidth,            // ⬅ FULL WIDTH RESPONSIVE
          height: containerHeight,
          alignment: Alignment.center,
          child: Image.asset(
            assetPath,
            width: 500,            // ⬅ scales based on screen size
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'smart_living'.tr,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
