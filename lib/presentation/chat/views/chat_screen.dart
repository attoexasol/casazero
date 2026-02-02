import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/permissions.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_message_model.dart';

/// Flutter ChatScreen converted from React ChatScreen.tsx.
/// UI matches React 1:1 (header, message list, input area).
/// Uses GetX ChatController for state management.
class ChatScreen extends GetView<ChatController> {
  final Role role;
  final VoidCallback onBack;

  const ChatScreen({
    super.key,
    required this.role,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(child: _buildMessageList()),
        _buildInputArea(context),
      ],
    );
  }

  /// Header: Group Chat, Online Now, right-side Demo button (light green, gear + Demo).
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.h,
        left: 24.w,
        right: 24.w,
        bottom: 16.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.neutralLine100, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'groupChat'.tr.isEmpty ? 'Group Chat' : 'groupChat'.tr,
                  style: AppTextStyles.CardHeaderText.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralInk900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'onlineNow'.tr.isEmpty ? 'Online Now' : 'onlineNow'.tr,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.neutralInk500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.brandSage100,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.settings,
                      size: 18.sp,
                      color: AppColors.neutralInk900,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Demo',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutralInk900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Obx(() => ListView.builder(
          controller: controller.scrollController,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          itemCount: controller.messages.length,
          itemBuilder: (context, index) {
            final msg = controller.messages[index];
            final isOwnMessage = msg.sender == 'You';
            final showAvatar = index == 0 ||
                controller.messages[index - 1].sender != msg.sender;

            if (msg.type == 'announcement') {
              return _buildAnnouncementCard(msg);
            }

            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                mainAxisAlignment:
                    isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isOwnMessage && showAvatar) _buildAvatar(msg.sender),
                  if (!isOwnMessage && !showAvatar) SizedBox(width: 32.w),
                  if (!isOwnMessage) SizedBox(width: 8.w),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: isOwnMessage
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (showAvatar && !isOwnMessage)
                          Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  msg.sender,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.neutralInk700,
                                  ),
                                ),
                                if (msg.senderRole == 'admin') ...[
                                  SizedBox(width: 6.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandSage100,
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      'Admin',
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.brandSage600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: isOwnMessage
                                ? AppColors.brandSage600
                                : AppColors.surfaceWhite,
                            border: isOwnMessage
                                ? null
                                : Border.all(
                                    color: AppColors.neutralLine200,
                                    width: 1,
                                  ),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Text(
                            msg.content,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 14.sp,
                              height: 1.4,
                              color: isOwnMessage
                                  ? AppColors.surfaceWhite
                                  : AppColors.neutralInk900,
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          controller.formatTime(msg.timestamp),
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11.sp,
                            color: AppColors.neutralInk400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwnMessage) SizedBox(width: 8.w),
                ],
              ),
            );
          },
        ));
  }

  Widget _buildAnnouncementCard(ChatMessage msg) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          border: Border.all(
            color: AppColors.warning.withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              alignment: Alignment.center,
              child: Text('📢', style: TextStyle(fontSize: 14.sp)),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'communityAnnouncement'.tr.isEmpty
                              ? 'Community Announcement'
                              : 'communityAnnouncement'.tr,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.brandSage100,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          msg.sender,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.brandSage600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    msg.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.neutralInk900,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    controller.formatTime(msg.timestamp),
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
      ),
    );
  }

  Widget _buildAvatar(String sender) {
    final initial = sender.isNotEmpty ? sender[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 16.r,
      backgroundColor: AppColors.brandSage300,
      child: Text(
        initial,
        style: AppTextStyles.caption.copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.brandSage600,
        ),
      ),
    );
  }

  /// Input area: paperclip, rounded field "Type a message...", green circular send.
  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.neutralLine200, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Material(
            color: Colors.transparent,
            child: IconButton(
              onPressed: () {},
              icon: Image.asset(
                'assets/images/chat_pin_icon.png',
                width: 22.sp,
                height: 22.sp,
                color: AppColors.neutralInk700,
                colorBlendMode: BlendMode.srcIn,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Container(
              constraints: BoxConstraints(minHeight: 44.h),
              decoration: BoxDecoration(
                color: AppColors.neutralLine100,
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: TextField(
                controller: controller.messageController,
                decoration: InputDecoration(
                  hintText: 'typeMessage'.tr.isEmpty ? 'Type a message...' : 'typeMessage'.tr,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.neutralInk400,
                  ),
                  border: InputBorder.none,
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
                onSubmitted: (_) => controller.handleSend(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GetBuilder<ChatController>(
            id: 'input',
            builder: (_) {
              final hasText = controller.hasMessageText;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasText ? controller.handleSend : null,
                  borderRadius: BorderRadius.circular(22.r),
                  child: Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: AppColors.brandSage500,
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
                    child: Image.asset(
                      'assets/images/chat_send_icon.png',
                      width: 20.sp,
                      height: 20.sp,
                      color: hasText ? AppColors.surfaceWhite : AppColors.surfaceWhite.withOpacity(0.6),
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
