import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/ticket_model.dart';

class TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final String categoryDisplayName;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.categoryDisplayName,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
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
                    _buildCategoryPill(categoryDisplayName),
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
                _buildMetaRow(),
                if (ticket.status == 'in-progress') _buildUpdateBox(),
                if (ticket.status == 'resolved') _buildResolvedBox(),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedSection(),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOut,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.neutralLine200),
                ),
              ),
              padding: EdgeInsets.only(top: 12.h),
              child: OutlinedButton(
                onPressed: onToggleExpand,
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

  Widget _buildExpandedSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: AppColors.neutralLine200, height: 1),
          SizedBox(height: 12.h),
          if (ticket.priority != null && ticket.priority!.isNotEmpty)
            _buildDetailRow(Icons.flag_outlined, ticket.priority!),
          if (ticket.createdBy != null && ticket.createdBy!.isNotEmpty)
            _buildDetailRow(Icons.person_outline, ticket.createdBy!),
          // if (ticket.updated.isNotEmpty)
          //   _buildDetailRow(Icons.calendar_today_outlined, ticket.updated),
          if (ticket.imageUrl != null) ...[
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openPhotoViewer(ticket.imageUrl!),
                icon: Icon(Icons.photo_outlined, size: 16.sp),
                label: Text(
                  'View Photo',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.neutralLine100,
                  foregroundColor: AppColors.neutralInk700,
                  side: BorderSide(color: AppColors.neutralLine200),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: AppColors.neutralInk500),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13.sp,
                color: AppColors.neutralInk700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPhotoViewer(String imageUrl) {
    Get.dialog(
      Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierColor: Colors.black87,
      useSafeArea: false,
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
      case 'pending':
        bg = AppColors.warning.withOpacity(0.15);
        textColor = AppColors.warning;
        label = 'pending'.tr;
        break;
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

  Widget _buildMetaRow() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 6.h,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14.sp,
                color: AppColors.neutralInk500,
              ),
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
                Icon(
                  Icons.photo_library_outlined,
                  size: 14.sp,
                  color: AppColors.neutralInk500,
                ),
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
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14.sp,
                  color: AppColors.neutralInk500,
                ),
                SizedBox(width: 4.w),
                Text(
                  (ticket.updates! > 1 ? 'ticketUpdates'.tr : 'ticketUpdate'.tr)
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

  Widget _buildUpdateBox() {
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

  Widget _buildResolvedBox() {
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
