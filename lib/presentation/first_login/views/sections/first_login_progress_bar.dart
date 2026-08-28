import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_colors.dart';
import '../../controllers/first_login_controller.dart';

class FirstLoginProgressBar extends StatelessWidget {
  final FirstLoginController controller;

  const FirstLoginProgressBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: controller.currentStep.value == 1 ? 0.5 : 1.0,
              minHeight: 8.h,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.brandSage500),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                'change_password'.tr,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: controller.currentStep.value == 1
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                  fontWeight: controller.currentStep.value == 1
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ),
              Flexible(
                child: Text(
                'two_factor_auth'.tr,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: controller.currentStep.value == 2
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                  fontWeight: controller.currentStep.value == 2
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
