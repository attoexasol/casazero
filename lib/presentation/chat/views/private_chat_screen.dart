import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/private_chat_controller.dart';
import '../providers/private_chat_provider.dart';
import 'widgets/private_chat_bubble.dart';
import 'widgets/private_chat_input.dart';

/// Direct one-to-one chat between resident and building admin.
/// Firestore: conversations/{conversationId}/messages
class PrivateChatScreen extends GetView<PrivateChatController> {
  const PrivateChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Get.find<PrivateChatProvider>();

    return Column(
      children: [
        Obx(() => _buildHeader(context, provider)),
        Expanded(child: _buildMessageList(provider)),
        _buildInputArea(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, PrivateChatProvider provider) {
    final adminName = _displayAdminName(provider);
    final residenceName = provider.residenceName;
    final isOnline = provider.adminOnline.value;

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
          Stack(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: const Color(0xFFFFEBEE),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.danger,
                  size: 24.sp,
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: AppColors.brandSage500,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceWhite,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  adminName,
                  style: AppTextStyles.CardHeaderText.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralInk900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  residenceName.isNotEmpty
                      ? residenceName
                      : 'adminChatSubtitle'.tr,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.neutralInk500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(PrivateChatProvider provider) {
    return Obx(() {
      final state = controller.chatState.value;
      if (state == PrivateChatState.noAuth) {
        return _buildErrorState(
          icon: Icons.chat_bubble_outline,
          title: 'chatUnavailable'.tr,
          subtitle: 'chatUnavailableSubtitle'.tr,
        );
      }
      if (state == PrivateChatState.noAdmin) {
        return _buildErrorState(
          icon: Icons.person_outline,
          title: 'chatNotAvailable'.tr,
          subtitle: 'adminChatNoResidence'.tr,
        );
      }
      if (state == PrivateChatState.permissionDenied) {
        return _buildErrorState(
          icon: Icons.lock_outline,
          title: 'accessDenied'.tr,
          subtitle: 'adminChatAccessDenied'.tr,
        );
      }
      if (state == PrivateChatState.networkError) {
        return _buildErrorState(
          icon: Icons.wifi_off,
          title: 'connectionIssue'.tr,
          subtitle: 'checkNetworkAndRetry'.tr,
        );
      }
      if (state == PrivateChatState.indexPending) {
        return _buildErrorState(
          icon: Icons.sync,
          title: 'connectionIssue'.tr,
          subtitle: 'privateChatIndexPending'.tr,
        );
      }
      if (controller.isOpening.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.danger),
        );
      }
      if (state != PrivateChatState.ready && state != PrivateChatState.initial) {
        return _buildErrorState(
          icon: Icons.error_outline,
          title: 'something_went_wrong'.tr,
          subtitle: 'tryAgainLater'.tr,
        );
      }

      return _buildMessageStream(provider);
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
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _displayAdminName(PrivateChatProvider provider) {
    return provider.adminName == 'Administrator Support'
        ? provider.adminName.tr
        : provider.adminName;
  }

  Widget _buildMessageStream(PrivateChatProvider provider) {
    if (!controller.isFirebaseSignedIn) {
      return _buildErrorState(
        icon: Icons.chat_bubble_outline,
        title: 'chatUnavailable'.tr,
        subtitle: 'chatUnavailableSubtitle'.tr,
      );
    }

    return Obx(() {
      if (controller.isLoadingMessages.value && controller.messages.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.danger),
        );
      }

      final messages = controller.messages;
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
          final isOwn = controller.isOwnMessage(msg);
          final isFromAdmin = controller.isAdminMessage(msg);

          return PrivateChatBubble(
            message: msg,
            isOwn: isOwn,
            isFromAdmin: isFromAdmin,
            senderLabel: _displayAdminName(provider),
            timeLabel: controller.formatTime(msg.createdAt),
            profileImageUrl: null,
          );
        },
      );
    });
  }

  Widget _buildInputArea(BuildContext context) {
    return GetBuilder<PrivateChatController>(
      id: 'input',
      builder: (_) {
        final hasText = controller.hasMessageText;
        return Obx(() {
          final sending = controller.isSending.value;
          final canSend =
              hasText && !sending && controller.isFirebaseSignedIn;
          return PrivateChatInput(
            controller: controller.messageController,
            isSending: sending,
            canSend: canSend,
            onSend: controller.sendTextMessage,
          );
        });
      },
    );
  }
}
