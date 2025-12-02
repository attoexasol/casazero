import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_gradients.dart';
import '../../app/theme/app_shadows.dart';

class PremiumIconContainer extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? iconColor;
  final Gradient? gradient;
  final double borderRadius;
  final bool showShadow;

  const PremiumIconContainer({
    Key? key,
    required this.icon,
    this.size = 48,
    this.iconColor,
    this.gradient,
    this.borderRadius = 12,
    this.showShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.premiumGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? AppShadows.customColoredShadow(
          AppColors.brandSage500,
          opacity: 0.3,
        )
            : null,
      ),
      child: Icon(
        icon,
        color: iconColor ?? AppColors.surfaceWhite,
        size: size * 0.5,
      ),
    );
  }
}
