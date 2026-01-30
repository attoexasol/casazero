import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/permissions.dart';

/// Chat message model matching React ChatMessage structure.
class ChatMessage {
  final String id;
  final String sender;
  final String senderRole; // 'admin' | 'resident'
  final String content;
  final DateTime timestamp;
  final String type; // 'message' | 'announcement'

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.senderRole,
    required this.content,
    required this.timestamp,
    required this.type,
  });
}

/// Flutter ChatScreen converted from React ChatScreen.tsx.
/// UI matches React 1:1 (header, message list, input area).
class ChatScreen extends StatefulWidget {
  final Role role;
  final VoidCallback onBack;

  const ChatScreen({
    super.key,
    required this.role,
    required this.onBack,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    final nov1 = DateTime(2025, 11, 1);
    final nov2 = DateTime(2025, 11, 2);
    _messages.addAll([
      ChatMessage(
          id: '1',
          sender: 'Building Administrator',
          senderRole: 'admin',
          content:
              'Important: Elevator maintenance scheduled for November 8-9. Please use the stairs during this period.',
          timestamp: nov1,
          type: 'announcement'),
      ChatMessage(
          id: '2',
          sender: 'Marco R.',
          senderRole: 'resident',
          content: 'Will the water be shut off during the maintenance?',
          timestamp: DateTime(2025, 11, 1, 11, 15),
          type: 'message'),
      ChatMessage(
          id: '3',
          sender: 'Building Administrator',
          senderRole: 'admin',
          content:
              'No, only elevator service will be affected. Water and all other utilities will operate normally.',
          timestamp: DateTime(2025, 11, 1, 11, 20),
          type: 'message'),
      ChatMessage(
          id: '4',
          sender: 'Sofia M.',
          senderRole: 'resident',
          content: 'Thank you for the update!',
          timestamp: DateTime(2025, 11, 1, 14, 45),
          type: 'message'),
      ChatMessage(
          id: '5',
          sender: 'Building Administrator',
          senderRole: 'admin',
          content:
              'Reminder: Monthly condominium meeting this Friday at 6 PM in the community room.',
          timestamp: nov2,
          type: 'announcement'),
      ChatMessage(
          id: '6',
          sender: 'Luca P.',
          senderRole: 'resident',
          content: 'Can we join online?',
          timestamp: DateTime(2025, 11, 2, 9, 30),
          type: 'message'),
    ]);
    _messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 24) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        senderRole: 'resident',
        content: text,
        timestamp: DateTime.now(),
        type: 'message',
      ));
      _messageController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildMessageList()),
        _buildInputArea(),
      ],
    );
  }

  /// Header: Group Chat, Online Now, right-side Demo button (light green, gear + Demo).
  Widget _buildHeader() {
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
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isOwnMessage = msg.sender == 'You';
        final showAvatar = index == 0 ||
            _messages[index - 1].sender != msg.sender;

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
                      _formatTime(msg.timestamp),
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
                    _formatTime(msg.timestamp),
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
  Widget _buildInputArea() {
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
              icon: Icon(
                LucideIcons.paperclip,
                size: 22.sp,
                color: AppColors.neutralInk700,
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
                controller: _messageController,
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
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (_, value, __) {
              final hasText = value.text.trim().isNotEmpty;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasText ? _handleSend : null,
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
                child: Icon(
                  LucideIcons.send,
                  size: 20.sp,
                  color: hasText ? AppColors.surfaceWhite : AppColors.surfaceWhite.withOpacity(0.6),
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
