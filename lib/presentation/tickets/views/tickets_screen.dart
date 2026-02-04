import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/tickets_controller.dart';
import '../models/ticket_model.dart';

/// Flutter TicketsScreen converted from React TicketsScreen.tsx.
/// UI matches React 1:1 (filter tabs, Create Ticket button, ticket cards).
class TicketsScreen extends GetView<TicketsController> {
  final VoidCallback onBack;

  const TicketsScreen({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final permissions = controller.permissions;
      return Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (permissions.canCreateTickets) _buildCreateTicketButton(),
                  if (permissions.canCreateTickets) SizedBox(height: 16.h),
                  if (controller.filteredTickets.isEmpty) _buildEmptyState(),
                  ...controller.filteredTickets.map((t) => _buildTicketCard(t)),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Filter tabs: All / Open / In Progress / Resolved — pill style, active green.
  Widget _buildFilterTabs() {
    final tabs = ['all', 'open', 'in-progress', 'resolved'];
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
  Widget _buildCreateTicketButton() {
    final label = 'createTicket'.tr;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
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
              Icon(LucideIcons.plus, size: 18.sp, color: AppColors.surfaceWhite),
              SizedBox(width: 8.w),
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

  /// Single ticket card: category pill, status pill, title, description, meta row, update box, View Details.
  Widget _buildTicketCard(TicketModel ticket) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.neutralLine200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildCategoryPill(ticket.category),
                    const Spacer(),
                    _buildStatusPill(ticket.status),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  ticket.title,
                  style: AppTextStyles.CardHeaderText.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralInk900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  ticket.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.neutralInk500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetaRow(ticket),
                if (ticket.status == 'in-progress') _buildUpdateBox(ticket),
                if (ticket.status == 'resolved') _buildResolvedBox(ticket),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.neutralLine200)),
              ),
              padding: EdgeInsets.only(top: 12.h),
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.neutralLine100,
                  foregroundColor: AppColors.neutralInk900,
                  side: BorderSide(color: AppColors.neutralLine200),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  'viewDetails'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutralInk700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String category) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.brandSage100,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        category,
        style: AppTextStyles.caption.copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.brandSage600,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color textColor;
    String label;
    switch (status) {
      case 'open':
        bg = AppColors.neutralLine100;
        textColor = AppColors.neutralInk700;
        label = 'open'.tr;
        break;
      case 'in-progress':
        bg = AppColors.info.withOpacity(0.15);
        textColor = AppColors.info;
        label = 'inProgress'.tr;
        break;
      case 'resolved':
        bg = AppColors.success.withOpacity(0.15);
        textColor = AppColors.success;
        label = 'resolved'.tr;
        break;
      default:
        bg = AppColors.neutralLine100;
        textColor = AppColors.neutralInk700;
        label = status;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMetaRow(TicketModel ticket) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 6.h,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.clock, size: 14.sp, color: AppColors.neutralInk500),
              SizedBox(width: 4.w),
              Text(
                'ticketCreated'.tr.replaceAll('{date}', ticket.created),
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.neutralInk500,
                ),
              ),
            ],
          ),
          if (ticket.attachments != null && ticket.attachments! > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.image, size: 14.sp, color: AppColors.neutralInk500),
                SizedBox(width: 4.w),
                Text(
                  (ticket.attachments! > 1
                          ? 'ticketPhotosPlural'.tr
                          : 'ticketPhotos'.tr)
                      .replaceAll('{count}', ticket.attachments.toString()),
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.neutralInk500,
                  ),
                ),
              ],
            ),
          if (ticket.updates != null && ticket.updates! > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.messageCircle, size: 14.sp, color: AppColors.neutralInk500),
                SizedBox(width: 4.w),
                Text(
                  (ticket.updates! > 1
                          ? 'ticketUpdates'.tr
                          : 'ticketUpdate'.tr)
                      .replaceAll('{count}', ticket.updates.toString()),
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.neutralInk500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUpdateBox(TicketModel ticket) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Text(
        'technicianUpdate'.tr,
        style: AppTextStyles.caption.copyWith(
          fontSize: 12.sp,
          color: AppColors.info,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildResolvedBox(TicketModel ticket) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16.sp, color: AppColors.success),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'resolvedIssueFixed'.tr.replaceAll('{date}', ticket.updated),
              style: AppTextStyles.caption.copyWith(
                fontSize: 12.sp,
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
