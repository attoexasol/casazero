import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

import '../../../data/models/user_model.dart';
import '../../app/theme/app_shadows.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../presentation/profile/controllers/profile_controller.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/controllers/message_popup_controller.dart';
import '../../core/logging/diagnostic_logger.dart';


class PreferencesCard extends StatefulWidget {
  final UserModel user;

  const PreferencesCard({super.key, required this.user});

  @override
  State<PreferencesCard> createState() => _PreferencesCardState();
}

class _PreferencesCardState extends State<PreferencesCard> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _changeLanguage(String code) async {
    // Use LocaleController as single source of truth
    final localeController = Get.find<LocaleController>();
    
    // Update LocaleController immediately (updates app-wide language)
    await localeController.changeLocale(code);

    // Call ProfileController to update API (if user is logged in)
    final profileController = Get.find<ProfileController>();
    if (profileController.user.value != null) {
      await profileController.changeLanguage(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the controller to access loading state
    final controller = Get.find<ProfileController>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.shadowProfileCard,
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("preferences".tr, style: AppTextStyles.cardHeaderText),
          SizedBox(height: 16.h),

          Obx(() => _buildLanguageSelector(controller)),

          SizedBox(height: 16.h),
          _buildExportDiagnosticLog(),

          // const SizedBox(height: 16),

          // _buildResetFirstLogin(),
        ],
      ),
    );
  }

  // LANGUAGE SELECTOR -----------------------------------------------------

  Widget _buildLanguageSelector(ProfileController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutralLine200),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/language.svg',   // your svg file
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.neutralInk500,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Text("language".tr, style: AppTextStyles.bodyMedium),
          const Spacer(),

          // Show loading indicator if language is being changed
          if (controller.isChangingLanguage.value)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandSage600),
              ),
            )
          else ...[
            _pill("IT", "it"),
            const SizedBox(width: 6),
            _pill("EN", "en"),
          ],
        ],
      ),
    );
  }

  Widget _pill(String text, String code) {
    // Use LocaleController as single source of truth
    final localeController = Get.find<LocaleController>();
    
    return Obx(() {
      final active = (code == 'it' && localeController.isItalian) ||
          (code == 'en' && localeController.isEnglish);

      return InkWell(
        onTap: () => _changeLanguage(code),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.brandSage600 : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? AppColors.brandSage600 : AppColors.neutralInk300,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : AppColors.neutralInk500,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildExportDiagnosticLog() {
    return InkWell(
      onTap: _exportDiagnosticLog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutralLine200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.ios_share,
              size: 20,
              color: AppColors.neutralInk500,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'export_diagnostic_log'.tr,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20.sp,
              color: AppColors.neutralInk400,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportDiagnosticLog() async {
    try {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      Rect? origin;
      if (box != null && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
      final bool ok = await DiagnosticLogger.instance.shareLogFile(
        shareOrigin: origin,
      );
      if (!ok) {
        await MessagePopupController.showError(
          messageKey: 'diagnostic_log_export_failed',
          titleKey: 'error',
        );
      }
    } catch (_) {
      try {
        await MessagePopupController.showError(
          messageKey: 'diagnostic_log_export_failed',
          titleKey: 'error',
        );
      } catch (_) {}
    }
  }
}