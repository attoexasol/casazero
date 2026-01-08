// presentation/maintenance/views/sections/maintenance_task_card.dart
import 'package:casazero/app/theme/app_colors.dart';
import 'package:casazero/app/theme/app_shadows.dart';
import 'package:casazero/app/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/maintenance_task_model.dart';
import '../../controllers/maintenance_controller.dart';

class MaintenanceTaskCard extends StatelessWidget {
  final MaintenanceTask task;
  final VoidCallback onAskAI;

  const MaintenanceTaskCard({
    super.key,
    required this.task,
    required this.onAskAI,
  });

  // Priority colors matching React
  static Map<MaintenancePriority, Map<String, Color>> get priorityColors => {
    MaintenancePriority.facoltative: {
      'bg': const Color(0xFFCFE2D7),
      'text': const Color(0xFF2D5F3F),
      'border': const Color(0xFFA8C9B5),
    },
    MaintenancePriority.obbligatorie: {
      'bg': const Color(0xFFFFE6B3),
      'text': const Color(0xFF8B5E00),
      'border': const Color(0xFFF4D399),
    },
    MaintenancePriority.condominiali: {
      'bg': const Color(0xFFD7E2EA),
      'text': const Color(0xFF2C5F7F),
      'border': const Color(0xFFB5CFE0),
    },
    MaintenancePriority.personal: {
      'bg': const Color(0xFFE8F5E9),
      'text': const Color(0xFF6A8F7B),
      'border': const Color(0xFF6A8F7B),
    },
    MaintenancePriority.n1: {
      'bg': const Color(0xFFF3F4F6), // gray-100
      'text': const Color(0xFF374151), // gray-700
      'border': const Color(0xFFD1D5DB), // gray-300
    },
    MaintenancePriority.n2: {
      'bg': const Color(0xFFFEF3C7), // yellow-100
      'text': const Color(0xFF92400E), // yellow-700
      'border': const Color(0xFFFDE68A), // yellow-300
    },
    MaintenancePriority.n3: {
      'bg': const Color(0xFFFEE2E2), // red-100
      'text': const Color(0xFF991B1B), // red-700
      'border': const Color(0xFFFCA5A5), // red-300
    },
  };

  Color _getStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return Colors.amber.shade100;
      case MaintenanceStatus.inProgress:
        return Colors.blue.shade100;
      case MaintenanceStatus.completed:
        return Colors.green.shade100;
      case MaintenanceStatus.overdue:
        return Colors.red.shade100;
    }
  }

  Color _getStatusTextColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return Colors.amber.shade700;
      case MaintenanceStatus.inProgress:
        return Colors.blue.shade700;
      case MaintenanceStatus.completed:
        return Colors.green.shade700;
      case MaintenanceStatus.overdue:
        return Colors.red.shade700;
    }
  }

  /// Get localized status label using translation keys
  /// Maps MaintenanceStatus enum to translation keys
  String _getStatusLabel(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return 'pendingStatus'.tr;
      case MaintenanceStatus.inProgress:
        return 'inProgressStatus'.tr;
      case MaintenanceStatus.completed:
        return 'completedStatus'.tr;
      case MaintenanceStatus.overdue:
        return 'overdueStatus'.tr;
    }
  }

  /// Get localized priority label using translation keys
  /// Maps MaintenancePriority enum to translation keys
  String _getPriorityLabel(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.facoltative:
        return 'facoltative'.tr;
      case MaintenancePriority.obbligatorie:
        return 'obbligatorie'.tr;
      case MaintenancePriority.condominiali:
        return 'condominiali'.tr;
      case MaintenancePriority.personal:
        return 'personal'.tr;
      case MaintenancePriority.n1:
        return 'N1';
      case MaintenancePriority.n2:
        return 'N2';
      case MaintenancePriority.n3:
        return 'N3';
    }
  }

  /// Map API frequency value to translation key
  /// Handles various frequency formats from API
  String _getFrequencyLabel(String? frequency) {
    if (frequency == null || frequency.isEmpty) {
      return frequency ?? '';
    }

    // Normalize frequency string for comparison
    final normalized = frequency.toLowerCase().trim();

    // Map common API frequency values to translation keys
    if (normalized.contains('weekly') || normalized.contains('settimanale')) {
      return 'frequencyWeekly'.tr;
    } else if (normalized.contains('monthly') ||
        normalized.contains('mensile')) {
      return 'frequencyMonthly'.tr;
    } else if (normalized.contains('quarterly') ||
        normalized.contains('trimestrale')) {
      return 'frequencyQuarterly'.tr;
    } else if (normalized.contains('6 months') ||
        normalized.contains('6 mesi')) {
      return 'frequencyEvery6Months'.tr;
    } else if (normalized.contains('3 months') ||
        normalized.contains('3 mesi')) {
      return 'frequencyEvery3Months'.tr;
    } else if (normalized.contains('12 months') ||
        normalized.contains('12 mesi') ||
        normalized.contains('annually') ||
        normalized.contains('annuale') ||
        normalized.contains('annualmente')) {
      return 'frequencyAnnually'.tr;
    } else if (normalized.contains('18 months') ||
        normalized.contains('18 mesi')) {
      return 'frequencyEvery18Months'.tr;
    } else if (normalized.contains('one-time') ||
        normalized.contains('una tantum') ||
        normalized.contains('progetto una tantum')) {
      return 'frequencyOneTime'.tr;
    }

    // If no match found, return original value (might be custom frequency)
    // This handles edge cases where API returns custom frequencies
    return frequency;
  }

  /// Get priority border color based on priority type from API
  /// Maps priority type to color following Document card pattern
  Color _getPriorityBorderColor() {
    // Extract priority name from priorityRaw if it contains a dash (format: "name-type")
    String? priorityName;
    if (task.priorityRaw != null && task.priorityRaw!.contains('-')) {
      final parts = task.priorityRaw!.split('-');
      if (parts.isNotEmpty) {
        priorityName = parts[0].trim();
      }
    } else if (task.priorityRaw != null) {
      priorityName = task.priorityRaw!.trim();
    }

    // Map priority name to color (case-sensitive matching as per requirements)
    switch (priorityName) {
      case 'Facoltativa':
        return Colors.yellow.shade600;
      case 'Obbligatoria':
        return Colors.red.shade600;
      case 'Condominiale':
        return Colors.blue.shade600;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MaintenanceController>();
    final isOverdue = task.status == MaintenanceStatus.overdue;
    final priorityStyle = priorityColors[task.priority]!;

    // DEBUG: Log priority display data
    print('PRIORITY => ${task.priorityRaw}');

    return Obx(() {
      final isExpanded =
          controller.expandedCardId.value != null &&
          controller.expandedCardId.value == task.id;

      final priorityBorderColor = _getPriorityBorderColor();

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: isOverdue
              ? Border.all(color: Colors.red.shade300, width: 2)
              : null,
          boxShadow: AppShadows.shadowMd,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.toggleExpanded(task.id),
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// LEFT ACCENT BORDER
                  Container(
                    width: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          priorityBorderColor,
                          priorityBorderColor.withOpacity(0.5),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),

                  /// CONTENT SECTION
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact View
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badges and Expand Icon
                              Row(
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        // Priority Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: priorityStyle['bg'],
                                            border: Border.all(
                                              color: priorityStyle['border']!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            task.priorityRaw
                                                    ?.toString()
                                                    .split('-')
                                                    .first ??
                                                '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  (priorityStyle['text']
                                                      as Color?) ??
                                                  const Color(0xFF000000),
                                              height: 1.2,
                                              letterSpacing: 0,
                                            ),
                                          ),
                                        ),
                                        // Status Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(task.status),
                                            border: Border.all(
                                              color: _getStatusTextColor(
                                                task.status,
                                              ).withOpacity(0.3),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            _getStatusLabel(task.status),
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: _getStatusTextColor(
                                                    task.status,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: AppColors.neutralInk500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Title
                              Text(
                                task.title,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.neutralInk900,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Category and Frequency
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceWarm50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      task.categoryObj?.nameEn.isNotEmpty ==
                                              true
                                          ? task.categoryObj!.nameEn
                                          : task.category,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.neutralInk700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      color: AppColors.neutralInk400,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    task.frequency.isNotEmpty
                                        ? _getFrequencyLabel(task.frequency)
                                        : '',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.neutralInk700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Dates
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  if (task.nextDue != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: isOverdue
                                              ? Colors.red.shade600
                                              : AppColors.neutralInk500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${'dueDateLabel'.tr}: ${task.nextDue}',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: isOverdue
                                                    ? Colors.red.shade600
                                                    : AppColors.neutralInk700,
                                                fontWeight: isOverdue
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                        ),
                                      ],
                                    ),
                                  if (task.lastCompleted != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 14,
                                          color: AppColors.neutralInk500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${'lastMaintenanceLabel'.tr}: ${task.lastCompleted}',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.neutralInk700,
                                              ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Expanded Detail View
                        if (isExpanded) ...[
                          Divider(height: 1, color: AppColors.neutralLine200),
                          Container(
                            color: AppColors.surfaceWarm50.withOpacity(0.3),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Full Description
                                // Text(
                                //   'fullDescription'.tr,
                                //   style: AppTextStyles.bodySmall.copyWith(
                                //     fontWeight: FontWeight.w600,
                                //     color: AppColors.neutralInk700,
                                //   ),
                                // ),
                                // const SizedBox(height: 8),
                                // Text(
                                //   task.description ??
                                //       task.maintenanceNote ??
                                //       'noDescriptionAvailable'.tr,
                                //   style: AppTextStyles.bodyMedium.copyWith(
                                //     color: AppColors.neutralInk700,
                                //     height: 1.5,
                                //   ),
                                // ),

                                // Item Name
                                if (task.itemObj != null) ...[
                                  //const SizedBox(height: 16),
                                  Text(
                                    'Item name',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.neutralInk700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    task.itemObj!.nameEn.isNotEmpty
                                        ? task.itemObj!.nameEn
                                        : task.itemObj!.name,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.neutralInk700,
                                    ),
                                  ),
                                ],

                                // Residence Name
                                if (task.residenceObj != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Residence',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.neutralInk700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    task.residenceObj!.residenceName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.neutralInk700,
                                    ),
                                  ),
                                ],

                                // Attachments
                                if (task.attachments != null &&
                                    task.attachments!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'attachments'.tr,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.neutralInk700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...task.attachments!.map((file) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceWhite,
                                        border: Border.all(
                                          color: AppColors.neutralLine200,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  const Color(
                                                    0xFF6A8F7B,
                                                  ).withOpacity(0.2),
                                                  const Color(
                                                    0xFF6A8F7B,
                                                  ).withOpacity(0.1),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.description,
                                              size: 16,
                                              color: Color(0xFF6A8F7B),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  file.name,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                                Text(
                                                  file.type,
                                                  style: AppTextStyles.caption
                                                      .copyWith(
                                                        color: AppColors
                                                            .neutralInk500,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.file_download_outlined,
                                            size: 18,
                                            color: AppColors.neutralInk500,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],

                                // Contacts
                                if (task.contacts != null &&
                                    task.contacts!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'contacts'.tr,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.neutralInk700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...task.contacts!.map((contact) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceWhite,
                                        border: Border.all(
                                          color: AppColors.neutralLine200,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            contact.name,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            contact.role,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color:
                                                      AppColors.neutralInk700,
                                                ),
                                          ),
                                          if (contact.phone != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.phone,
                                                  size: 12,
                                                  color: AppColors.brandSage400,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  contact.phone!,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                        color: AppColors
                                                            .brandSage400,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (contact.email != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.email,
                                                  size: 12,
                                                  color: AppColors.brandSage400,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  contact.email!,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                        color: AppColors
                                                            .brandSage400,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }),
                                ],

                                // Action Buttons
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Primary Action: Mark Complete (dominant)
                                    // Primary Action: Mark Complete (same style, green)
                                    // Primary Action: Mark Complete (green, same height)
                                    ElevatedButton(
                                      onPressed: () {
                                        controller.markTaskCompleted(task.id);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.brandSage400, // ✅ green
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        minimumSize: const Size(0, 42),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline,
                                            size: 17,
                                            color: AppColors.surfaceWhite,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'markComplete'.tr,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: AppColors.surfaceWhite,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 15),
                                    // Secondary Action: Schedule Visit
                                    OutlinedButton(
                                      onPressed: () {
                                        controller.scheduleVisit(task.id);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFF6A8F7B),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        minimumSize: const Size(0, 40),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Color(0xFF6A8F7B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'scheduleVisit'.tr,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: const Color(
                                                    0xFF6A8F7B,
                                                  ),
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Secondary Action: Ask AI
                                    OutlinedButton(
                                      onPressed: onAskAI,
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFF6A8F7B),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        minimumSize: const Size(0, 40),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.chat_bubble_outline,
                                            size: 14,
                                            color: Color(0xFF6A8F7B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'askAI'.tr,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: const Color(
                                                    0xFF6A8F7B,
                                                  ),
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
