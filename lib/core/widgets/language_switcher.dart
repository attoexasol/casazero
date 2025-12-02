import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../localization/locale_controller.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool showLabel;
  final Color? activeColor;
  final Color? inactiveColor;

  const LanguageSwitcher({
    Key? key,
    this.showLabel = true,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LocaleController localeController = Get.find();

    return Obx(
          () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            const Icon(Icons.language, size: 20),
            const SizedBox(width: 8),
          ],
          _buildLanguageButton(
            'EN',
            'en',
            localeController.isEnglish,
            localeController,
          ),
          const SizedBox(width: 8),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (activeColor ?? AppColors.brandSage500)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? (activeColor ?? AppColors.brandSage500)
                : (inactiveColor ?? AppColors.neutralLine200),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive
                ? AppColors.surfaceWhite
                : (inactiveColor ?? AppColors.neutralInk700),
          ),
        ),
      ),
    );
  }
}
