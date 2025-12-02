import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_gradients.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_text_styles.dart';

class ViewAllBuildingsCard extends StatelessWidget {
  final VoidCallback onTap;

  const ViewAllBuildingsCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24, left: 24, right: 24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.shadowLg,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppGradients.premiumGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.customColoredShadow(
                    AppColors.brandSage500,
                    opacity: 0.3,
                  ),
                ),
                child: const Icon(Icons.business,
                    color: AppColors.surfaceWhite),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('building'.tr,
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.bold)),
                    Text('view_all_buildings'.tr,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.neutralInk500)),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentLime500,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.customColoredShadow(
                    AppColors.accentLime500,
                    opacity: 0.5,
                  ),
                ),
                child: const Text("✓",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
