// core/utils/time_formatter.dart

import 'package:get/get.dart';

class TimeFormatter {
  static const List<String> _monthAbbrEn = [
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

  static const List<String> _monthAbbrIt = [
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

  /// Locale-aware date in DD-MMM-YYYY format (e.g. "28-Nov-2025" / "28-Gen-2025").
  static String formatDate(DateTime dateTime) {
    final isIt = Get.locale?.languageCode == 'it';
    final months = isIt ? _monthAbbrIt : _monthAbbrEn;
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$day-${months[dateTime.month - 1]}-${dateTime.year}';
  }

  /// Locale-aware date and time (e.g. "28-Nov-2025 15:30").
  static String formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${formatDate(dateTime)} $hour:$minute';
  }

  /// Format time as "2 minutes ago", "3 days ago", or localized date.
  ///
  /// Rules:
  /// - < 1 minute: "Just now"
  /// - < 60 minutes: "X minutes ago"
  /// - < 24 hours: "X hours ago"
  /// - < 7 days: "X days ago"
  /// - >= 7 days: localized "DD-MMM-YYYY"
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just_now'.tr;
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute_ago'.tr : 'minutes_ago'.tr}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour_ago'.tr : 'hours_ago'.tr}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day_ago'.tr : 'days_ago'.tr}';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Format trusted until date with localized label and date.
  static String formatTrustedUntil(DateTime dateTime) {
    return '${'valid_until'.tr} ${formatDate(dateTime)}';
  }

  /// Check if date is in the past
  static bool isPast(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }

  /// Check if date is in the future
  static bool isFuture(DateTime dateTime) {
    return dateTime.isAfter(DateTime.now());
  }

  /// Get relative time with more detail
  static String formatTimeAgoDetailed(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just_now'.tr;
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute_ago'.tr : 'minutes_ago'.tr}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (minutes > 0) {
        return '$hours ${hours == 1 ? 'hour_ago'.tr : 'hours_ago'.tr} '
            '$minutes ${minutes == 1 ? 'minute_ago'.tr : 'minutes_ago'.tr}';
      }
      return '$hours ${hours == 1 ? 'hour_ago'.tr : 'hours_ago'.tr}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      if (hours > 0) {
        return '$days ${days == 1 ? 'day_ago'.tr : 'days_ago'.tr} '
            '$hours ${hours == 1 ? 'hour_ago'.tr : 'hours_ago'.tr}';
      }
      return '$days ${days == 1 ? 'day_ago'.tr : 'days_ago'.tr}';
    } else {
      return formatDate(dateTime);
    }
  }
}
