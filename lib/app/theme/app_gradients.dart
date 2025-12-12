import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandSage500, AppColors.brandSage400],
  );

  static const LinearGradient premiumGradientGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentGold500, AppColors.accentGold300],
  );

  static const LinearGradient aquaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.aquaGreen600, AppColors.aquaGreen400],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
    colors: [
      AppColors.brandSage500,
      AppColors.accentLime500,
      AppColors.brandSage500,
    ],
  );

  static LinearGradient glassOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.6)],
  );
}
