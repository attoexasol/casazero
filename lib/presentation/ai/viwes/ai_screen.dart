import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_shadows.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/ai_controller.dart';

class AIScreen extends StatelessWidget {
  const AIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller is already initialized in main_scaffold.dart
    final controller = Get.find<AiController>();

    return Obx(
      () => Column(
        children: [
          // Premium Header with Cube Icon
          _buildHeader(controller),

          // Messages Area - takes up remaining space and scrolls
          Expanded(child: _buildMessagesArea(controller)),

          // Premium Input - always at bottom
          _buildInputArea(controller),
        ],
      ),
    );
  }

  Widget _buildHeader(AiController controller) {
    return Container(
          color: AppColors.surfaceWhite,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back + Logo + Title Row
                Row(
                  children: [
                    // Back button - returns to previous screen (uses HomeController screen history)
                    IconButton(
                      onPressed: () => Get.find<HomeController>().goBack(),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: 22.sp,
                        color: AppColors.neutralInk700,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 40.w,
                        minHeight: 40.h,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Animated AI Cube Icon
                    _buildAnimatedAIIcon(),
                    SizedBox(width: 16.w),
                    // Title + Subtitle Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                                'casaZeroAI'.tr,
                                style: AppTextStyles.h3.copyWith(
                                  fontSize: 24.sp,
                                  letterSpacing: -0.48, // -0.02em
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.neutralInk900,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 300.ms, delay: 300.ms)
                              .slideX(
                                begin: -0.2,
                                end: 0,
                                duration: 300.ms,
                                delay: 300.ms,
                              ),
                          SizedBox(height: 4.h),
                          Text(
                                'yourIntelligentAssistant'.tr,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 14.sp,
                                  color: AppColors.neutralInk500,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 300.ms, delay: 400.ms)
                              .slideX(
                                begin: -0.2,
                                end: 0,
                                duration: 300.ms,
                                delay: 400.ms,
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Info Alert
                _buildInfoAlert(),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.2, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }

  Widget _buildAnimatedAIIcon() {
    return StatefulBuilder(
      builder: (context, setState) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 6),
          curve: Curves.easeInOut,
          onEnd: () {
            // Restart animation by rebuilding
            setState(() {});
          },
          builder: (context, value, child) {
            // Oscillating rotation: 0 -> 5deg -> -5deg -> 0
            // Use sine wave for smooth oscillation
            final oscillate =
                sin(value * 2 * pi) * 0.087; // ±5 degrees in radians

            return Transform.rotate(
              angle: oscillate,
              child: Container(
                width: 64.w,
                height: 64.h,
                decoration: BoxDecoration(boxShadow: AppShadows.shadowXl),
                child: Image.asset(
                  'assets/images/thumb_cubo.png',
                  width: 64.w,
                  height: 64.h,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoAlert() {
    return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.brandSage300.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16.sp,
                color: AppColors.neutralInk700,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'aiInfoAlert'.tr,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.neutralInk700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: 500.ms);
  }

  Widget _buildMessagesArea(AiController controller) {
    return Obx(() {
      // Show loading state while history is loading
      if (controller.isLoadingHistory.value) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: CircularProgressIndicator(color: AppColors.brandSage500),
          ),
        );
      }

      return Container(
        color: AppColors.surfaceWhite,
        child: ListView.builder(
          controller: controller.scrollController,
          padding: EdgeInsets.all(16.w),
          itemCount:
              controller.messages.length +
              (controller.isLoading.value ? 1 : 0) +
              (controller.showAssistance.value &&
                      controller.messages.length == 1
                  ? 1
                  : 0),
          itemBuilder: (context, index) {
            // Show assistance section when no chat started
            if (controller.showAssistance.value &&
                controller.messages.length == 1 &&
                index == controller.messages.length) {
              return _buildAssistanceSection(controller);
            }

            // Show loading indicator
            if (controller.isLoading.value &&
                index == controller.messages.length) {
              return _buildLoadingIndicator(controller);
            }

            // Show message
            final message = controller.messages[index];
            return _buildMessageBubble(message, index);
          },
        ),
      );
    });
  }

  Widget _buildMessageBubble(Message message, int index) {
    final isUser = message.role == 'user';

    return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(Get.context!).size.width * 0.85,
            ),
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            decoration: BoxDecoration(
              gradient: isUser
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.brandSage600, AppColors.brandSage500],
                    )
                  : null,
              color: isUser ? null : AppColors.surfaceWhite.withOpacity(0.9),
              border: isUser
                  ? null
                  : Border.all(
                      color: AppColors.neutralLine200.withOpacity(0.5),
                      width: 1,
                    ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: AppShadows.shadowMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/thumb_cubo.png',
                        width: 16.w,
                        height: 16.h,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'casaZeroAI'.tr,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandSage600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                ],
                Text(
                  message.content,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14.sp,
                    height: 1.5,
                    color: isUser
                        ? AppColors.surfaceWhite
                        : AppColors.neutralInk900,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11.sp,
                    color: isUser
                        ? AppColors.surfaceWhite.withOpacity(0.7)
                        : AppColors.neutralInk400,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildLoadingIndicator(AiController controller) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(Get.context!).size.width * 0.85,
        ),
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite.withOpacity(0.9),
          border: Border.all(
            color: AppColors.neutralLine200.withOpacity(0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: AppShadows.shadowMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16.w,
              height: 16.h,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.linear,
                    onEnd: () {
                      // Restart animation by rebuilding
                      setState(() {});
                    },
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 2 * 3.14159,
                        child: Image.asset(
                          'assets/images/thumb_cubo.png',
                          width: 16.w,
                          height: 16.h,
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'thinking'.tr,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14.sp,
                color: AppColors.neutralInk500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAssistanceSection(AiController controller) {
    final tickets = controller.getRecentTickets();
    final prompts = controller.getSuggestedPrompts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        // Assistenza Header
        Row(
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.brandSage100, AppColors.brandSage50],
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.help_outline,
                size: 18.sp,
                color: AppColors.brandSage600,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'assistance'.tr,
              style: AppTextStyles.CardHeaderText.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.neutralInk800,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // New Ticket Button
        _buildNewTicketButton(controller),

        SizedBox(height: 16.h),

        // Recent Tickets
        if (tickets.isNotEmpty) ...[
          Text(
            'recentTickets'.tr,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralInk500,
            ),
          ),
          SizedBox(height: 12.h),
          ...tickets.asMap().entries.map((entry) {
            final idx = entry.key;
            final ticket = entry.value;
            return _buildTicketCard(ticket, controller, idx + 1);
          }),
          SizedBox(height: 24.h),
        ],

        // Suggested Prompts
        Text(
          'exampleQuestions'.tr,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.neutralInk500,
          ),
        ),
        SizedBox(height: 12.h),
        ...prompts.asMap().entries.map((entry) {
          final idx = entry.key;
          final prompt = entry.value;
          return _buildPromptCard(prompt, controller, idx + 3);
        }),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildNewTicketButton(AiController controller) {
    return InkWell(
      onTap: () {
        // TODO: Handle new ticket
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brandSage500, AppColors.accentLime500],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandSage500.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.help_outline,
                color: AppColors.surfaceWhite,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'newAssistanceRequest'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.surfaceWhite,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'openSupportTicket'.tr,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.surfaceWhite,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.surfaceWhite,
              size: 16.sp,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTicketCard(Ticket ticket, AiController controller, int index) {
    return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          child: InkWell(
            onTap: () {
              // TODO: Handle ticket tap
            },
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite.withOpacity(0.8),
                border: Border.all(
                  color: AppColors.neutralLine200.withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.subject,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutralInk900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              ticket.id,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11.sp,
                                color: AppColors.neutralInk500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: controller.getStatusColor(ticket.status),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          controller.getStatusText(ticket.status),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: controller.getStatusTextColor(ticket.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12.sp,
                        color: AppColors.neutralInk500,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        ticket.date,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.neutralInk500,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '•',
                        style: TextStyle(color: AppColors.neutralInk400),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        ticket.category,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.neutralInk500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (200 + index * 100).ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildPromptCard(
    SuggestedPrompt prompt,
    AiController controller,
    int index,
  ) {
    return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          child: InkWell(
            onTap: () => controller.handlePromptClick(prompt.text),
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite.withOpacity(0.8),
                border: Border.all(
                  color: AppColors.neutralLine200.withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.brandSage100, AppColors.brandSage50],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: AppShadows.shadowSm,
                    ),
                    child: Icon(
                      prompt.icon,
                      size: 20.sp,
                      color: AppColors.brandSage600,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prompt.text,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 13.sp,
                            color: AppColors.neutralInk900,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandSage50,
                            border: Border.all(
                              color: AppColors.brandSage300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            prompt.category,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandSage600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (400 + index * 100).ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildInputArea(AiController controller) {
    return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite.withOpacity(0.95),
            border: Border(
              top: BorderSide(
                color: AppColors.neutralLine200.withOpacity(0.5),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.inputController,
                      enabled:
                          !controller.isLoading.value &&
                          !controller.isSending.value,
                      decoration: InputDecoration(
                        hintText: 'askAnything'.tr,
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14.sp,
                          color: AppColors.neutralInk400,
                          fontStyle: FontStyle.italic,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceWarm50.withOpacity(0.5),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.brandSage400,
                            width: 1,
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.neutralLine200,
                            width: 1,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.brandSage400,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      onSubmitted: (_) => controller.sendMessage(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.brandSage600,
                          AppColors.brandSage500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandSage500.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Obx(() {
                        final isLoading = controller.isLoading.value;
                        final isSending = controller.isSending.value;
                        final hasText = controller.inputText.value
                            .trim()
                            .isNotEmpty;
                        final isEnabled = hasText && !isLoading && !isSending;

                        return InkWell(
                          onTap: isEnabled ? controller.sendMessage : null,
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            width: 48.w,
                            height: 48.h,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.send,
                              color: isEnabled
                                  ? AppColors.surfaceWhite
                                  : AppColors.surfaceWhite.withOpacity(0.5),
                              size: 20.sp,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 700.ms)
        .slideY(begin: 0.2, end: 0, duration: 600.ms);
  }
}
