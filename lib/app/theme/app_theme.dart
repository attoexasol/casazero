import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: AppColors.brandSage500,
      onPrimary: AppColors.surfaceWhite,
      secondary: AppColors.brandSage300,
      onSecondary: AppColors.neutralInk900,
      error: AppColors.danger,
      onError: AppColors.surfaceWhite,
      surface: AppColors.surfaceWarm50,
      onSurface: AppColors.neutralInk900,
      outline: AppColors.neutralLine200,
    ),

    // Scaffold
    scaffoldBackgroundColor: AppColors.surfaceWarm50,

    // App Bar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceWhite,
      foregroundColor: AppColors.neutralInk900,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.neutralInk900,
        fontFamily: AppTextStyles.fontFamily,
      ),
    ),

    // Card
    cardTheme: CardThemeData(
      color: AppColors.surfaceWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.neutralLine100),
      ),
      shadowColor: Colors.black.withOpacity(0.04),
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.h1,
      displayMedium: AppTextStyles.h2,
      displaySmall: AppTextStyles.h3,
      headlineMedium: AppTextStyles.h4,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.label,
      labelMedium: AppTextStyles.caption,
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.neutralInk700,
      size: 24,
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandSage500,
        foregroundColor: AppColors.surfaceWhite,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: AppTextStyles.button,
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brandSage500,
        textStyle: AppTextStyles.button,
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandSage500,
        side: const BorderSide(color: AppColors.brandSage500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: AppTextStyles.button,
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceWhite.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.surfaceWhite.withOpacity(0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.brandSage500,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.danger,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.danger,
          width: 2,
        ),
      ),
      hintStyle: TextStyle(
        color: AppColors.neutralInk400,
        fontSize: 16,
      ),
      labelStyle: const TextStyle(
        color: AppColors.neutralInk700,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.brandSage500,
      foregroundColor: AppColors.surfaceWhite,
      elevation: 4,
      shape: CircleBorder(),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.brandSage100,
      labelStyle: const TextStyle(
        color: AppColors.brandSage800,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceWhite,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: AppTextStyles.h4,
    ),

    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.neutralInk900,
      contentTextStyle: const TextStyle(
        color: AppColors.surfaceWhite,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceWhite,
      selectedItemColor: AppColors.brandSage500,
      unselectedItemColor: AppColors.neutralInk400,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.neutralLine200,
      thickness: 1,
      space: 1,
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brandSage500,
      linearTrackColor: AppColors.neutralLine100,
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.surfaceWhite;
        }
        return AppColors.neutralInk300;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.brandSage500;
        }
        return AppColors.neutralLine200;
      }),
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.brandSage500;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.surfaceWhite),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    // Radio Theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.brandSage500;
        }
        return AppColors.neutralInk400;
      }),
    ),

    // Font Family
    fontFamily: AppTextStyles.fontFamily,
  );

  // Dark Theme (Optional)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: ColorScheme.dark(
      primary: AppColors.brandSage500,
      onPrimary: AppColors.neutralInk900,
      secondary: AppColors.brandSage300,
      onSecondary: AppColors.surfaceWhite,
      error: AppColors.danger,
      onError: AppColors.surfaceWhite,
      surface: AppColors.neutralInk900,
      onSurface: AppColors.surfaceWhite,
      outline: AppColors.neutralInk700,
    ),

    scaffoldBackgroundColor: AppColors.neutralInk900,

    // Rest of dark theme configuration...
    fontFamily: AppTextStyles.fontFamily,
  );
}