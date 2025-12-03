import 'package:casazero/core/widgets/bounce_glow_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/cz_app_bar.dart';
import '../ai/viwes/ai_screen.dart';
import '../documents/viwes/documents_screen.dart';
import '../home/views/home_screen.dart';
import '../hub/views/hub_screen.dart' hide Role;
import '../maintenance/views/maintenance_screen.dart';
import '../profile/views/profile_screen.dart';
import '../smart_home/views/smart_home_screen.dart';
import '../auth/views/change_password_screen.dart';

import '../home/controllers/home_controller.dart';
import '../../data/models/user_model.dart';
import '../../core/utils/permissions.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../trusted_device/views/trusted_devices_screen.dart';

// Screen identifiers
enum AppScreen {
  home,
  documents,
  ai,
  maintenance,
  profile,
  smartHome,
  changePassword,
  hubScreen,
  trustedDevices,
  // Add more screens as needed
}

class MainScaffold extends GetView<HomeController> {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => WillPopScope(
        onWillPop: () async {
          // Handle back button - go back to previous screen
          return controller.handleBackNavigation();
        },
        child: Scaffold(
          backgroundColor: AppColors.surfaceWhite,
          // SINGLE PERSISTENT APP BAR FOR ALL SCREENS
          appBar: _buildAppBar(),
          // BODY - Contains all screens dynamically
          body: _buildBody(),
          // SINGLE PERSISTENT BOTTOM NAV BAR (show/hide based on screen)
          bottomNavigationBar: _buildBottomNavBar(),
        ),
      ),
    );
  }

  // BUILD APP BAR - PERSISTENT ACROSS ALL SCREENS
  PreferredSizeWidget _buildAppBar() {
    String title = 'CasaZero';
    bool showNotification = true;
    bool showBuildingSelector = false;
    bool showBackButton = false;

    switch (controller.currentScreen.value) {
      case AppScreen.home:
        // Show selected residence name or default
        title =
            controller.selectedResidence.value?.residenceName ??
            'AttoExa Solutions';
        showNotification = true;
        showBuildingSelector =
            controller.permissions.canManageBuildings &&
            controller.residences.isNotEmpty;
        showBackButton = false;
        break;

      case AppScreen.documents:
        title = 'Documents';
        showNotification = true;
        showBuildingSelector = false;
        showBackButton = false;
        break;

      case AppScreen.hubScreen:
        title = 'AI Assistant';
        showNotification = false;
        showBuildingSelector = false;
        showBackButton = false;
        break;

      case AppScreen.maintenance:
        title = 'Maintenance';
        showNotification = true;
        showBuildingSelector = false;
        showBackButton = false;
        break;

      case AppScreen.profile:
        title = 'Profile';
        showNotification = false;
        showBuildingSelector = false;
        showBackButton = false;
        break;

      case AppScreen.smartHome:
        title = 'Smart Home';
        showNotification = true;
        showBuildingSelector = false;
        showBackButton = true; // Show back button for sub-screens
        break;

      case AppScreen.changePassword:
        title = 'Change Password';
        showNotification = false;
        showBuildingSelector = false;
        showBackButton = true;
        break;
      case AppScreen.ai:
        title = 'Change Password';
        showNotification = false;
        showBuildingSelector = false;
        showBackButton = true;
        break;
      case AppScreen.trustedDevices:
        title = 'trusted_devices'.tr;
        showNotification = false;
        showBuildingSelector = false;
        showBackButton = true;
        break;
    }

    return CZAppBar(
      title: title,
      showNotification: showNotification,
      showBuildingSelector: showBuildingSelector,
      showBackButton: showBackButton,
      onBackPressed: showBackButton ? () => controller.goBack() : null,
      onBuildingTap: showBuildingSelector
          ? () => _showResidenceSelectorDialog()
          : null,
    );
  }

  /// Show residence selector dialog
  void _showResidenceSelectorDialog() {
    Get.dialog(
      Obx(
        () => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'select_residence'.tr,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          content: controller.isLoadingResidences.value
              ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                )
              : controller.residences.isEmpty
              ? SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'no_residences_available'.tr,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.residences.length,
                    itemBuilder: (context, index) {
                      final residence = controller.residences[index];
                      final isSelected =
                          controller.selectedResidence.value?.id ==
                          residence.id;

                      return ListTile(
                        leading: Icon(
                          Icons.apartment_rounded,
                          color: isSelected
                              ? AppColors.brandSage600
                              : Colors.grey,
                        ),
                        title: Text(
                          residence.residenceName,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.brandSage600
                                : Colors.black87,
                          ),
                        ),
                        subtitle:
                            residence.residenceAddress != null &&
                                residence.residenceAddress!.isNotEmpty
                            ? Text(residence.residenceAddress!)
                            : null,
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: AppColors.brandSage600,
                              )
                            : null,
                        onTap: () {
                          controller.selectResidence(residence);
                          Get.back();
                        },
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Show the current screen based on controller.currentScreen
    switch (controller.currentScreen.value) {
      case AppScreen.home:
        return _buildHomeScreen();

      case AppScreen.documents:
        return DocumentsScreen(
          role: controller.currentUser.value?.role ?? Role.client,
          onAskAI: () => controller.navigateToScreen(AppScreen.ai),
        );

      case AppScreen.hubScreen:
        return HubScreen(
          role: controller.currentUser.value?.role ?? Role.client,
          onNavigate: (screen) =>
              controller.navigateToScreen(AppScreen.hubScreen),
        );

      case AppScreen.maintenance:
        return MaintenanceScreen(
          role: controller.currentUser.value?.role.toString() ?? 'client',
          onAskAI: () => controller.navigateToScreen(AppScreen.ai),
        );

      case AppScreen.profile:
        return ProfileScreen(
          user: controller.currentUser.value!,
          onLogout: controller.logout,
          onNavigate: (destination) =>
              controller.navigateToScreenByString(destination),
        );

      case AppScreen.smartHome:
        return SmartHomeScreen(
          role: controller.currentUser.value?.role.toString() ?? 'client',
        );

      case AppScreen.changePassword:
        return ChangePasswordScreen(
          onBack: () => controller.goBack(),
          onSuccess: () {
            controller.goBack();
            Get.snackbar(
              'Success',
              'Password changed successfully',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.brandSage600,
              colorText: AppColors.surfaceWhite,
            );
          },
        );

      case AppScreen.trustedDevices:
        return const TrustedDevicesScreen();

      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    // Show Hub for completed residence, dashboard for under construction
    if (controller.currentUser.value?.residenceStatus ==
        ResidenceStatus.completed) {
      return HubScreen(
        role: controller.currentUser.value?.role ?? Role.client,
        onNavigate: (destination) =>
            controller.navigateToScreenByString(destination),
      );
    }
    return const HomeScreen();
  }

  Widget? _buildBottomNavBar() {
    // Hide bottom nav on certain screens
    final hideBottomNavScreens = [
      AppScreen.smartHome,
      AppScreen.changePassword,
      AppScreen.trustedDevices,
      // Add other screens where you want to hide bottom nav
    ];

    if (hideBottomNavScreens.contains(controller.currentScreen.value)) {
      return null; // Hide bottom nav
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          top: BorderSide(color: AppColors.neutralLine200, width: 1.w),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 61.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(controller.bottomNavTabs.length, (index) {
              final tab = controller.bottomNavTabs[index];
              final isActive = controller.currentScreen.value == tab.screen;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => controller.navigateToScreen(tab.screen),
                  child: AnimatedContainer(
                    key: ValueKey(tab.screen),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    padding: EdgeInsets.only(top: 10.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BounceGlowWidget(
                          active: isActive,
                          child: _buildIcon(tab, isActive),
                        ),

                        SizedBox(height: 10.h),
                        // Active indicator dot
                        AnimatedOpacity(
                          opacity: isActive ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 4.w,
                            height: 4.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.brandSage500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BottomNavTab tab, bool isActive) {
    // SET YOUR CUSTOM SIZES HERE
    final double activeSize = 24.w; // Bigger on active
    final double inactiveSize = 24.w; // Smaller on inactive

    // The icon that should NOT change color when active
    bool noColorChange = tab.screen == AppScreen.hubScreen;

    final activeColor = AppColors.brandSage500; // green
    final inactiveColor = Color(0xff333333); // grey

    // Decide which color to apply
    final Color? iconColor = noColorChange
        ? null // do NOT apply active/inactive color
        : (isActive ? activeColor : inactiveColor);

    // Active/inactive colors

    if (tab.assetIcon != null) {
      return SvgPicture.asset(
        tab.assetIcon!,
        width: isActive ? activeSize : inactiveSize,
        height: isActive ? activeSize : inactiveSize,
        // THIS is the correct way to preserve original SVG color:
        colorFilter: iconColor == null
            ? null
            : ColorFilter.mode(iconColor, BlendMode.srcIn),
        fit: BoxFit.contain,
      );
    }

    return Image.asset(
      tab.icon!,
      width: isActive ? activeSize : inactiveSize,
      height: isActive ? activeSize : inactiveSize,
      color: iconColor, // <- smart color
    );
  }
}

// Bottom Navigation Tab Model
class BottomNavTab {
  final AppScreen screen;
  final String label;
  final String? icon;
  final String? assetIcon;

  const BottomNavTab({
    required this.screen,
    required this.label,
    this.icon,
    this.assetIcon,
  });
}
