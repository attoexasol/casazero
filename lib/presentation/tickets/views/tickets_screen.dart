import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/tickets_controller.dart';
import '../widgets/ticket_card.dart';
import 'create_ticket_dialog.dart';

/// Flutter TicketsScreen converted from React TicketsScreen.tsx.
/// UI matches React 1:1 (filter tabs, Create Ticket button, ticket cards).
class TicketsScreen extends GetView<TicketsController> {
  final VoidCallback onBack;
  final Rxn<String> _expandedTicketId = Rxn<String>();

  TicketsScreen({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final permissions = controller.permissions;
      final isLoading = controller.isLoadingTickets.value;
      return Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandSage600,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: controller.fetchMyTickets,
                    color: AppColors.brandSage600,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h + MediaQuery.of(context).padding.bottom),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (permissions.canCreateTickets) _buildCreateTicketButton(context),
                          if (permissions.canCreateTickets) SizedBox(height: 16.h),
                          if (controller.filteredTickets.isEmpty) _buildEmptyState(),
                          ...controller.filteredTickets.map((t) => TicketCard(
                                ticket: t,
                                categoryDisplayName: controller.localizedIssueTypeName(
                                  t.issueTypeId,
                                  t.category,
                                ),
                                isExpanded: _expandedTicketId.value == t.id,
                                onToggleExpand: () {
                                  if (_expandedTicketId.value == t.id) {
                                    _expandedTicketId.value = null;
                                  } else {
                                    _expandedTicketId.value = t.id;
                                  }
                                },
                              )),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }

  /// Filter tabs: All / Open / In Progress / Resolved — pill style, active green.
  Widget _buildFilterTabs() {
    final tabs = controller.availableFilters;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppColors.neutralLine100)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: tabs.map((f) {
            final isActive = controller.filter.value == f;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.setFilter(f),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.brandSage600
                          : AppColors.surfaceWhite,
                      border: Border.all(
                        color: isActive
                            ? AppColors.brandSage600
                            : AppColors.neutralLine200,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      controller.tabLabel(f),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? AppColors.surfaceWhite
                            : AppColors.neutralInk700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Full-width green "+ Create Ticket" button.
  Widget _buildCreateTicketButton(BuildContext context) {
    final label = 'createTicket'.tr;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (_) => const CreateTicketDialog(),
          );
        },
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.brandSage500,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon(LucideIcons.plus, size: 18.sp, color: AppColors.surfaceWhite),
              // SizedBox(width: 8.w),
              Text(
                label,
                style: AppTextStyles.button.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.surfaceWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48.sp, color: AppColors.neutralInk400),
          SizedBox(height: 16.h),
          Text(
            'noTicketsInCategory'.tr,
            style: AppTextStyles.CardHeaderText.copyWith(
              fontSize: 16.sp,
              color: AppColors.neutralInk900,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'createNewTicketIfNeeded'.tr,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14.sp,
              color: AppColors.neutralInk500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
