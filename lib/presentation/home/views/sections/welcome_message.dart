import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'package:get/get.dart';

class WelcomeMessage extends StatelessWidget {
  final dynamic user;

  const WelcomeMessage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 448.w),
        child: Padding(
          padding: EdgeInsets.only(top: 16.h),
          child: Text(
            '${'welcome'.tr}, ${user?.firstName ?? 'User'}',
            style: AppTextStyles.h3.copyWith(
              fontSize: 22.sp,
              color: AppColors.neutralInk700,
              letterSpacing: -0.3.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
