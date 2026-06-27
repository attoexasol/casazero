import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../localization/locale_controller.dart';
import '../utils/accessibility.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool showLabel;
  final Color? activeColor;
  final Color? inactiveColor;

  const LanguageSwitcher({
    super.key,
    this.showLabel = true,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final LocaleController localeController = Get.find();

    return Obx(
          () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Icon(Icons.language, size: 20.sp),
            SizedBox(width: 8.w),
          ],
          _buildLanguageButton(
            'EN',
            'en',
            localeController.isEnglish,
            localeController,
          ),
          SizedBox(width: 8.w),
          _buildLanguageButton(
            'IT',
            'it',
            localeController.isItalian,
            localeController,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(
      String label,
      String code,
      bool isActive,
      LocaleController controller,
      ) {
    return InkWell(
      onTap: () => controller.changeLocale(code),
      borderRadius: BorderRadius.circular(8.r),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: Accessibility.minTouchTarget,
          minHeight: Accessibility.minTouchTarget,
        ),
        child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isActive
              ? (activeColor ?? AppColors.brandSage500)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isActive
                ? (activeColor ?? AppColors.brandSage500)
                : (inactiveColor ?? AppColors.neutralLine200),
          ),
        ),
        child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isActive
                ? AppColors.surfaceWhite
                : (inactiveColor ?? AppColors.neutralInk700),
          ),
        ),
        ),
        ),
      ),
    );
  }
}
