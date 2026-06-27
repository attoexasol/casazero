// presentation/trusted_devices/screens/trusted_devices_screen.dart
// Converted from React to Flutter - Matches React design exactly

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/localization/app_translations.dart';
import '../controllers/trusted_devices_controller.dart';
import '../../../data/models/trusted_device_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/tablet_centered_layout.dart';

import 'package:flutter_animate/flutter_animate.dart';

class TrustedDevicesScreen extends GetView<TrustedDevicesController> {
  const TrustedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabletCenteredLayout(
              child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.devices.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: controller.refreshDevices,
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 24.h,
                  ),
                  children: [
                    _buildSecurityNotice(),
                    SizedBox(height: 16.h),
                    ..._buildDevicesList(),
                  ],
                ),
              );
            }),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutralLine200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: Icon(Icons.chevron_left, size: 24.sp),
                color: AppColors.neutralInk900,
                onPressed: () => Get.back(),
              ),

              SizedBox(width: 8.w),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'trusted_devices'.tr,
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.neutralInk900,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'manage_your_devices'.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutralInk500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Security Notice - Matches React gradient card with shield icon
  Widget _buildSecurityNotice() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF0FDF4), // brand-sage-50
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shield icon
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7), // brand-sage-100
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 20.sp,
              color: const Color(0xFF16A34A), // brand-sage-600
            ),
          ),
          SizedBox(width: 12.w),
          // Info text
          Expanded(
            child: Text(
              AppTranslations.trustedDevicesInfo.tr,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF374151), // neutral-ink-700
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  /// Build devices list with animations
  List<Widget> _buildDevicesList() {
    return controller.devices.asMap().entries.map((entry) {
      final index = entry.key;
      final device = entry.value;

      return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: _buildDeviceCard(device, index),
          )
          .animate()
          .fadeIn(
            duration: 300.ms,
            delay: Duration(milliseconds: index * 100),
          )
          .slideY(begin: 0.2, end: 0);
    }).toList();
  }

  /// Device Card - Matches React expandable card design
  Widget _buildDeviceCard(TrustedDeviceModel device, int index) {
    final isCurrentDevice = controller.currentDevice?.id == device.id;
    final isActive = device.isActive && device.isTrustedValid;

    return Obx(() {
      final isExpanded =
          controller.expandedDeviceId.value == device.id.toString();

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Device Header - Clickable
            InkWell(
              onTap: () {
                controller.expandedDeviceId.value = isExpanded
                    ? ''
                    : device.id.toString();
              },
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12.r),
                bottom: isExpanded ? Radius.zero : Radius.circular(12.r),
              ),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12.r),
                    bottom: isExpanded ? Radius.zero : Radius.circular(12.r),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Device Icon
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: isCurrentDevice
                            ? const Color(0xFFDCFCE7) // brand-sage-100
                            : const Color(0xFFF3F4F6), // neutral-line-100
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        _getDeviceIcon(device.platform),
                        size: 20.sp,
                        color: isCurrentDevice
                            ? const Color(0xFF16A34A) // brand-sage-600
                            : const Color(0xFF6B7280), // neutral-ink-500
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // Device Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Device name and badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  device.deviceName,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              if (isCurrentDevice) ...[
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981), // success
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    AppTranslations.currentDevice.tr,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 8.h),
                          // Location
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14.sp,
                                color: const Color(0xFF6B7280),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Obx(() {
                                  final location = controller.getDeviceLocation(
                                    device,
                                  );
                                  return Text(
                                    location,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          // Last Active
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14.sp,
                                color: const Color(0xFF6B7280),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  '${AppTranslations.lastActive.tr}: ${controller.getLastLoginTime(device)}',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded Activity Section
            if (isExpanded)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAF9), // surface-warm-50
                    border: Border(
                      top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12.r),
                    ),
                  ),
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recent Activity Header
                      Text(
                        AppTranslations.recentActivity.tr,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // Activity Items (mock data for now)
                      _buildActivityItem(
                        action: 'Logged in',
                        timestamp: controller.getLastLoginTime(device),
                        location: controller.getDeviceLocation(device),
                        index: 0,
                      ),
                      if (device.lastIp != null) ...[
                        SizedBox(height: 12.h),
                        _buildActivityItem(
                          action: 'IP: ${device.lastIp}',
                          timestamp: controller.getTrustedUntilStatus(device),
                          location: 'Platform: ${device.platformName}',
                          index: 1,
                        ),
                      ],

                      // Remove Device Button (only if not current device)
                      if (!isCurrentDevice && isActive) ...[
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => controller.revokeDevice(device),
                            icon: Icon(
                              Icons.delete_outline,
                              size: 16.sp,
                              color: const Color(0xFFEF4444), // danger
                            ),
                            label: Text(
                              AppTranslations.removeDevice.tr,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFEF4444),
                                width: 1,
                              ),
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ).animate().fadeIn().slideY(begin: -0.05, end: 0),
          ],
        ),
      );
    });
  }

  /// Activity Item - Matches React activity log design
  Widget _buildActivityItem({
    required String action,
    required String timestamp,
    required String location,
    required int index,
  }) {
    return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot indicator
            Container(
              width: 8.w,
              height: 8.w,
              margin: EdgeInsets.only(top: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80), // brand-sage-400
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12.w),
            // Activity details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF111827), // neutral-ink-900
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12.sp,
                        color: const Color(0xFF6B7280),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        timestamp,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF6B7280),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 100))
        .slideX(begin: -0.1, end: 0);
  }

  /// Empty State - Matches React empty state design
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(48.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), // neutral-line-100
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smartphone,
                size: 32.sp,
                color: const Color(0xFF9CA3AF), // neutral-ink-400
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              AppTranslations.noTrustedDevices.tr,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              AppTranslations.noTrustedDevicesDesc.tr,
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1, 1),
    );
  }

  /// Get device icon based on platform
  IconData _getDeviceIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'mobile':
      case 'android':
      case 'ios':
        return Icons.smartphone;
      case 'desktop':
      case 'windows':
      case 'macos':
      case 'linux':
        return Icons.computer;
      case 'tablet':
      case 'ipad':
        return Icons.tablet;
      default:
        return Icons.devices;
    }
  }
}
