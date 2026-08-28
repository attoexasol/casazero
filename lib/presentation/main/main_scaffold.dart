import 'package:casazero/core/controllers/message_popup_controller.dart';
import 'package:casazero/core/widgets/responsive_alert_dialog.dart';
import 'package:casazero/core/widgets/floating_bottom_nav_bar.dart';
import 'package:casazero/core/widgets/notifications_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../hub/views/hub_screen.dart';
import '../maintenance/views/maintenance_screen.dart';
import '../profile/views/profile_screen.dart';
import '../smart_home/views/smart_home_screen.dart';
import '../auth/views/change_password_screen.dart';

import '../home/controllers/home_controller.dart';
import '../profile/controllers/profile_controller.dart';
import '../documents/controllers/documents_controller.dart';
import '../maintenance/controllers/maintenance_controller.dart';
import '../ai/controllers/ai_controller.dart';
import '../chat/controllers/chat_controller.dart';
import '../chat/controllers/private_chat_controller.dart';
import '../hub/controllers/hub_controller.dart';
import '../tickets/controllers/tickets_controller.dart';
import '../../core/utils/permissions.dart';
import '../../core/utils/accessibility.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../chat/views/chat_screen.dart';
import '../chat/views/chat_hub_screen.dart';
import '../chat/views/private_chat_screen.dart';
import '../tickets/views/tickets_screen.dart';

// Screen identifiers
enum AppScreen {
  home,
  documents,
  ai,
  maintenance,
  profile,
  smartHome,
  trustedDevices,
  changePassword,
  hubScreen,
  chatHub,
  chat,
  adminChat,
  tickets,
  //trustedDevices,
  // Add more screens as needed
}

class MainScaffold extends GetView<HomeController> {
  const MainScaffold({super.key});

  /// Start loading maintenance categories early so the filter bar is ready
  /// before the user opens the maintenance tab.
  void _ensureMaintenancePreloaded() {
    if (!Get.isRegistered<MaintenanceController>()) {
      Get.put(MaintenanceController());
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureMaintenancePreloaded();
    return Obx(
      () => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          if (_shouldDismissKeyboardFirst(context)) {
            FocusManager.instance.primaryFocus?.unfocus();
            return;
          }

          controller.handleBackNavigation().then((shouldExit) {
            if (shouldExit) {
              SystemNavigator.pop();
            }
          });
        },
        child: Scaffold(
          backgroundColor: AppColors.surfaceWhite,
          extendBody: true,
          resizeToAvoidBottomInset: false,
          appBar: _buildAppBar(),
          body: _ScrollAwareBody(
            isNavVisible: _isBottomNavVisible(),
            screenKey: controller.currentScreen.value,
            body: _buildBody(),
            navBarBuilder: _buildFloatingNavBar,
          ),
        ),
      ),
    );
  }

  // BUILD APP BAR - PERSISTENT ACROSS ALL SCREENS
  PreferredSizeWidget _buildAppBar() {
    late String title;
    bool showNotification = true;
    bool showResidenceSwitcher = false;
    bool canGoBack = false;
    bool canGoForward = false;
    String variant = 'default';

    switch (controller.currentScreen.value) {
      case AppScreen.home:
        title = 'home_page'.tr;
        showNotification = true;
        showResidenceSwitcher = false; // No residence switcher on home screen
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        variant =
            'default'; // Use default variant to show title text (not logo)
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
        title = 'ecosystemHub'.tr;
        showNotification = true; // Show notification on all screens
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
        title = 'profile'.tr;
        showNotification = true; // Show notification on all screens
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;

      case AppScreen.smartHome:
        title = 'smartHome'.tr;
        showNotification = true; // Show notification on all screens
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;

      case AppScreen.changePassword:
        title = 'Change Password';
        showNotification = true; // Show notification on all screens
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;
      case AppScreen.ai:
        title = 'casaZeroAI'.tr;
        showNotification = true; // Show notification on all screens
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;

      case AppScreen.trustedDevices:
        title = 'trusted_devices'.tr;
        showNotification = true; // Show notification on all screens
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;

      case AppScreen.chatHub:
        title = 'appbarchatHub'.tr;
        showNotification = true;
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;

      case AppScreen.chat:
        title = 'appbargroupChat'.tr;
        showNotification = true;
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;

      case AppScreen.adminChat:
        title = 'appbarAdminChat'.tr;
        showNotification = true;
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;

      case AppScreen.tickets:
        title = 'tickets'.tr;
        showNotification = true;
        showResidenceSwitcher = false;
        canGoBack = controller.canGoBack;
        canGoForward = controller.canGoForward;
        break;
    }

    final showNavigationControls = canGoBack || canGoForward;
    final currentScreen = controller.currentScreen.value;
    final showBackButton =
        canGoBack &&
        (currentScreen == AppScreen.ai ||
            currentScreen == AppScreen.chatHub ||
            currentScreen == AppScreen.chat ||
            currentScreen == AppScreen.adminChat ||
            currentScreen == AppScreen.tickets);
    final statusBarHeight = MediaQuery.paddingOf(Get.context!).top;
    final toolbarHeight = 56.h;
    final leadingInset = showBackButton ? 48.w : 8.w;
    final trailingInset = showNotification ? 48.w : 8.w;
    final titleSideInset =
        leadingInset > trailingInset ? leadingInset : trailingInset;
    // Solid opaque app bar (no blur/shadow) — frosted glass lets green UI
    // under the bar bleed through as a green bottom edge on these screens.
    final useOpaqueAppBar = currentScreen == AppScreen.tickets ||
        currentScreen == AppScreen.maintenance;

    final appBarContent = Center(
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
                  if (showBackButton)
                    IconButton(
                      onPressed: () => controller.goBack(),
                      icon: Icon(
                        CupertinoIcons.back,
                        size: 24.sp,
                        color: AppColors.neutralInk900,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: Accessibility.iconButtonConstraints,
                    ),
                  if (showBackButton) SizedBox(width: 4.w),

                  // Logo/Title Section (only for non-title cases like logo/residence switcher)
                  if ((variant == 'branded' && !showNavigationControls) ||
                      showResidenceSwitcher)
                    _buildTitleSection(
                      title: title,
                      showNavigationControls: showNavigationControls,
                      variant: variant,
                      showResidenceSwitcher: showResidenceSwitcher,
                      currentResidence: showResidenceSwitcher
                          ? (controller.selectedResidence.value?.residenceName ??
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
            if (!(variant == 'branded' && !showNavigationControls) &&
                !showResidenceSwitcher)
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: titleSideInset,
                  ),
                  child: Center(
                    child: _buildTitleSection(
                      title: title,
                      showNavigationControls: showNavigationControls,
                      variant: variant,
                      showResidenceSwitcher: showResidenceSwitcher,
                      currentResidence: showResidenceSwitcher
                          ? (controller.selectedResidence.value?.residenceName ??
                                'Select Residence')
                          : null,
                      onResidenceSwitch: showResidenceSwitcher
                          ? () => _showResidenceSelectorDialog()
                          : null,
                    ),
                  ),
                ),
              ),

            // Right section - positioned on the right
            Positioned(
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                            NotificationsModal.show(
                              Get.context!,
                            );
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
    );

    return PreferredSize(
      preferredSize: Size.fromHeight(toolbarHeight + statusBarHeight),
      child:
          Container(
                height: toolbarHeight + statusBarHeight,
                padding: EdgeInsets.only(top: statusBarHeight),
                decoration: BoxDecoration(
                  color: useOpaqueAppBar
                      ? AppColors.surfaceWhite
                      : AppColors.surfaceWhite.withValues(alpha: 0.95),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.neutralLine200.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  boxShadow: useOpaqueAppBar
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                ),
                child: useOpaqueAppBar
                    ? appBarContent
                    : ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: appBarContent,
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
              color: AppColors.brandSage50.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
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

    // Title — ValueKey forces remount so fadeIn re-runs on every screen
    // change (same behavior Maintenance↔Profile gets from opaque/blur swap).
    if (title != null) {
      return SizedBox(
        key: ValueKey(title),
        width: double.infinity,
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.neutralInk900,
            letterSpacing: -0.3,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNotificationButton({
    required int count,
    required VoidCallback onTap,
  }) {
    return _AnimatedNotificationButton(count: count, onTap: onTap);
  }
}

/// Notification bell with tap-triggered scale animation for clear visual feedback.
class _AnimatedNotificationButton extends StatefulWidget {
  const _AnimatedNotificationButton({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  State<_AnimatedNotificationButton> createState() =>
      _AnimatedNotificationButtonState();
}

class _AnimatedNotificationButtonState extends State<_AnimatedNotificationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
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
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: Accessibility.iconButtonConstraints,
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 30.sp,
                      color: AppColors.brandSage600,
                    ),
                    if (widget.count > 0)
                      Positioned(
                        right: -2.w,
                        top: -2.h,
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth: 14.w,
                            minHeight: 14.w,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 3.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.danger,
                                AppColors.danger.withValues(alpha: 0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.surfaceWhite,
                              width: 1.5.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4.r,
                                offset: Offset(0, 1.h),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.count > 9
                                ? '9+'
                                : widget.count.toString(),
                            style: TextStyle(
                              color: AppColors.surfaceWhite,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    if (widget.count > 0)
                      Positioned(
                        right: -2.w,
                        top: -2.h,
                        child: Container(
                          width: 14.w,
                          height: 14.w,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat())
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
          ),
        ),
      ),
    );
  }
}

extension _MainScaffoldNotification on MainScaffold {
  /// Show residence selector dialog
  void _showResidenceSelectorDialog() {
    Get.dialog(
      Obx(
        () => Builder(
          builder: (dialogContext) => ResponsiveAlertDialog(
            scrollable: controller.residences.isNotEmpty &&
                !controller.isLoadingResidences.value,
            title: Text(
              'select_residence'.tr,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            content: controller.isLoadingResidences.value
                ? ResponsiveAlertDialog.loadingPlaceholder()
                : controller.residences.isEmpty
                ? SizedBox(
                    height: 100.h,
                    child: Center(
                      child: Text(
                        'no_residences_available'.tr,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                : ResponsiveAlertDialog.boundedList(
                    context: dialogContext,
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
                              fontSize: 15.sp,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle:
                              residence.residenceAddress != null &&
                                  residence.residenceAddress!.isNotEmpty
                              ? Text(
                                  residence.residenceAddress!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13.sp),
                                )
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
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'cancel'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
        if (!Get.isRegistered<HubController>()) {
          Get.put(HubController());
        }
        return HubScreen(
          onNavigate: (screen) => controller.navigateToScreenByString(screen),
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
            Future.delayed(const Duration(milliseconds: 300), () {
              MessagePopupController.showSuccess(
                messageKey: message,
                titleKey: 'success',
              );
            });
          },
        );

      case AppScreen.ai:
        // Ensure AiController is initialized
        if (!Get.isRegistered<AiController>()) {
          Get.put(AiController());
        }
        return const AIScreen();

      case AppScreen.chatHub:
        return ChatHubScreen(
          onGroupChat: () => controller.navigateToScreen(AppScreen.chat),
          onAdminChat: () {
            if (Get.isRegistered<PrivateChatController>()) {
              Get.delete<PrivateChatController>();
            }
            controller.navigateToScreen(AppScreen.adminChat);
          },
        );

      case AppScreen.chat:
        if (!Get.isRegistered<ChatController>()) {
          Get.put(ChatController());
        }
        return ChatScreen(
          role: controller.currentUser.value?.role ?? Role.client,
          onBack: () => controller.goBack(),
        );

      case AppScreen.adminChat:
        if (!Get.isRegistered<PrivateChatController>()) {
          Get.put(PrivateChatController());
        }
        return const PrivateChatScreen();

      case AppScreen.tickets:
        if (!Get.isRegistered<TicketsController>()) {
          Get.put(TicketsController());
        }
        return TicketsScreen(onBack: () => controller.goBack());

      // case AppScreen.trustedDevices:
      //   return const TrustedDevicesScreen();

      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    // Home tab always shows HomeScreen. Residence status only affects
    // Construction Progress visibility (handled inside HomeScreen).
    return Obx(() {
      final user = controller.currentUser.value;
      if (user == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.brandSage500),
        );
      }
      controller.ensureHomeResidenceLoaded();
      return const HomeScreen();
    });
  }

  bool _shouldDismissKeyboardFirst(BuildContext context) {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) return true;

    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.hasFocus) return false;

    final focusContext = focus.context;
    if (focusContext == null) return false;

    return focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _isBottomNavVisible() {
    const hideBottomNavScreens = [
      AppScreen.ai,
      AppScreen.smartHome,
      AppScreen.changePassword,
      AppScreen.chatHub,
      AppScreen.chat,
      AppScreen.adminChat,
      AppScreen.tickets,
    ];

    return !hideBottomNavScreens.contains(controller.currentScreen.value);
  }

  Widget _buildFloatingNavBar(double collapseProgress) {
    final tabs = controller.bottomNavTabs;
    final selectedIndex = tabs.indexWhere(
      (tab) => tab.screen == controller.currentScreen.value,
    );

    return FloatingBottomNavBar(
      itemCount: tabs.length,
      selectedIndex: selectedIndex,
      collapseProgress: collapseProgress,
      onItemSelected: (index) =>
          controller.navigateToScreen(tabs[index].screen),
      iconBuilder: (index, isActive) => _buildIcon(tabs[index], isActive),
    );
  }

  Widget _buildIcon(BottomNavTab tab, bool isActive) {
    // Active icon slightly larger than inactive for clear tab affordance.
    final double activeSize = 28.w;
    final double inactiveSize = 24.w;

    // The icon that should NOT change color when active
    bool noColorChange = tab.screen == AppScreen.hubScreen;

    final activeColor = AppColors.neutralInk900;
    final inactiveColor = AppColors.neutralInk900;

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

/// Shrinks the floating nav bar progressively while scrolling down (Instagram-style)
/// and expands it when scrolling up or returning to the top.
/// Uses [NotificationListener] so no child screen needs modification.
class _ScrollAwareBody extends StatefulWidget {
  final bool isNavVisible;
  final AppScreen screenKey;
  final Widget body;
  final Widget Function(double collapseProgress) navBarBuilder;

  const _ScrollAwareBody({
    required this.isNavVisible,
    required this.screenKey,
    required this.body,
    required this.navBarBuilder,
  });

  @override
  State<_ScrollAwareBody> createState() => _ScrollAwareBodyState();
}

class _ScrollAwareBodyState extends State<_ScrollAwareBody> {
  /// 0 = fully expanded, 1 = fully collapsed.
  double _collapseProgress = 0;

  /// Scroll distance (px) required to reach full collapse — higher = subtler, slower shrink.
  static const double _collapseScrollDistance = 220;

  /// Cap so the bar never fully reaches the collapsed end-state (Instagram stays slightly expanded).
  static const double _maxCollapseProgress = 0.65;

  @override
  void didUpdateWidget(_ScrollAwareBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenKey != widget.screenKey && _collapseProgress > 0) {
      setState(() => _collapseProgress = 0);
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (!widget.isNavVisible) return false;

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta != 0) {
        final next = (_collapseProgress + delta / _collapseScrollDistance)
            .clamp(0.0, _maxCollapseProgress);
        if (next != _collapseProgress) {
          setState(() => _collapseProgress = next);
        }
      }
    }

    if (notification is ScrollEndNotification) {
      if (notification.metrics.pixels <= 0 && _collapseProgress > 0) {
        setState(() => _collapseProgress = 0);
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: _KeyboardBottomPadding(
            includeSafeAreaBottom: !widget.isNavVisible,
            child: widget.body,
          ),
        ),
        if (widget.isNavVisible)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                viewInsets: EdgeInsets.zero,
              ),
              child: widget.navBarBuilder(_collapseProgress),
            ),
          ),
      ],
    );
  }
}

/// Applies keyboard bottom inset only to its child so the rest of [MainScaffold]
/// does not rebuild on every IME animation frame.
class _KeyboardBottomPadding extends StatelessWidget {
  const _KeyboardBottomPadding({
    required this.includeSafeAreaBottom,
    required this.child,
  });

  final bool includeSafeAreaBottom;
  final Widget child;

  bool _isRouteObscuredByModal(BuildContext context) {
    final route = ModalRoute.of(context);
    return route != null && !route.isCurrent;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = _isRouteObscuredByModal(context)
        ? 0.0
        : MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = includeSafeAreaBottom && keyboardInset == 0
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset + safeBottom),
      child: child,
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
