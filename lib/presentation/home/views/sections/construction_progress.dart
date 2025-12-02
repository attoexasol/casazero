import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_shadows.dart';

import 'construction_phase_item.dart';

class ConstructionProgress extends StatelessWidget {
  final List<dynamic> phases;
  final bool canManageBuildings;
  final VoidCallback onViewBuildings;

  const ConstructionProgress({
    super.key,
    required this.phases,
    required this.canManageBuildings,
    required this.onViewBuildings,
  });

  @override
  Widget build(BuildContext context) {
    if (phases.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 32, left: 24, right: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutralLine200),
        boxShadow: AppShadows.shadowLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Text(
                'construction_progress'.tr,
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.neutralInk900,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.auto_awesome,
                color: AppColors.aquaGreen500,
                size: 20,
              ),
            ],
          ).animate().fadeIn().slideY(begin: 0.2),

          const SizedBox(height: 8),
          Text(
            'your_home_is_being_built'.tr,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutralInk500,
            ),
          ),

          const SizedBox(height: 24),

          // Phases
          Column(
            children: phases.asMap().entries.map((entry) {
              return ConstructionPhaseItem(
                index: entry.key,
                total: phases.length,
                phase: entry.value,
              )
                  .animate(
                delay: (entry.key * 80).ms,
              )
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.2);
            }).toList(),
          ),

          // View buildings
          if (canManageBuildings) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onViewBuildings,
                icon: const Icon(Icons.business, size: 18),
                label: Text('view_all_buildings'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.aquaGreen600,
                  foregroundColor: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            )
                .animate(
              delay: 200.ms,
            )
                .fadeIn()
                .slideY(begin: 0.2),
          ]
        ],
      ),
    );
  }
}
