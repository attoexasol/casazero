import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String fontFamily = 'Inter';

  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.64, // -0.02em
    color: AppColors.regulerTextColor,
    fontFamily: fontFamily,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.28, // -0.01em
    color: AppColors.regulerTextColor,
    fontFamily: fontFamily,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.regulerTextColor,
    fontFamily: fontFamily,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.regulerTextColor,
    fontFamily: fontFamily,
    letterSpacing: 0,
  );

  static const TextStyle CardHeaderText = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
    color: AppColors.regulerTextColor,
    fontFamily: fontFamily,
    letterSpacing: 0,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.regulerTextColor,
    fontFamily: fontFamily,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.grayTextColor,
    fontFamily: fontFamily,
    letterSpacing: 0,
  );

  static const TextStyle cardText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.regulerTextColor,
    fontFamily: fontFamily,
    letterSpacing: 0,
  );

  static const TextStyle cardSecondText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.grayTextColor,
    fontFamily: fontFamily,
    letterSpacing: 0,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    //height: 1.6,
    color: AppColors.regulerTextColor,
    fontFamily: fontFamily,
    height: 20 / 14, // Line height = 1.428
    letterSpacing: 0,
  );

  // Labels & Buttons
  static const TextStyle label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.regulerTextColor,
    fontFamily: fontFamily,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.surfaceWhite,
    fontFamily: fontFamily,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.neutralInk500,
    fontFamily: fontFamily,
  );

  // Utilities
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
}
