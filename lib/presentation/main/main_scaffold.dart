import 'package:casazero/core/widgets/bounce_glow_widget.dart';
import 'package:casazero/core/widgets/notifications_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import '../ai/viwes/ai_screen.dart';
import '../documents/viwes/documents_screen.dart';
import '../home/views/home_screen.dart';
import '../hub/views/hub_screen.dart' hide Role;
import '../maintenance/views/maintenance_screen.dart';
import '../profile/views/profile_screen.dart';
import '../smart_home/views/smart_home_screen.dart';
import '../auth/views/change_password_screen.dart';

import '../home/controllers/home_controller.dart';
import '../profile/controllers/profile_controller.dart';
import '../documents/controllers/documents_controller.dart';
import '../maintenance/controllers/maintenance_controller.dart';
import '../../data/models/user_model.dart';
import '../../data/models/feed_item_model.dart';
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
  const MainScaffold({super.key});

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
          // SafeArea applied here for Android devices (removed from main.dart to allow snackbars)
          body: SafeArea(
            top: false, // AppBar handles top safe area
            bottom: true,
            left: false,
            right: false,
            child: _buildBody(),
          ),
          // SINGLE PERSISTENT BOTTOM NAV BAR (show/hide based on screen)
          bottomNavigationBar: _buildBottomNavBar(),
        ),
      ),
    );
  }

  // BUILD APP BAR - PERSISTENT ACROSS ALL SCREENS
  PreferredSizeWidget _buildAppBar() {
    String? title;
    bool showNotification = true;
    bool showSearch = false;
    bool showResidenceSwitcher = false;
    bool canGoBack = false;
    bool canGoForward = false;
    String variant = 'default';

    switch (controller.currentScreen.value) {
      case AppScreen.home:
        title = 'home'.tr;
        // controller.selectedResidence.value?.residenceName ??
        //     'AttoExa Solutions';
        showNotification = true;
        showSearch = false;
        showResidenceSwitcher =
            controller.permissions.canManageBuildings &&
            controller.residences.isNotEmpty;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        variant = 'branded';
        break;

      case AppScreen.documents:
        title = 'documents'.tr;
        showNotification = true;
        //showSearch = true; // Show search on Documents screen
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;

      case AppScreen.hubScreen:
        title = 'Ecosystem Hub';
        showNotification = true; // Show notification on all screens
        showSearch = false;
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;

      case AppScreen.maintenance:
        title = 'maintenance'.tr;
        showNotification = true; // Show notification on all screens
        //showSearch = true; // Show search on Maintenance screen
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;

      case AppScreen.profile:
        title = 'Profile';
        showNotification = true; // Show notification on all screens
        showSearch = false;
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;

      case AppScreen.smartHome:
        title = 'Smart Home';
        showNotification = true; // Show notification on all screens
        showSearch = false;
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;

      case AppScreen.changePassword:
        title = 'Change Password';
        showNotification = true; // Show notification on all screens
        showSearch = false;
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;
      case AppScreen.ai:
        title = 'AI Assistant';
        showNotification = true; // Show notification on all screens
        showSearch = false;
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;
      case AppScreen.trustedDevices:
        title = 'trusted_devices'.tr;
        showNotification = true; // Show notification on all screens
        showSearch = false;
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;
    }

    final showNavigationControls = canGoBack || canGoForward;
    final statusBarHeight = MediaQuery.of(Get.context!).padding.top;

    return PreferredSize(
      preferredSize: Size.fromHeight(64.h + statusBarHeight),
      child:
          Container(
                height: 50.h + statusBarHeight,
                padding: EdgeInsets.only(top: statusBarHeight),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite.withOpacity(0.95),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.neutralLine200.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: 448.w),
                        margin: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Left section - positioned on the left
                            Positioned(
                              left: 0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Navigation Controls (Back/Forward)
                                  // if (showNavigationControls) ...[
                                  //   _buildNavButton(
                                  //     icon: Icons.arrow_back,
                                  //     enabled: canGoBack,
                                  //     onTap: canGoBack
                                  //         ? () => controller.goBack()
                                  //         : null,
                                  //     tooltip: 'Go back (Alt+←)',
                                  //   ),
                                  //   SizedBox(width: 6.w),
                                  //   _buildNavButton(
                                  //     icon: Icons.arrow_forward,
                                  //     enabled: canGoForward,
                                  //     onTap: canGoForward
                                  //         ? () => controller.goForward()
                                  //         : null,
                                  //     tooltip: 'Go forward (Alt+→)',
                                  //   ),
                                  //   SizedBox(width: 8.w),
                                  // ],

                                  // Logo/Title Section (only for non-title cases like logo/residence switcher)
                                  if (variant == 'branded' &&
                                          !showNavigationControls ||
                                      (showResidenceSwitcher && title != null))
                                    _buildTitleSection(
                                      title: title,
                                      showNavigationControls:
                                          showNavigationControls,
                                      variant: variant,
                                      showResidenceSwitcher:
                                          showResidenceSwitcher,
                                      currentResidence: showResidenceSwitcher
                                          ? (controller
                                                    .selectedResidence
                                                    .value
                                                    ?.residenceName ??
                                                'Select Residence')
                                          : null,
                                      onResidenceSwitch: showResidenceSwitcher
                                          ? () => _showResidenceSelectorDialog()
                                          : null,
                                    ),
                                ],
                              ),
                            ),

                            // Center section - Title positioned absolutely in center
                            if (title != null &&
                                !(variant == 'branded' &&
                                    !showNavigationControls) &&
                                !(showResidenceSwitcher && title != null))
                              Center(
                                child: _buildTitleSection(
                                  title: title,
                                  showNavigationControls:
                                      showNavigationControls,
                                  variant: variant,
                                  showResidenceSwitcher: showResidenceSwitcher,
                                  currentResidence: showResidenceSwitcher
                                      ? (controller
                                                .selectedResidence
                                                .value
                                                ?.residenceName ??
                                            'Select Residence')
                                      : null,
                                  onResidenceSwitch: showResidenceSwitcher
                                      ? () => _showResidenceSelectorDialog()
                                      : null,
                                ),
                              ),

                            // Right section - positioned on the right
                            Positioned(
                              right: 0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Search button - shown only on Documents and Maintenance screens
                                  // if (showSearch) ...[
                                  //   _buildSearchButton(
                                  //     onTap: () {
                                  //       // TODO: Implement search functionality
                                  //     },
                                  //   ),
                                  //   SizedBox(width: 8.w),
                                  // ],
                                  // Notification button - shown on ALL screens
                                  if (showNotification)
                                    Obx(() {
                                      // Use unread count from API (single source of truth)
                                      final count = controller.unreadCount.value;
                                      return _buildNotificationButton(
                                        count: count,
                                        onTap: () {
                                          // Show notifications modal bottom sheet
                                          // Use Get.context! here as it's safe in onTap callback
                                          if (Get.context != null) {
                                            NotificationsModal.show(Get.context!);
                                          }
                                        },
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .slideY(
                begin: -0.05,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 500.ms),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: enabled ? tooltip : '',
      waitDuration: const Duration(milliseconds: 300),
      textStyle: TextStyle(
        color: AppColors.surfaceWhite,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutralInk900,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 43.w,
            height: 43.w,
            decoration: BoxDecoration(
              color: enabled ? AppColors.brandSage50 : AppColors.neutralLine100,
              shape: BoxShape.circle,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              size: 20.sp,
              color: enabled ? AppColors.brandSage600 : AppColors.neutralInk300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection({
    String? title,
    required bool showNavigationControls,
    required String variant,
    required bool showResidenceSwitcher,
    String? currentResidence,
    VoidCallback? onResidenceSwitch,
  }) {
    // Branded variant with logo
    if (!showNavigationControls && variant == 'branded') {
      return Image.asset(
            'assets/images/logo_green.png',
            height: 24.h,
            fit: BoxFit.contain,
          )
          .animate()
          .fadeIn(delay: 200.ms, duration: 400.ms)
          .slideX(begin: -0.1, end: 0, duration: 400.ms);
    }

    // Residence Switcher
    if (showResidenceSwitcher && currentResidence != null) {
      return GestureDetector(
        onTap: onResidenceSwitch,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.brandSage50.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    currentResidence,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutralInk900,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  LucideIcons.chevronDown,
                  size: 16.sp,
                  color: AppColors.neutralInk500,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Title
    if (title != null) {
      return Center(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 23.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.neutralInk900,
            letterSpacing: -0.3,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSearchButton({required VoidCallback onTap}) {
    return Tooltip(
      message: 'Search',
      waitDuration: const Duration(milliseconds: 300),
      textStyle: TextStyle(
        color: AppColors.surfaceWhite,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutralInk900,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 43.w,
            height: 43.w,
            decoration: BoxDecoration(
              color: AppColors.brandSage50,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.search,
              size: 25.sp,
              color: AppColors.brandSage600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton({
    required int count,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: 'Notifications',
      waitDuration: const Duration(milliseconds: 300),
      textStyle: TextStyle(
        color: AppColors.surfaceWhite,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutralInk900,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 43.w,
                height: 43.w,
                decoration: BoxDecoration(
                  color: AppColors.brandSage50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications,
                  size: 25.sp,
                  color: AppColors.brandSage600,
                ),
              ),
              // Notification Badge
              if (count > 0)
                Positioned(
                  right: -4.w,
                  top: -4.h,
                  child:
                      Container(
                        constraints: BoxConstraints(
                          minWidth: 20.w,
                          minHeight: 20.h,
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.danger,
                              AppColors.danger.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.surfaceWhite,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            count > 9 ? '9+' : count.toString(),
                            style: TextStyle(
                              color: AppColors.surfaceWhite,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ).animate().scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 300.ms,
                        curve: Curves.elasticOut,
                      ),
                ),
              // Pulsing indicator
              if (count > 0)
                Positioned(
                  right: -4.w,
                  top: -4.h,
                  child:
                      Container(
                            width: 20.w,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.3, 1.3),
                            duration: 2000.ms,
                            curve: Curves.easeInOut,
                          )
                          .then()
                          .scale(
                            begin: const Offset(1.3, 1.3),
                            end: const Offset(1, 1),
                            duration: 2000.ms,
                            curve: Curves.easeInOut,
                          )
                          .fade(
                            begin: 0.5,
                            end: 0,
                            duration: 2000.ms,
                            curve: Curves.easeInOut,
                          )
                          .then(delay: 0.ms)
                          .fade(
                            begin: 0,
                            end: 0.5,
                            duration: 2000.ms,
                            curve: Curves.easeInOut,
                          ),
                ),
            ],
          ),
        ),
      ),
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
        // Ensure DocumentsController is initialized
        if (!Get.isRegistered<DocumentsController>()) {
          Get.put(DocumentsController());
        }
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
        // Ensure MaintenanceController is initialized
        if (!Get.isRegistered<MaintenanceController>()) {
          Get.put(MaintenanceController());
        }
        return MaintenanceScreen(
          role: controller.currentUser.value?.role.toString() ?? 'client',
          onAskAI: () => controller.navigateToScreen(AppScreen.ai),
        );

      case AppScreen.profile:
        // Ensure ProfileController is initialized
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
        final profileController = Get.find<ProfileController>();

        // Sync user data from HomeController to ProfileController
        if (controller.currentUser.value != null) {
          profileController.syncUserData(controller.currentUser.value!);
        }

        // Ensure user is loaded before showing profile screen
        if (controller.currentUser.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brandSage500),
          );
        }
        return ProfileScreen(
          user: controller.currentUser.value!,
          onLogout: () {
            // Use ProfileController's logout method which calls the API
            profileController.logout();
          },
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
          onSuccess: (String message) {
            controller.goBack();
            // Show snackbar after navigation completes
            Future.delayed(const Duration(milliseconds: 300), () {
              Get.snackbar(
                'success'.tr,
                message,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.brandSage600,
                colorText: AppColors.surfaceWhite,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
                duration: const Duration(seconds: 3),
              );
            });
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
    return Obx(() {
      final user = controller.currentUser.value;
      if (user == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.brandSage500),
        );
      }

      if (user.residenceStatus == ResidenceStatus.completed) {
        return HubScreen(
          role: user.role ?? Role.client,
          onNavigate: (destination) =>
              controller.navigateToScreenByString(destination),
        );
      }
      return const HomeScreen();
    });
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
        // borderRadius: BorderRadius.only(
        //   topLeft: Radius.circular(20),
        //   topRight: Radius.circular(20),
        // ),
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
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BounceGlowWidget(
                          active: isActive,
                          child: _buildIcon(tab, isActive),
                        ),

                        SizedBox(height: 8.h),
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
