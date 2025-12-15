import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum BadgeType { success, warning, danger, info, neutral }

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeType type;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusBadge({
    super.key,
    required this.text,
    this.type = BadgeType.neutral,
    this.fontSize,
    this.padding,
  });

  Color get _backgroundColor {
    switch (type) {
      case BadgeType.success:
        return AppColors.success.withOpacity(0.1);
      case BadgeType.warning:
        return AppColors.warning.withOpacity(0.1);
      case BadgeType.danger:
        return AppColors.danger.withOpacity(0.1);
      case BadgeType.info:
        return AppColors.info.withOpacity(0.1);
      case BadgeType.neutral:
        return AppColors.neutralLine100;
    }
  }

  Color get _textColor {
    switch (type) {
      case BadgeType.success:
        return AppColors.success;
      case BadgeType.warning:
        return AppColors.warning;
      case BadgeType.danger:
        return AppColors.danger;
      case BadgeType.info:
        return AppColors.info;
      case BadgeType.neutral:
        return AppColors.neutralInk700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _textColor,
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}