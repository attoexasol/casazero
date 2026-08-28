import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/tablet_centered_layout.dart';
import 'widgets/chat_option_card.dart';

/// Intermediate screen: choose group chat or direct admin chat.
class ChatHubScreen extends StatelessWidget {
  final VoidCallback onGroupChat;
  final VoidCallback onAdminChat;

  const ChatHubScreen({
    super.key,
    required this.onGroupChat,
    required this.onAdminChat,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = _horizontalPadding(width);

        return TabletCenteredLayout(
          child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 24.h),
              // Padding(
              //   padding: horizontalPadding,
              //   child: Text(
              //   'ChatHubTitle'.tr,
              //     style: const TextStyle(
              //       fontSize: 22,
              //       fontWeight: FontWeight.w600,
              //       color: Color(0xFF1A1A1A),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 8),
              Padding(
                padding: horizontalPadding,
                child: Text(
                  'chatHubSubtitle'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.45,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 28.h),
              Padding(
                padding: horizontalPadding,
                child: Column(
                  children: [
                    ChatOptionCard(
                      title: 'groupChat'.tr,
                      subtitle: 'groupChatDesc'.tr,
                      icon: Icons.groups_rounded,
                      gradient: const [
                        AppColors.brandSage600,
                        AppColors.brandSage500,
                      ],
                      bgGradient: const [
                        AppColors.brandSage50,
                        AppColors.brandSage100,
                      ],
                      shadowColor: const Color(0x4D4CAF47),
                      hoverColor: AppColors.brandSage500,
                      index: 0,
                      onTap: onGroupChat,
                    ),
                    SizedBox(height: 16.h),
                    ChatOptionCard(
                      title: 'chatWithAdmin'.tr,
                      subtitle: 'chatWithAdminDesc'.tr,
                      icon: Icons.admin_panel_settings,
                      gradient: const [Color(0xFFD32F2F), Color(0xFFFF7043)],
                      bgGradient: const [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
                      shadowColor: const Color(0x4DD32F2F),
                      hoverColor: AppColors.danger,
                      index: 1,
                      onTap: onAdminChat,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              Padding(
                padding: horizontalPadding,
                child: _buildInfoBanner(),
              ),
                ],
              ),
            ),
        );
      },
    );
  }

  EdgeInsets _horizontalPadding(double width) {
    if (width >= 1100) return EdgeInsets.symmetric(horizontal: 120.w);
    if (width >= 800) return EdgeInsets.symmetric(horizontal: 80.w);
    if (width >= 600) return EdgeInsets.symmetric(horizontal: 40.w);
    return EdgeInsets.symmetric(horizontal: 24.w);
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          //colors: [Color(0xFFEFF8E6), Color(0xFFF3FBEA)],
          colors: [ Color(0xFFE6F9FB), Color(0xFFF0FDFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6B8E23).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                //colors: [Color(0xFF6B8E23), Color(0xFF9ACD32)],
                colors: [ Color(0xFF26C6DA), Color(0xFF80DEEA)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'chatHubInfo'.tr,
              style: TextStyle(fontSize: 13.sp, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}
