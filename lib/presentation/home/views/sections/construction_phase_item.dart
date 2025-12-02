import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class ConstructionPhaseItem extends StatelessWidget {
  final int index;
  final int total;
  final dynamic phase;

  const ConstructionPhaseItem({
    super.key,
    required this.index,
    required this.total,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLast = index == total - 1;

    Color iconColor;
    IconData iconData;

    if (phase.status == 'completed') {
      iconColor = AppColors.aquaGreen500;
      iconData = Icons.check;
    } else if (phase.status == 'in-progress') {
      iconColor = AppColors.info;
      iconData = Icons.build;
    } else {
      iconColor = AppColors.neutralInk300;
      iconData = Icons.schedule;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: Colors.white, size: 18),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: AppColors.neutralInk300,
                ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),

                // In-progress bar
                if (phase.status == 'in-progress') ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: phase.progress / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.neutralLine200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.info,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${phase.progress}${'percent_complete'.tr}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutralInk500,
                    ),
                  ),
                ] else
                  Text(
                    phase.status == 'completed'
                        ? 'completed'.tr
                        : 'pending'.tr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutralInk500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
