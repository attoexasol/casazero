import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.neutralLine200.withValues(alpha: 0.5)),
          boxShadow: AppShadows.shadowLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ICON
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.brandSage600,
                    AppColors.brandSage400,
                  ],
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: AppShadows.customColoredShadow(
                  AppColors.brandSage500,
                  opacity: 0.3,
                ),
              ),
              child: Icon(
                data['icon'],
                color: Colors.white,
                size: 22.sp,
              ),
            ),

            const Spacer(),

            Text(
              data['title'],
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 4.h),

            Text(
              data['label'],
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutralInk500,
                fontSize: 12.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
