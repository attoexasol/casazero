// lib/presentation/home/views/home_screen.dart

import 'package:casazero/presentation/main/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/utils/permissions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../controllers/home_controller.dart';

// SECTIONS
import 'sections/premium_banner.dart';
import 'sections/residence_name.dart';
import 'sections/hero_image.dart';
import 'sections/welcome_message.dart';
import 'sections/construction_progress.dart';
import 'sections/view_all_buildings_card.dart';
import 'sections/quick_tiles.dart';
import 'sections/latest_notifications.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // NO SCAFFOLD - This screen is wrapped by MainScaffold
    return Obx(() {
      if (controller.isLoading.value) {
        return const LoadingIndicator(message: 'loading');
      }
      return RefreshIndicator(
        onRefresh: controller.refreshData,
        color: AppColors.brandSage500,
        child: _buildBody(),
      );
    });
  }

  Widget _buildBody() {
    final user = controller.currentUser.value;
    final isCompleted = user?.residenceStatus == ResidenceStatus.completed;
    final isUnderConstruction =
        user?.residenceStatus == ResidenceStatus.underConstruction;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const PremiumBanner(),
          ResidenceName(user: user)
              .animate(
            delay: 100.ms,
          )
              .fadeIn()
              .slideY(begin: 0.15),
          const HeroImage()
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.9, 0.9)),
          
          // Residence Status
          Obx(() {
            final residenceStatus = controller.residenceData.value?['residence_status'];
            if (residenceStatus != null && residenceStatus.toString().isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
                child: Text(
                  residenceStatus.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // const HeroImage()
          //     .animate()
          //     .fadeIn(duration: 500.ms)
          //     .scale(begin: const Offset(0.9, 0.9)),

          // COMPLETED DASHBOARD
          //if (isCompleted) ...[
          //   WelcomeMessage(user: user)
          //       .animate(
          //     delay: 100.ms,
          //   )
          //       .fadeIn()
          //       .slideY(begin: 0.15),
          const LatestNotifications()
              .animate(
            delay: 100.ms,
          )
              .fadeIn()
              .slideY(begin: 0.15),

          if (controller.permissions.canManageBuildings)
            ViewAllBuildingsCard(
              onTap: () => controller.navigateToScreen(AppScreen.changePassword),
            )  .animate(
              delay: 100.ms,
            )
                .fadeIn()
                .slideY(begin: 0.15),

          // QuickTiles(
          //   permissions: controller.permissions,
          //   onNavigate:()=> {},// controller.navigateToScreen(AppScreen.changePassword),
          // )
          //     .animate(
          //   delay: 100.ms,
          // )
          //     .fadeIn()
          //     .slideY(begin: 0.15),
          // const SizedBox(height: 80),
          //],

          // UNDER CONSTRUCTION DASHBOARD
          if (isUnderConstruction) ...[
            ConstructionProgress(
              phases: controller.constructionPhases,
              canManageBuildings: controller.permissions.canManageBuildings,
              onViewBuildings: () => controller.navigateToScreen(AppScreen.ai),
            )  .animate(
              delay: 100.ms,
            )
                .fadeIn()
                .slideY(begin: 0.15),

            const LatestNotifications()
                .animate(
              delay: 100.ms,
            )
                .fadeIn()
                .slideY(begin: 0.15),
            const SizedBox(height: 80),
          ],
        ],
      ),
    );
  }
}