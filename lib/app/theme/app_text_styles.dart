import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

/// Typography tokens for the 390×844 design baseline ([ScreenUtilInit] in main.dart).
///
/// Styles are exposed as getters so [fontSize] and [letterSpacing] scale via `.sp`
/// while weights, colors, line heights, and font family stay unchanged.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Inter';

  // Design-token sizes (logical px at 390pt width).
  static const double _h1Size = 32;
  static const double _h2Size = 28;
  static const double _h3Size = 24;
  static const double _h4Size = 20;
  static const double _cardHeaderSize = 16;
  static const double _bodyLargeSize = 18;
  static const double _bodyMediumSize = 14;
  static const double _bodySmallSize = 11;
  static const double _labelSize = 16;
  static const double _buttonSize = 16;
  static const double _captionSize = 12;

  static TextStyle _style({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontSize: fontSize.sp,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing == 0 ? 0 : letterSpacing.sp,
      color: color,
      fontFamily: fontFamily,
    );
  }

  // Headings
  static TextStyle get h1 => _style(
        fontSize: _h1Size,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: -0.64,
        color: AppColors.regulerTextColor,
      );

  static TextStyle get h2 => _style(
        fontSize: _h2Size,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: -0.28,
        color: AppColors.regulerTextColor,
      );

  static TextStyle get h3 => _style(
        fontSize: _h3Size,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.regulerTextColor,
      );

  static TextStyle get h4 => _style(
        fontSize: _h4Size,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.regulerTextColor,
      );

  static TextStyle get CardHeaderText => _style(
        fontSize: _cardHeaderSize,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.regulerTextColor,
      );

  // Body Text
  static TextStyle get bodyLarge => _style(
        fontSize: _bodyLargeSize,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.regulerTextColor,
      );

  static TextStyle get bodyMedium => _style(
        fontSize: _bodyMediumSize,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: AppColors.grayTextColor,
      );

  static TextStyle get cardText => _style(
        fontSize: _bodyMediumSize,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: AppColors.regulerTextColor,
      );

  static TextStyle get cardSecondText => _style(
        fontSize: _bodyMediumSize,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: AppColors.grayTextColor,
      );

  static TextStyle get bodySmall => _style(
        fontSize: _bodySmallSize,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: AppColors.regulerTextColor,
      );

  // Labels & Buttons
  static TextStyle get label => _style(
        fontSize: _labelSize,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.regulerTextColor,
      );

  static TextStyle get button => _style(
        fontSize: _buttonSize,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.surfaceWhite,
      );

  static TextStyle get caption => _style(
        fontSize: _captionSize,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.neutralInk500,
      );

  // Theme-level typography (used by [AppTheme]).
  static TextStyle get appBarTitle => _style(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.neutralInk900,
      );

  static TextStyle get inputHint => _style(
        fontSize: _labelSize,
        fontWeight: FontWeight.w400,
        color: AppColors.neutralInk400,
      );

  static TextStyle get inputLabel => _style(
        fontSize: _labelSize,
        fontWeight: FontWeight.w500,
        color: AppColors.neutralInk700,
      );

  static TextStyle get chipLabel => _style(
        fontSize: _bodyMediumSize,
        fontWeight: FontWeight.w500,
        color: AppColors.brandSage800,
      );

  static TextStyle get snackBarContent => _style(
        fontSize: _bodyMediumSize,
        fontWeight: FontWeight.w400,
        color: AppColors.surfaceWhite,
      );

  static TextStyle get bottomNavSelected => TextStyle(
        fontSize: _captionSize.sp,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
      );

  static TextStyle get bottomNavUnselected => TextStyle(
        fontSize: _captionSize.sp,
        fontWeight: FontWeight.w400,
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
