// core/utils/time_formatter.dart

import 'package:intl/intl.dart';

class TimeFormatter {
  /// Format time as "2 minutes ago", "3 days ago", or "28-Nov-2025"
  ///
  /// Rules:
  /// - < 1 minute: "Just now"
  /// - < 60 minutes: "X minutes ago"
  /// - < 24 hours: "X hours ago"
  /// - < 7 days: "X days ago"
  /// - >= 7 days: "DD-MMM-YYYY"
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      // Format as DD-MMM-YYYY (e.g., "28-Nov-2025")
      return DateFormat('dd-MMM-yyyy').format(dateTime);
    }
  }

  /// Format date as "DD-MMM-YYYY" (e.g., "28-Nov-2025")
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd-MMM-yyyy').format(dateTime);
  }

  /// Format date and time as "DD-MMM-YYYY HH:mm" (e.g., "28-Nov-2025 15:30")
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd-MMM-yyyy HH:mm').format(dateTime);
  }

  /// Format trusted until date
  /// Shows "Valid until DD-MMM-YYYY"
  static String formatTrustedUntil(DateTime dateTime) {
    final formatted = DateFormat('dd-MMM-yyyy').format(dateTime);
    return 'Valid until $formatted';
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
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (minutes > 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
      }
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      if (hours > 0) {
        return '$days ${days == 1 ? 'day' : 'days'} $hours ${hours == 1 ? 'hour' : 'hours'} ago';
      }
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('dd-MMM-yyyy').format(dateTime);
    }
  }
}