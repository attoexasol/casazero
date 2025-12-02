import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_shadows.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final IconData? icon;
  final double borderRadius;
  final bool showShadow;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.icon,
    this.borderRadius = 12,
    this.showShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: showShadow
          ? BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppShadows.shadowMd,
      )
          : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.brandSage500,
          foregroundColor: textColor ?? AppColors.surfaceWhite,
          disabledBackgroundColor: AppColors.neutralInk300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: icon != null ? 20 : 24,
            vertical: 0,
          ),
        ),
        child: isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              textColor ?? AppColors.surfaceWhite,
            ),
          ),
        )
            : icon != null
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: AppTextStyles.button.copyWith(
                color: textColor ?? AppColors.surfaceWhite,
              ),
            ),
          ],
        )
            : Text(
          text,
          style: AppTextStyles.button.copyWith(
            color: textColor ?? AppColors.surfaceWhite,
          ),
        ),
      ),
    );
  }
}