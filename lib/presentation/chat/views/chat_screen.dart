import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/permissions.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_message_model.dart';

/// Text-only real-time chat using Firestore. No mock data.
class ChatScreen extends GetView<ChatController> {
  final Role role;
  final VoidCallback onBack;

  const ChatScreen({super.key, required this.role, required this.onBack});

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
                Obx(() => Text(
                  controller.residenceName.value,
                  style: AppTextStyles.CardHeaderText.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralInk900,
                  ),
                )),
                SizedBox(height: 2.h),
                Text(
                  'onlineNow'.tr,
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

  Widget _buildMessageList() {
    return Obx(() {
      final state = controller.chatState.value;
      if (state == ChatState.noAuth) {
        return _buildErrorState(
          icon: Icons.chat_bubble_outline,
          title: 'chatUnavailable'.tr,
          subtitle: 'chatUnavailableSubtitle'.tr,
        );
      }
      if (state == ChatState.noGroup) {
        return _buildErrorState(
          icon: Icons.group_off,
          title: 'chatNotAvailable'.tr,
          subtitle: 'groupNotInitialized'.tr,
        );
      }
      if (state == ChatState.permissionDenied) {
        return _buildErrorState(
          icon: Icons.lock_outline,
          title: 'accessDenied'.tr,
          subtitle: 'notGroupMember'.tr,
        );
      }
      if (state == ChatState.networkError) {
        return _buildErrorState(
          icon: Icons.wifi_off,
          title: 'connectionIssue'.tr,
          subtitle: 'checkNetworkAndRetry'.tr,
        );
      }
      if (state != ChatState.ready && state != ChatState.initial) {
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
                fontSize: 13,
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
            child: CircularProgressIndicator(color: AppColors.brandSage500),
          );
        }
        if (snapshot.hasError) {
          final err = snapshot.error.toString().toLowerCase();
          final isPermission = err.contains('permission');
          final isNetwork =
              err.contains('network') ||
              err.contains('unavailable') ||
              err.contains('socket');
          if (isPermission) {
            controller.chatState.value = ChatState.permissionDenied;
          } else if (isNetwork) {
            controller.chatState.value = ChatState.networkError;
          }
          return _buildErrorState(
            icon: Icons.error_outline,
            title: isPermission ? 'accessDenied'.tr : 'connectionIssue'.tr,
            subtitle: isPermission
                ? 'notGroupMember'.tr
                : 'checkNetworkAndRetry'.tr,
          );
        }
        final messages = snapshot.data ?? [];
        if (messages.isEmpty) {
          return Center(
            child: Text(
              'noMessagesYet'.tr,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutralInk500,
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
            final isOwnMessage = controller.isOwnMessage(msg.senderId);
            final showAvatar =
                index == 0 || messages[index - 1].senderId != msg.senderId;

            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                mainAxisAlignment: isOwnMessage
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isOwnMessage && showAvatar)
                    _buildAvatar(
                      msg.senderName,
                      msg.senderProfileImage,
                      msg.senderId,
                    ),
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
                                  msg.senderName,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.neutralInk700,
                                  ),
                                ),
                                if (msg.senderRole == 'admin') ...[
                                  SizedBox(width: 6.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandSage100,
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      'admin'.tr,
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
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
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
                            msg.text,
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
                          controller.formatTime(msg.createdAt),
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
        );
      },
    );
  }

  /// Distinct colors for initial avatars so users are easy to tell apart.
  static final List<Color> _avatarColors = [
    AppColors.brandSage600,
    AppColors.aquaGreen600,
    AppColors.accentGold500,
    AppColors.info,
    AppColors.warning,
    AppColors.danger,
    AppColors.brandSage800,
    AppColors.neutralInk700,
  ];

  static Color _avatarColorFor(String senderId) {
    final index = senderId.hashCode.abs() % _avatarColors.length;
    return _avatarColors[index];
  }

  static bool _isValidProfileUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Widget _buildAvatar(String senderName, String? profileImageUrl, String senderId) {
    final initial =
        senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';
    final showImage = _isValidProfileUrl(profileImageUrl);

    if (showImage) {
      return CircleAvatar(
        radius: 16.r,
        backgroundColor: AppColors.neutralLine200,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: profileImageUrl!,
            width: 32.r,
            height: 32.r,
            fit: BoxFit.cover,
            placeholder: (context, url) => _initialAvatar(
              initial,
              _avatarColorFor(senderId),
            ),
            errorWidget: (context, url, error) => _initialAvatar(
              initial,
              _avatarColorFor(senderId),
            ),
          ),
        ),
      );
    }

    return _initialAvatar(initial, _avatarColorFor(senderId));
  }

  Widget _initialAvatar(String initial, Color backgroundColor) {
    return CircleAvatar(
      radius: 16.r,
      backgroundColor: backgroundColor,
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

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        12.h,
        16.w,
        12.h + MediaQuery.of(context).padding.bottom,
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
            child: Container(
              constraints: BoxConstraints(minHeight: 44.h),
              decoration: BoxDecoration(
                color: AppColors.neutralLine100,
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: TextField(
                controller: controller.messageController,
                decoration: InputDecoration(
                  hintText: 'typeMessage'.tr,
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
                onSubmitted: (_) => controller.sendTextMessage(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GetBuilder<ChatController>(
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
                          : Icon(Icons.send, color: Colors.white,size: 20,),
                      // Image.asset(
                      //     'assets/images/chat_send_icon.png',
                      //     width: 20.sp,
                      //     height: 20.sp,
                      //     color: hasText
                      //         ? AppColors.surfaceWhite
                      //         : AppColors.surfaceWhite.withOpacity(0.6),
                      //     colorBlendMode: BlendMode.srcIn,
                      //   ),
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
