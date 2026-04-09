import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/residence_model.dart';
import '../../app/theme/app_shadows.dart';
import '../../../presentation/home/controllers/home_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ResidenceInfoCard extends StatelessWidget {
  final UserModel user;

  const ResidenceInfoCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // Get HomeController to access residences
    final homeController = Get.find<HomeController>();

    // Refresh residences when the card is built (e.g., when profile screen is viewed)
    // This ensures we always have fresh data when viewing the profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (homeController.residences.isEmpty && !homeController.isLoadingResidences.value) {
        print('[ResidenceInfoCard] Residences empty, triggering fetchResidences()');
        homeController.fetchResidences();
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.shadowProfileCard,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 16),

          // Display all residences or empty state
          Obx(() {
            if (homeController.isLoadingResidences.value) {
              return _buildLoadingState();
            }

            if (homeController.residences.isEmpty) {
              return _buildEmptyState();
            }

            // Display all residences
            return Column(
              children: homeController.residences
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final residence = entry.value;
                return Column(
                  children: [
                    if (index > 0) const SizedBox(height: 12),
                    _buildResidenceRow(residence),
                  ],
                );
              })
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _header() {
    return Text(
      "residence".tr,
      style: AppTextStyles.CardHeaderText.copyWith(
        color: AppColors.regulerTextColor,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOADING STATE
  // ---------------------------------------------------------------------------
  Widget _buildLoadingState() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/images/location_icon.svg',
          width: 18,
          height: 18,
          colorFilter: const ColorFilter.mode(
            AppColors.grayTextColor,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "loading".tr,
            style: AppTextStyles.cardText.copyWith(
              color: AppColors.neutralInk500,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/images/location_icon.svg',
          width: 18,
          height: 18,
          colorFilter: const ColorFilter.mode(
            AppColors.grayTextColor,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "No_Residence".tr,
            style: AppTextStyles.cardText.copyWith(
              color: AppColors.neutralInk900,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RESIDENCE ROW - Display residence name and address
  // ---------------------------------------------------------------------------
  Widget _buildResidenceRow(ResidenceModel residence) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/images/location_icon.svg',
          width: 18,
          height: 18,
          colorFilter: const ColorFilter.mode(
            AppColors.grayTextColor,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First line: Residence Name
              Text(
                residence.residenceName,
                style: AppTextStyles.cardText.copyWith(
                  color: AppColors.neutralInk900,
                ),
              ),
              const SizedBox(height: 6),
              // Second line: Residence Address
              Text(
                residence.residenceAddress ?? "address".tr,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutralInk500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}