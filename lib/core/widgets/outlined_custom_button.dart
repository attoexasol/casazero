import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class OutlinedCustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? borderColor;
  final Color? textColor;
  final double? width;
  final double height;
  final IconData? icon;
  final double borderRadius;

  const OutlinedCustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.borderColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.icon,
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppColors.brandSage500;
    final effectiveTextColor = textColor ?? AppColors.brandSage500;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveTextColor,
          side: BorderSide(
            color: effectiveBorderColor,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
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
            valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
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
                color: effectiveTextColor,
              ),
            ),
          ],
        )
            : Text(
          text,
          style: AppTextStyles.button.copyWith(
            color: effectiveTextColor,
          ),
        ),
      ),
    );
  }
}
