// lib/presentation/demo/widgets/demo_button.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../controllers/demo_controller.dart';

/// Pixel-perfect Demo button for top-right of Home (Figma).
/// White background, rounded corners, border, shadow, gear icon + "Demo" label.
class DemoButton extends GetView<DemoController> {
  const DemoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: controller.togglePanel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.brandSage300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 18,
              color: AppColors.neutralInk700,
            ),
            const SizedBox(width: 8),
            Text(
              'demo'.tr,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.neutralInk900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
