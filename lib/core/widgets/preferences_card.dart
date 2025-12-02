import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

import '../../../data/models/user_model.dart';
import '../../app/theme/app_shadows.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../presentation/profile/controllers/profile_controller.dart';


class PreferencesCard extends StatefulWidget {
  final UserModel user;

  const PreferencesCard({super.key, required this.user});

  @override
  State<PreferencesCard> createState() => _PreferencesCardState();
}

class _PreferencesCardState extends State<PreferencesCard> {
  late String lang;

  @override
  void initState() {
    super.initState();
    lang = widget.user.language; // "en" or "it"
  }

  Future<void> _changeLanguage(String code) async {
    // Update local state immediately for UI responsiveness
    setState(() => lang = code);

    // Update GetX locale immediately
    if (code == "it") {
      Get.updateLocale(const Locale('it', 'IT'));
    } else {
      Get.updateLocale(const Locale('en', 'US'));
    }

    // Call the controller method which will handle API call
    final controller = Get.find<ProfileController>();
    await controller.changeLanguage(code);
  }

  @override
  Widget build(BuildContext context) {
    // Get the controller to access loading state
    final controller = Get.find<ProfileController>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.shadowPremium,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("preferences".tr, style: AppTextStyles.CardHeaderText),
          const SizedBox(height: 16),

          Obx(() => _buildLanguageSelector(controller)),

          const SizedBox(height: 16),

          _buildResetFirstLogin(),
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
    final active = lang == code;

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
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // RESET FIRST LOGIN -----------------------------------------------------

  Widget _buildResetFirstLogin() {
    return InkWell(
      onTap: () {
        // You can implement logic here later
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.refresh, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "reset_first_login".tr,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}