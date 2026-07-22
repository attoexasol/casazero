import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/tablet_centered_layout.dart';
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
      final pendingExpandId = controller.pendingExpandTicketId.value;
      if (pendingExpandId != null && pendingExpandId.isNotEmpty) {
        _expandedTicketId.value = pendingExpandId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.pendingExpandTicketId.value == pendingExpandId) {
            controller.pendingExpandTicketId.value = null;
          }
        });
      }
      return TabletCenteredLayout(
        child: Column(
        children: [
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
                          if (controller.allTickets.isEmpty) _buildEmptyState(),
                          ...controller.allTickets.map((t) => TicketCard(
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
        ),
      );
    });
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
