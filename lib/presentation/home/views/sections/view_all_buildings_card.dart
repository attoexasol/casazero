import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_gradients.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_text_styles.dart';

class ViewAllBuildingsCard extends StatelessWidget {
  final VoidCallback onTap;

  const ViewAllBuildingsCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 448.w),
        child: Container(
          margin: EdgeInsets.only(top: 24.h, left: 24.w, right: 24.w),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: AppShadows.shadowLg,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      gradient: AppGradients.premiumGradient,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: AppShadows.customColoredShadow(
                        AppColors.brandSage500,
                        opacity: 0.3,
                      ),
                    ),
                    child: const Icon(Icons.business,
                        color: AppColors.surfaceWhite),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'building'.tr,
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'view_all_buildings'.tr,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.neutralInk500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentLime500,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: AppShadows.customColoredShadow(
                        AppColors.accentLime500,
                        opacity: 0.5,
                      ),
                    ),
                    child: Text(
                      '✓',
                      style: TextStyle(fontSize: 16.sp, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
