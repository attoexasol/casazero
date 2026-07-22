// presentation/maintenance/views/sections/maintenance_task_card.dart
import 'package:casazero/app/theme/app_colors.dart';
import 'package:casazero/app/theme/app_shadows.dart';
import 'package:casazero/app/theme/app_text_styles.dart';
import 'package:casazero/core/controllers/message_popup_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../models/maintenance_task_model.dart';
import '../../controllers/maintenance_controller.dart';

const List<String> _monthAbbrEn = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _monthAbbrIt = [
  'Gen',
  'Feb',
  'Mar',
  'Apr',
  'Mag',
  'Giu',
  'Lug',
  'Ago',
  'Set',
  'Ott',
  'Nov',
  'Dic',
];

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

  /// Get priority border color from bilingual API labels (IT name or EN type).
  Color _getPriorityBorderColor() {
    final label = task.getPriorityLabel().toLowerCase();
    if (label.contains('facoltativ') || label.contains('optional')) {
      return Colors.yellow.shade600;
    }
    if (label.contains('obbligator') || label.contains('mandatory')) {
      return Colors.red.shade600;
    }
    if (label.contains('condominial') || label.contains('administrative')) {
      return Colors.blue.shade600;
    }
    return Colors.transparent;
  }

  /// Get priority badge background color to match left border color
  /// Returns the same color as the border for consistency
  Color _getPriorityBadgeBackgroundColor() {
    final borderColor = _getPriorityBorderColor();
    // If border is transparent, use default priority style
    if (borderColor == Colors.transparent) {
      return priorityColors[task.priority]!['bg']!;
    }
    // Return border color with slight opacity for badge background
    return borderColor.withOpacity(0.2);
  }

  /// Get priority badge border color to match left border color
  Color _getPriorityBadgeBorderColor() {
    final borderColor = _getPriorityBorderColor();
    // If border is transparent, use default priority style
    if (borderColor == Colors.transparent) {
      return priorityColors[task.priority]!['border']!;
    }
    // Return the same border color
    return borderColor;
  }

  /// Get priority badge text color based on background
  Color _getPriorityBadgeTextColor() {
    final borderColor = _getPriorityBorderColor();
    // If border is transparent, use default priority style
    if (borderColor == Colors.transparent) {
      return priorityColors[task.priority]!['text']!;
    }
    // Use darker shade of border color for text
    if (borderColor == Colors.yellow.shade600) {
      return Colors.yellow.shade800; // Darker yellow for text
    } else if (borderColor == Colors.red.shade600) {
      return Colors.red.shade800; // Darker red for text
    } else if (borderColor == Colors.blue.shade600) {
      return Colors.blue.shade800; // Darker blue for text
    }
    return Colors.black;
  }

  /// Format date to DD MMM YYYY format (e.g., "15 Jan 2025" / "15 Gen 2025")
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return '';
    }

    try {
      // Try parsing different date formats from API
      DateTime? date;

      // Try parsing "yyyy-MM-dd HH:mm:ss" format
      if (dateStr.contains(' ')) {
        date = DateTime.parse(dateStr.split(' ')[0]);
      } else {
        // Try parsing "yyyy-MM-dd" format
        date = DateTime.parse(dateStr);
      }

      // Format to DD MMM YYYY using current locale (EN / IT)
      final isIt = Get.locale?.languageCode == 'it';
      final months = isIt ? _monthAbbrIt : _monthAbbrEn;
      final day = date.day.toString().padLeft(2, '0');
      return '$day ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      // If parsing fails, return original string
      print('⚠️ [MaintenanceTaskCard] Error parsing date: $dateStr - $e');
      return dateStr;
    }
  }

  /// Priority badge text from API, bilingual:
  /// EN = priority_type / type, IT = name
  String _getLocalizedPriorityLabel() => task.getPriorityLabel();

  /// Mark Complete only for Optional / Mandatory from API
  /// (`priority.priority_type` / `priority_info.type`).
  /// Hidden for Administrative (and any other type).
  bool _canShowMarkCompleteButton() {
    final en = (task.priorityNameEn ?? '').trim().toLowerCase();
    final it = (task.priorityNameIt ?? '').trim().toLowerCase();
    final label = task.getPriorityLabel().trim().toLowerCase();
    final combined = '$en|$it|$label|${task.priority.name}';

    // Explicitly hide Administrative / Condominiale
    if (combined.contains('administrative') ||
        combined.contains('condominial')) {
      return false;
    }

    // Show only Optional / Mandatory (EN type or IT name)
    return en == 'optional' ||
        en == 'mandatory' ||
        it.contains('facoltativ') ||
        it.contains('obbligator') ||
        label.contains('optional') ||
        label.contains('mandatory') ||
        label.contains('facoltativ') ||
        label.contains('obbligator');
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MaintenanceController>();
    final isOverdue = task.status == MaintenanceStatus.overdue;

    // DEBUG: Log priority display data
    print(
      'PRIORITY => it=${task.priorityNameIt} en=${task.priorityNameEn} shown=${task.getPriorityLabel()}',
    );

    return Obx(() {
      final isExpanded =
          controller.expandedCardId.value != null &&
          controller.expandedCardId.value == task.id;

      final priorityBorderColor = _getPriorityBorderColor();
      final cardRadius = 16.r;
      final borderWidth = isOverdue ? 2.w : 0.0;
      // Inner corner radius must account for the card border so the accent
      // strip follows the same curve as the card edge.
      final innerRadius = cardRadius - borderWidth;

      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(cardRadius),
          border: isOverdue
              ? Border.all(color: Colors.red.shade300, width: borderWidth)
              : null,
          boxShadow: AppShadows.shadowMd,
        ),
        child: GestureDetector(
          onTap: () => controller.toggleExpanded(task.id),
          behavior: HitTestBehavior.opaque,
          child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// LEFT ACCENT BORDER
                  Container(
                    width: 8.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          priorityBorderColor,
                          priorityBorderColor.withOpacity(0.5),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(innerRadius),
                        bottomLeft: Radius.circular(innerRadius),
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
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badges and Expand Icon
                              Row(
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8.w,
                                      runSpacing: 8.h,
                                      children: [
                                        // Priority Badge (background matches left border color)
                                        Obx(() {
                                          final localeController =
                                              Get.find<LocaleController>();
                                          // Access locale to trigger reactivity
                                          final _ = localeController.locale;

                                          final priorityLabel =
                                              _getLocalizedPriorityLabel();
                                          if (priorityLabel.isEmpty) {
                                            return const SizedBox.shrink();
                                          }
                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  _getPriorityBadgeBackgroundColor(),
                                              border: Border.all(
                                                color:
                                                    _getPriorityBadgeBorderColor(),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                            ),
                                            child: Text(
                                              priorityLabel,
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    _getPriorityBadgeTextColor(),
                                                height: 1.2,
                                                letterSpacing: 0,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }),
                                        // Status Badge
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(task.status),
                                            border: Border.all(
                                              color: _getStatusTextColor(
                                                task.status,
                                              ).withOpacity(0.3),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6.r,
                                            ),
                                          ),
                                          child: Text(
                                            _getStatusLabel(task.status),
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                              color: _getStatusTextColor(
                                                task.status,
                                              ),
                                              height: 1.2,
                                              letterSpacing: 0,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                      size: 24.sp,
                                      color: AppColors.neutralInk500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),

                              // Title (uses item_name_en/item_name_it, reactive to language changes)
                              Obx(() {
                                final localeController =
                                    Get.find<LocaleController>();
                                // Access locale to trigger reactivity
                                final _ = localeController.locale;

                                final title = task.getTitle();
                                return Text(
                                  title,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.neutralInk900,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }),
                              SizedBox(height: 8.h),

                              // Category and Frequency
                              isExpanded
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceWarm50,
                                            borderRadius: BorderRadius.circular(
                                              6.r,
                                            ),
                                          ),
                                          child: Obx(() {
                                            final localeController =
                                                Get.find<LocaleController>();
                                            // Access locale to trigger reactivity
                                            final _ = localeController.locale;

                                            final categoryName = task
                                                .getCategory();
                                            return Text(
                                              categoryName,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color:
                                                        AppColors.neutralInk700,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            );
                                          }),
                                        ),
                                        SizedBox(height: 6.h),
                                        // Use Obx to make frequency reactive to language changes
                                        Obx(() {
                                          final localeController =
                                              Get.find<LocaleController>();
                                          // Access locale to trigger reactivity
                                          final _ = localeController.locale;

                                          final frequency = task.getFrequency();
                                          return Text(
                                            frequency.isNotEmpty
                                                ? frequency
                                                : '',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color:
                                                      AppColors.neutralInk700,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          );
                                        }),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Flexible(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceWarm50,
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                            ),
                                            child: Obx(() {
                                              final localeController =
                                                  Get.find<LocaleController>();
                                              // Access locale to trigger reactivity
                                              final _ = localeController.locale;

                                              final categoryName = task
                                                  .getCategory();
                                              return Text(
                                                categoryName,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color: AppColors
                                                          .neutralInk700,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              );
                                            }),
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            color: AppColors.neutralInk400,
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        // Use Obx to make frequency reactive to language changes
                                        Flexible(
                                          child: Obx(() {
                                            final localeController =
                                                Get.find<LocaleController>();
                                            // Access locale to trigger reactivity
                                            final _ = localeController.locale;

                                            final frequency = task
                                                .getFrequency();
                                            return Text(
                                              frequency.isNotEmpty
                                                  ? frequency
                                                  : '',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color:
                                                        AppColors.neutralInk700,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                              SizedBox(height: 12.h),

                              // Dates
                              // TEMP: Log lastMaintenanceDate for verification
                              Builder(
                                builder: (_) {
                                  print(
                                    'Last maintenance date: ${task.lastMaintenanceDate}',
                                  );
                                  return const SizedBox.shrink();
                                },
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task.nextDue != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14.sp,
                                          color: isOverdue
                                              ? Colors.red.shade600
                                              : AppColors.neutralInk500,
                                        ),
                                        SizedBox(width: 4.w),
                                        Expanded(
                                          child: Obx(() {
                                            final localeController =
                                                Get.find<LocaleController>();
                                            // Access locale to trigger reactivity
                                            final _ = localeController.locale;

                                            return Text(
                                              '${'startDate'.tr}: ${_formatDate(task.nextDue)}',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color: isOverdue
                                                        ? Colors.red.shade600
                                                        : AppColors
                                                            .neutralInk700,
                                                    fontWeight: isOverdue
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  // Show "End Date" if lastMaintenanceDate exists
                                  if (task.lastMaintenanceDate != null &&
                                      task.lastMaintenanceDate!.isNotEmpty) ...[
                                    if (task.nextDue != null)
                                      SizedBox(height: 8.h),
                                    // Row(
                                    //   mainAxisSize: MainAxisSize.min,
                                    //   children: [
                                    //     Icon(
                                    //       Icons.calendar_today,
                                    //       size: 14,
                                    //       color: AppColors.neutralInk500,
                                    //     ),
                                    //     const SizedBox(width: 4),
                                    //     Text(
                                    //       '${'endDate'.tr}: ${_formatDate(task.lastMaintenanceDate)}',
                                    //       style: AppTextStyles.bodySmall
                                    //           .copyWith(
                                    //             color: AppColors.neutralInk700,
                                    //           ),
                                    //     ),
                                    //   ],
                                    // ),
                                  ],
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
                            padding: EdgeInsets.all(16.w),
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

                                // Residence Name
                                if (task.residenceObj != null) ...[
                                  SizedBox(height: 16.h),
                                  Text(
                                    'residence_title'.tr,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.neutralInk700,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    task.residenceObj!.residenceName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.neutralInk700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],

                                // Company Name and Phone
                                if (task.companyObj != null &&
                                    (task.companyObj!.name.isNotEmpty ||
                                        (task.companyObj!.phone != null &&
                                            task.companyObj!
                                                .phone!
                                                .isNotEmpty))) ...[
                                  SizedBox(height: 16.h),
                                  Obx(() {
                                    final localeController =
                                        Get.find<LocaleController>();
                                    // Access locale to trigger reactivity
                                    final _ = localeController.locale;

                                    return Text(
                                      'recommendedCompany'.tr,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.neutralInk700,
                                      ),
                                    );
                                  }),
                                  SizedBox(height: 4.h),
                                  if (task.companyObj!.name.isNotEmpty)
                                    Text(
                                      task.companyObj!.name,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.neutralInk700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (task.companyObj!.phone != null &&
                                      task.companyObj!.phone!.isNotEmpty) ...[
                                    if (task.companyObj!.name.isNotEmpty)
                                      SizedBox(height: 4.h),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            task.companyObj!.phone!,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color:
                                                      AppColors.neutralInk700,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.call,
                                            size: 20.sp,
                                            color: AppColors.brandSage400,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () async {
                                            final phoneNumber =
                                                task.companyObj!.phone!;
                                            final cleanedNumber = phoneNumber
                                                .replaceAll(
                                                  RegExp(r'[\s\-\(\)]'),
                                                  '',
                                                );
                                            final uri = Uri.parse(
                                              'tel:$cleanedNumber',
                                            );

                                            try {
                                              final launched = await launchUrl(
                                                uri,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );

                                              if (!launched) {
                                                throw Exception(
                                                  'Failed to launch dialer',
                                                );
                                              }
                                            } catch (e) {
                                              print(
                                                '❌ Error launching phone call: $e',
                                              );
                                              MessagePopupController.showError(
                                                messageKey:
                                                    'failed_to_open_dialer',
                                                titleKey: 'error',
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ],

                                // Attachments
                                if (task.attachments != null &&
                                    task.attachments!.isNotEmpty) ...[
                                  SizedBox(height: 16.h),
                                  Text(
                                    'attachments'.tr,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.neutralInk700,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  ...task.attachments!.map((file) {
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8.h),
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceWhite,
                                        border: Border.all(
                                          color: AppColors.neutralLine200,
                                        ),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32.w,
                                            height: 32.w,
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
                                                  BorderRadius.circular(8.r),
                                            ),
                                            child: Icon(
                                              Icons.description,
                                              size: 16.sp,
                                              color: Color(0xFF6A8F7B),
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
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
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  file.type,
                                                  style: AppTextStyles.caption
                                                      .copyWith(
                                                        color: AppColors
                                                            .neutralInk500,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.file_download_outlined,
                                            size: 18.sp,
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
                                  SizedBox(height: 16.h),
                                  Text(
                                    'contacts'.tr,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.neutralInk700,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  ...task.contacts!.map((contact) {
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8.h),
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceWhite,
                                        border: Border.all(
                                          color: AppColors.neutralLine200,
                                        ),
                                        borderRadius: BorderRadius.circular(12.r),
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
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            contact.role,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color:
                                                      AppColors.neutralInk700,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (contact.phone != null) ...[
                                            SizedBox(height: 4.h),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.phone,
                                                  size: 12.sp,
                                                  color: AppColors.brandSage400,
                                                ),
                                                SizedBox(width: 4.w),
                                                Expanded(
                                                  child: Text(
                                                    contact.phone!,
                                                    style: AppTextStyles.bodySmall
                                                        .copyWith(
                                                          color: AppColors
                                                              .brandSage400,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (contact.email != null) ...[
                                            SizedBox(height: 4.h),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.email,
                                                  size: 12.sp,
                                                  color: AppColors.brandSage400,
                                                ),
                                                SizedBox(width: 4.w),
                                                Expanded(
                                                  child: Text(
                                                    contact.email!,
                                                    style: AppTextStyles.bodySmall
                                                        .copyWith(
                                                          color: AppColors
                                                              .brandSage400,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                // Mark Complete only for Optional / Mandatory
                                // (API priority_type); hidden for Administrative
                                SizedBox(height: 16.h),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Primary Action: Mark Complete / Revert Back
                                    if (_canShowMarkCompleteButton()) ...[
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            controller.markTaskCompleted(
                                              task.id,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.brandSage400,
                                            shape: const StadiumBorder(),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                              vertical: 10.h,
                                            ),
                                            minimumSize: Size(0, 48.h),
                                            elevation: 0,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                task.status ==
                                                        MaintenanceStatus
                                                            .completed
                                                    ? Icons.undo
                                                    : Icons
                                                          .check_circle_outline,
                                                size: 17.sp,
                                                color: AppColors.surfaceWhite,
                                              ),
                                              SizedBox(width: 8.w),
                                              Flexible(
                                                child: Text(
                                                  task.status ==
                                                          MaintenanceStatus
                                                              .completed
                                                      ? 'revertBack'.tr
                                                      : 'markComplete'.tr,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                        color: AppColors
                                                            .surfaceWhite,
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                    ],
                                    // Secondary Action: Schedule Visit (icon only with text below)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            controller.scheduleVisit(task.id);
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                            padding: EdgeInsets.all(12.w),
                                            minimumSize: Size(48.w, 48.w),
                                            tapTargetSize:
                                                MaterialTapTargetSize.padded,
                                          ),
                                          child: Icon(
                                            Icons.calendar_today,
                                            size: 20.sp,
                                            color: Color(0xFF6A8F7B),
                                          ),
                                        ),
                                        //const SizedBox(height: 2),
                                        SizedBox(
                                          width: 56.w,
                                          child: Text(
                                            'scheduleVisit'.tr,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: const Color(0xFF6A8F7B),
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 12.w),
                                    // Secondary Action: Ask AI (icon only with text below)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton(
                                          onPressed: onAskAI,
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                            padding: EdgeInsets.all(12.w),
                                            minimumSize: Size(48.w, 48.w),
                                            tapTargetSize:
                                                MaterialTapTargetSize.padded,
                                          ),
                                          child: Icon(
                                            Icons.chat_bubble_outline,
                                            size: 20.sp,
                                            color: Color(0xFF6A8F7B),
                                          ),
                                        ),
                                        //const SizedBox(height: 2),
                                        SizedBox(
                                          width: 56.w,
                                          child: Text(
                                            'askAI'.tr,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: const Color(0xFF6A8F7B),
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
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
      );
    });
  }
}
