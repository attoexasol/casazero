import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class TextCustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? textColor;
  final IconData? icon;

  const TextCustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.textColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? AppColors.brandSage500;

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: effectiveTextColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }
}