import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/image_url_builder.dart';
import '../../../../data/models/private_chat_message.dart';

class PrivateChatBubble extends StatelessWidget {
  final PrivateChatMessage message;
  final bool isOwn;
  final bool isFromAdmin;
  final String senderLabel;
  final String timeLabel;
  final String? profileImageUrl;

  const PrivateChatBubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.isFromAdmin,
    required this.senderLabel,
    required this.timeLabel,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment:
            isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn) ...[
            _buildAvatar(),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwn)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFromAdmin)
                          _buildRoleBadge('admin'.tr)
                        else
                          Text(
                            senderLabel,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.neutralInk700,
                            ),
                          ),
                      ],
                    ),
                  ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: isOwn
                        ? AppColors.brandSage600
                        : AppColors.surfaceWhite,
                    border: isOwn
                        ? null
                        : Border.all(
                            color: AppColors.neutralLine200,
                            width: 1,
                          ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    message.text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14.sp,
                      height: 1.4,
                      color: isOwn
                          ? AppColors.surfaceWhite
                          : AppColors.neutralInk900,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  timeLabel,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.neutralInk400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final url = ImageUrlBuilder.buildResidenceImageUrl(profileImageUrl);
    if (url.isNotEmpty) {
      return CircleAvatar(
        radius: 16.r,
        backgroundImage: NetworkImage(url),
      );
    }
    final initial =
        senderLabel.isNotEmpty ? senderLabel[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 16.r,
      backgroundColor: const Color(0xFF6B8E23),
      child: Text(
        initial,
        style: AppTextStyles.caption.copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.surfaceWhite,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.brandSage100,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.brandSage600,
        ),
      ),
    );
  }
}
