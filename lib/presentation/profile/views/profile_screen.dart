import 'package:casazero/core/widgets/logout_section.dart';
import 'package:casazero/core/widgets/notification_settings_card.dart';
import 'package:casazero/core/widgets/preferences_card.dart';
import 'package:casazero/core/widgets/profile_header_card.dart';
import 'package:casazero/core/widgets/residence_info_card.dart';
import 'package:casazero/core/widgets/security_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/floating_bottom_nav_bar.dart';
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
        padding: FloatingBottomNavBar.scrollBottomPadding(context),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Profile header
              ProfileHeaderCard(user: user),
              const SizedBox(height: 24),

              // Profile sections
              ResidenceInfoCard(user: user),
              const SizedBox(height: 16),
              SecurityCard(user: user, onNavigate: onNavigate),
              const SizedBox(height: 16),
              PreferencesCard(user: user),
              const SizedBox(height: 16),
              NotificationSettingsCard(user: user),
              const SizedBox(height: 16),
              LogoutSection(onLogoutTap: onLogout),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    // Your existing profile header implementation
    return Container();
  }

// ... rest of your profile widgets
}