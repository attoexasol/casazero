import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_gradients.dart';
import '../../app/theme/app_shadows.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Gradient? gradient;
  final Color? textColor;
  final double? width;
  final double height;
  final IconData? icon;
  final double borderRadius;

  const GradientButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.textColor,
    this.width,
    this.height = 48,
    this.icon,
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.premiumGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppShadows.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
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
              children: [
                Icon(icon, size: 18, color: textColor ?? AppColors.surfaceWhite),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? AppColors.surfaceWhite,
                  ),
                ),
              ],
            )
                : Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor ?? AppColors.surfaceWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}