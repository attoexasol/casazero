import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_gradients.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'package:get/get.dart';

class PremiumBanner extends StatelessWidget {
  const PremiumBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutralLine100.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: AppShadows.shadowSm,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              // decoration: BoxDecoration(
              //   borderRadius: BorderRadius.circular(16),
              //   gradient: AppGradients.premiumGradient,
              //   boxShadow: AppShadows.shadowMd,
              // ),
              child:
                Image.asset(
                'assets/images/home_ai.png',
                width: 60,
                height: 60,
              ),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutralInk800,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: 'whats_new: '.tr,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: 'ai_document_analysis'.tr),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
