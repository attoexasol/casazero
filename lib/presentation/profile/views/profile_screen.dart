import 'package:casazero/core/widgets/logout_section.dart';
import 'package:casazero/core/widgets/notification_settings_card.dart';
import 'package:casazero/core/widgets/preferences_card.dart';
import 'package:casazero/core/widgets/profile_header_card.dart';
import 'package:casazero/core/widgets/residence_info_card.dart';
import 'package:casazero/core/widgets/security_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/floating_bottom_nav_bar.dart';
import '../../../core/widgets/tablet_centered_layout.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;
  final VoidCallback onLogout;
  final Function(String) onNavigate;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    // Get ProfileController instance
    final profileController = Get.find<ProfileController>();
    
    // NO SCAFFOLD/APPBAR - This screen is wrapped by MainScaffold
    // Same effective background as Documents: MainScaffold white + theme surface;
    // backgroundColor avoids RefreshIndicator using a non-white Material surface.
    return RefreshIndicator(
      onRefresh: () => profileController.refreshData(),
      color: AppColors.brandSage500,
      backgroundColor: AppColors.surfaceWhite,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even when content doesn't scroll
        padding: FloatingBottomNavBar.screenPadding(context),
        child: TabletCenteredLayout(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
                children: [
                  ProfileHeaderCard(user: user),
                  SizedBox(height: 24.h),
                  Obx(
                    () => ResidenceInfoCard(
                      user: profileController.user.value ?? user,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SecurityCard(user: user, onNavigate: onNavigate),
                  SizedBox(height: 16.h),
                  PreferencesCard(user: user),
                  SizedBox(height: 16.h),
                  NotificationSettingsCard(user: user),
                  SizedBox(height: 16.h),
                  LogoutSection(onLogoutTap: onLogout),
                ],
              ),
            ),
          ),
      ),
    );
  }

// ... rest of your profile widgets
}