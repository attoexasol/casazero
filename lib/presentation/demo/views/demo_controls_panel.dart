// lib/presentation/demo/views/demo_controls_panel.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/demo_controller.dart';

/// Figma panel: width ~320, fill #FAFAF7, stroke #E6E6E6 1.24, drop shadow.
/// Right-edge rounded corners per design.
const double _kPanelWidth = 320;
const Color _kPanelFill = Color(0xFFFAFAF7);
const Color _kPanelStroke = Color(0xFFE6E6E6);
const double _kPanelStrokeWidth = 1.24;

class DemoControlsPanel extends GetView<DemoController> {
  const DemoControlsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kPanelWidth,
      decoration: BoxDecoration(
        color: _kPanelFill,
        border: Border(
          left: BorderSide(color: _kPanelStroke, width: _kPanelStrokeWidth),
          top: BorderSide(color: _kPanelStroke, width: _kPanelStrokeWidth),
          bottom: BorderSide(color: _kPanelStroke, width: _kPanelStrokeWidth),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: SafeArea(
        left: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserRoleSection(),
                    const SizedBox(height: 24),
                    _buildPropertyStatusSection(),
                    const SizedBox(height: 24),
                    _buildNoteBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'demo_controls'.tr,
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralInk900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'demo_controls_subtitle'.tr,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    color: AppColors.neutralInk500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: controller.closePanel,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 24,
                color: AppColors.neutralInk700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRoleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'demo_user_role'.tr,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.neutralInk900,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => _buildRoleCard(
              role: DemoUserRole.residentClient,
              icon: Icons.person_outline,
              titleKey: 'demo_resident_client',
              subtitleKey: 'demo_standard_user_access',
            )),
        const SizedBox(height: 8),
        Obx(() => _buildRoleCard(
              role: DemoUserRole.administrator,
              icon: Icons.people_outline,
              titleKey: 'administrator',
              subtitleKey: 'demo_manage_properties',
            )),
      ],
    );
  }

  Widget _buildRoleCard({
    required DemoUserRole role,
    required IconData icon,
    required String titleKey,
    required String subtitleKey,
  }) {
    final isActive = controller.selectedRole.value == role;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.setRole(role),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.brandSage50 : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.brandSage600 : AppColors.neutralLine200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? AppColors.brandSage600 : AppColors.neutralInk700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleKey.tr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutralInk900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleKey.tr,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.neutralInk500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive) _buildActiveBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'demo_property_status'.tr,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.neutralInk900,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => _buildStatusCard(
              status: DemoPropertyStatus.completed,
              icon: Icons.home_outlined,
              titleKey: 'completed',
              subtitleKey: 'demo_move_in_ready',
            )),
        const SizedBox(height: 8),
        Obx(() => _buildStatusCard(
              status: DemoPropertyStatus.underConstruction,
              icon: Icons.construction_outlined,
              titleKey: 'under_construction',
              subtitleKey: 'demo_building_in_progress',
            )),
      ],
    );
  }

  Widget _buildStatusCard({
    required DemoPropertyStatus status,
    required IconData icon,
    required String titleKey,
    required String subtitleKey,
  }) {
    final isActive = controller.selectedStatus.value == status;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.setPropertyStatus(status),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.brandSage50 : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.brandSage600 : AppColors.neutralLine200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? AppColors.brandSage600 : AppColors.neutralInk700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleKey.tr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutralInk900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleKey.tr,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.neutralInk500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive) _buildActiveBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandSage600,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'active'.tr,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.surfaceWhite,
        ),
      ),
    );
  }

  Widget _buildNoteBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        'demo_note'.tr,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 12,
          color: AppColors.neutralInk700,
          height: 1.45,
        ),
      ),
    );
  }
}
