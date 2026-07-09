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

    final bool isCompleted = phase.status == 'completed';
    final bool isInProgress = phase.status == 'in-progress';

    Color iconColor;
    Widget statusIcon;

    if (isCompleted) {
      iconColor = AppColors.aquaGreen500;
      statusIcon = Image.asset(
        'assets/images/casa_zero_ai.ico',
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    } else if (isInProgress) {
      iconColor = AppColors.info;
      statusIcon = const Icon(Icons.build, color: Colors.white, size: 18);
    } else {
      iconColor = AppColors.neutralInk300;
      statusIcon = const Icon(Icons.schedule, color: Colors.white, size: 18);
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
                child: Center(child: statusIcon),
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
