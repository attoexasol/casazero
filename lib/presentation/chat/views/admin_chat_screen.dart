import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/tablet_centered_layout.dart';
import '../controllers/admin_chat_controller.dart';
import '../models/chat_message_model.dart';

/// Direct one-to-one chat between resident and building admin.
/// Firestore: admin_chats/{conversationId}/messages
class AdminChatScreen extends GetView<AdminChatController> {
  const AdminChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TabletCenteredLayout(
      child: Column(
      children: [
        _buildHeader(context),
        Expanded(child: _buildMessageList()),
        _buildInputArea(context),
      ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 16.h,
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
          Container(
            width: 44.w,
            height: 44.w,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD32F2F), Color(0xFFFF7043)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Administrator Support'.tr,
                  style: AppTextStyles.cardHeaderText.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralInk900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  'adminChatSubtitle'.tr,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.neutralInk500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Obx(() {
      final state = controller.chatState.value;
      if (state == AdminChatState.noAuth) {
        return _buildErrorState(
          icon: Icons.chat_bubble_outline,
          title: 'chatUnavailable'.tr,
          subtitle: 'chatUnavailableSubtitle'.tr,
        );
      }
      if (state == AdminChatState.noConversation) {
        return _buildErrorState(
          icon: Icons.home_outlined,
          title: 'chatNotAvailable'.tr,
          subtitle: 'adminChatNoResidence'.tr,
        );
      }
      if (state == AdminChatState.permissionDenied) {
        return _buildErrorState(
          icon: Icons.lock_outline,
          title: 'accessDenied'.tr,
          subtitle: 'adminChatAccessDenied'.tr,
        );
      }
      if (state == AdminChatState.networkError) {
        return _buildErrorState(
          icon: Icons.wifi_off,
          title: 'connectionIssue'.tr,
          subtitle: 'checkNetworkAndRetry'.tr,
        );
      }
      if (state != AdminChatState.ready && state != AdminChatState.initial) {
        return _buildErrorState(
          icon: Icons.error_outline,
          title: 'something_went_wrong'.tr,
          subtitle: 'tryAgainLater'.tr,
        );
      }

      return _buildMessageStream();
    });
  }

  Widget _buildErrorState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.sp, color: AppColors.neutralInk400),
            SizedBox(height: 16.h),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.neutralInk700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.neutralInk500,
                fontSize: 13.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStream() {
    if (!controller.isFirebaseSignedIn) {
      return _buildErrorState(
        icon: Icons.chat_bubble_outline,
        title: 'chatUnavailable'.tr,
        subtitle: 'chatUnavailableSubtitle'.tr,
      );
    }

    return StreamBuilder<List<ChatMessage>>(
      stream: controller.messagesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.danger),
          );
        }
        if (snapshot.hasError) {
          final err = snapshot.error.toString().toLowerCase();
          final isPermission = err.contains('permission');
          return _buildErrorState(
            icon: Icons.error_outline,
            title: isPermission ? 'accessDenied'.tr : 'connectionIssue'.tr,
            subtitle: isPermission
                ? 'adminChatAccessDenied'.tr
                : 'checkNetworkAndRetry'.tr,
          );
        }
        final messages = snapshot.data ?? [];
        if (messages.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mark_chat_unread_outlined,
                    size: 48.sp,
                    color: AppColors.neutralInk300,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'adminChatEmpty'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutralInk500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          controller: controller.scrollController,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isOwn = controller.isOwnMessage(msg.senderId);
            final isFromAdmin = controller.isAdminMessage(msg);

            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                mainAxisAlignment:
                    isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isOwn) ...[
                    _buildAdminAvatar(),
                    SizedBox(width: 8.w),
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment: isOwn
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!isOwn)
                          Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isFromAdmin
                                      ? 'admin'.tr
                                      : msg.senderName,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.neutralInk700,
                                  ),
                                ),
                                if (isFromAdmin) ...[
                                  SizedBox(width: 6.w),
                                  _buildRoleBadge('admin'.tr),
                                ],
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
                            msg.text,
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
                          controller.formatTime(msg.createdAt),
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
          },
        );
      },
    );
  }

  Widget _buildAdminAvatar() {
    return CircleAvatar(
      radius: 16.r,
      backgroundColor: const Color(0xFF6B8E23),
      child: Icon(
        Icons.support_agent,
        size: 16.sp,
        color: Colors.white,
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

  Widget _buildInputArea(BuildContext context) {
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
                  controller: controller.messageController,
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
                  onSubmitted: (_) => controller.sendTextMessage(),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GetBuilder<AdminChatController>(
            id: 'input',
            builder: (_) {
              final hasText = controller.hasMessageText;
              return Obx(() {
                final sending = controller.isSending.value;
                final canSend =
                    hasText && !sending && controller.isFirebaseSignedIn;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canSend ? controller.sendTextMessage : null,
                    borderRadius: BorderRadius.circular(22.r),
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: sending
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
                );
              });
            },
          ),
        ],
      ),
    );
  }
}
