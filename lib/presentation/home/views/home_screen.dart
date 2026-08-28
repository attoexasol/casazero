// lib/presentation/home/views/home_screen.dart

import 'package:casazero/presentation/main/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/widgets/floating_bottom_nav_bar.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/home_controller.dart';

// SECTIONS
import 'sections/residence_name.dart';
import 'sections/hero_image.dart';
import 'sections/welcome_user_section.dart';
import 'sections/construction_progress_section.dart';

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
        child: _buildBody(context),
      );
    });
  }

  Widget _buildBody(BuildContext context) {
    final user = controller.currentUser.value;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: FloatingBottomNavBar.screenPadding(context),
      child: Column(
        children: [
          //const PremiumBanner(),
          // ResidenceName handles its own animations internally (matching React Framer Motion)
          ResidenceName(user: user),

          SizedBox(height: 20.h),
          // HeroImage handles its own animations internally (matching React Framer Motion)
          const HeroImage(),

          SizedBox(height: 20.h),
          // Welcome User Section (placed directly below Hero image)
          WelcomeUserSection(user: user),

          // Residence Status
          // Obx(() {
          //   final residenceStatus =
          //       controller.residenceData.value?['residence_status'];
          //   if (residenceStatus != null &&
          //       residenceStatus.toString().isNotEmpty) {
          //     return Padding(
          //       padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
          //       child: Text(
          //         residenceStatus.toString(),
          //         textAlign: TextAlign.center,
          //         style: const TextStyle(
          //           fontSize: 16,
          //           fontWeight: FontWeight.w500,
          //         ),
          //       ),
          //     );
          //   }
          //   return const SizedBox.shrink();
          // }),

          // const HeroImage()
          //     .animate()
          //     .fadeIn(duration: 500.ms)
          //     .scale(begin: const Offset(0.9, 0.9)),

          // Construction Progress: driven by live API residence status
          Obx(() {
            if (!controller.isResidenceUnderConstruction) {
              return const SizedBox.shrink();
            }
            return ConstructionProgressSection(
              onViewBuildings: () => controller.navigateToScreen(AppScreen.ai),
            );
          }),

          // COMPLETED DASHBOARD
          //if (isCompleted) ...[
          //   WelcomeMessage(user: user)
          //       .animate(
          //     delay: 100.ms,
          //   )
          //       .fadeIn()
          //       .slideY(begin: 0.15),
          // const LatestNotifications()
          //     .animate(delay: 100.ms)
          //     .fadeIn()
          //     .slideY(begin: 0.15),
            SizedBox(height: 20.h),
          // if (controller.permissions.canManageBuildings)
          //   ViewAllBuildingsCard(
          //     onTap: () =>
          //         controller.navigateToScreen(AppScreen.changePassword),
          //   ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.15),

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

          // Under-construction content is handled above (ConstructionProgressSection + single LatestNotifications)
        ],
      ),
    );
  }
}
