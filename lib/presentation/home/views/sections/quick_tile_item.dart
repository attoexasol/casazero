import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_shadows.dart';

class QuickTileItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const QuickTileItem({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutralLine200.withOpacity(0.5)),
          boxShadow: AppShadows.shadowLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ICON
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.brandSage600,
                    AppColors.brandSage400,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.customColoredShadow(
                  AppColors.brandSage500,
                  opacity: 0.3,
                ),
              ),
              child: Icon(
                data['icon'],
                color: Colors.white,
                size: 22,
              ),
            ),

            const Spacer(),

            Text(
              data['title'],
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              data['label'],
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutralInk500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
