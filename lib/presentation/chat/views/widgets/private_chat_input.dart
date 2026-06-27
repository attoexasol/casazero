import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class PrivateChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool canSend;
  final VoidCallback onSend;

  const PrivateChatInput({
    super.key,
    required this.controller,
    required this.isSending,
    required this.canSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final inputRadius = BorderRadius.circular(22.r);
    final enabledBorder = OutlineInputBorder(
      borderRadius: inputRadius,
      borderSide: BorderSide(
        color: AppColors.danger.withValues(alpha: 0.55),
        width: 1.5,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: inputRadius,
      borderSide: const BorderSide(
        color: AppColors.danger,
        width: 2,
      ),
    );

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomSafe =
        keyboardOpen ? 0.0 : MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        12.h,
        16.w,
        12.h + bottomSafe,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          top: BorderSide(color: AppColors.neutralLine200, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 44.h),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: AppColors.danger,
                    selectionColor: AppColors.danger.withValues(alpha: 0.25),
                    selectionHandleColor: AppColors.danger,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  cursorColor: AppColors.danger,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.neutralLine100,
                    hintText: 'typeMessage'.tr,
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.neutralInk400,
                    ),
                    border: enabledBorder,
                    enabledBorder: enabledBorder,
                    focusedBorder: focusedBorder,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.neutralInk900,
                  ),
                  maxLines: 4,
                  minLines: 1,
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canSend ? onSend : null,
              borderRadius: BorderRadius.circular(22.r),
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: isSending
                    ? SizedBox(
                        width: 20.sp,
                        height: 20.sp,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
