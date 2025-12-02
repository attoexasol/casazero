import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'notification_item.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'package:flutter_animate/flutter_animate.dart';


class LatestNotifications extends StatelessWidget {
  final List<dynamic> feedItems;

  const LatestNotifications({super.key, required this.feedItems});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'latest_notifications'.tr,
                style: AppTextStyles.h4.copyWith(
                  fontSize: 18,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentLime500,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentLime500.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Empty state
          if (feedItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'no_notifications'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk500,
                  ),
                ),
              ),
            )
          else
            Column(
              children: feedItems.asMap().entries.map((entry) {
                return NotificationItem(item: entry.value)
                    .animate(
                  delay: (entry.key * 100).ms,
                )
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2);
              }).toList(),
            ),
        ],
      ),
    );
  }
}
