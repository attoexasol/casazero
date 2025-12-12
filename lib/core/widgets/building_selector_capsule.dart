import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/theme/app_colors.dart';

class BuildingSelectorCapsule extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const BuildingSelectorCapsule({Key? key, required this.label, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 200.w, // keeps capsule from overflowing
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.brandSage50,
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(color: AppColors.brandSage300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon(
            //   Icons.apartment_rounded,
            //   size: 16.sp,
            //   color: AppColors.neutralInk500,
            // ),
            //
            // SizedBox(width: 6.w),

            /// Expanded here prevents overflow
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 14.sp, // Increased text size
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutralInk800,
                ),
              ),
            ),

            SizedBox(width: 4.w),

            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18.sp,
              color: AppColors.neutralInk500,
            ),
          ],
        ),
      ),
    );
  }
}
