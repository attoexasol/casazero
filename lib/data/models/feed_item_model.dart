import 'package:get/get.dart';
import '../../core/localization/locale_controller.dart';

class FeedItemModel {
  final String id;
  final String type; // 'maintenance', 'document', 'announcement'
  final String? priority; // 'low', 'medium', 'high'
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isRead;
  final String? url; // URL from API (optional)
  
  // Bilingual fields (for future API support)
  final String? titleEn;
  final String? titleIt;
  final String? contentEn;
  final String? contentIt;

  FeedItemModel({
    required this.id,
    required this.type,
    this.priority,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
    this.url,
    this.titleEn,
    this.titleIt,
    this.contentEn,
    this.contentIt,
  });

  factory FeedItemModel.fromJson(Map<String, dynamic> json) {
    // Support both API format and old format
    // API format: notification_type, content, created_at, is_read (0/1)
    // Old format: type, description, timestamp, is_read (bool)
    
    String id;
    String type;
    String title;
    String description;
    DateTime timestamp;
    bool isRead;
    String? url;

    // Handle ID (can be int or string)
    if (json['id'] is int) {
      id = json['id'].toString();
    } else {
      id = json['id']?.toString() ?? '';
    }

    // Handle type (API uses 'notification_type', old format uses 'type')
    type = json['notification_type'] ?? json['type'] ?? 'announcement';

    // Handle title (support bilingual fields for future API)
    title = json['title'] ?? '';
    final titleEn = json['title_en'];
    final titleIt = json['title_it'];

    // Handle description/content (API uses 'content', old format uses 'description')
    // Support bilingual fields for future API
    description = json['content'] ?? json['description'] ?? '';
    final contentEn = json['content_en'];
    final contentIt = json['content_it'];

    // Handle timestamp (API uses 'created_at', old format uses 'timestamp')
    if (json['created_at'] != null) {
      timestamp = DateTime.parse(json['created_at']);
    } else if (json['timestamp'] != null) {
      timestamp = DateTime.parse(json['timestamp']);
    } else {
      timestamp = DateTime.now();
    }

    // Handle is_read (API uses 0/1, old format uses bool)
    if (json['is_read'] is int) {
      isRead = json['is_read'] == 1;
    } else {
      isRead = json['is_read'] ?? false;
    }

    // Handle URL (optional, from API)
    url = json['url'];

    return FeedItemModel(
      id: id,
      type: type,
      priority: json['priority'],
      title: title,
      description: description,
      timestamp: timestamp,
      isRead: isRead,
      url: url,
      titleEn: titleEn,
      titleIt: titleIt,
      contentEn: contentEn,
      contentIt: contentIt,
    );
  }
  
  /// Get display title based on current language (reactive)
  /// Returns Italian title if available and language is Italian, otherwise English/default
  String get displayTitle {
    try {
      final localeController = Get.find<LocaleController>();
      final isItalian = localeController.isItalian;
      
      if (isItalian) {
        // Italian: prefer title_it, fallback to title, then title_en
        return titleIt?.isNotEmpty == true 
            ? titleIt! 
            : (title.isNotEmpty ? title : (titleEn ?? ''));
      } else {
        // English: prefer title_en, fallback to title, then title_it
        return titleEn?.isNotEmpty == true 
            ? titleEn! 
            : (title.isNotEmpty ? title : (titleIt ?? ''));
      }
    } catch (e) {
      // Fallback if LocaleController not available
      return title.isNotEmpty ? title : (titleEn ?? titleIt ?? '');
    }
  }
  
  /// Get display content/description based on current language (reactive)
  /// Returns Italian content if available and language is Italian, otherwise English/default
  String get displayContent {
    try {
      final localeController = Get.find<LocaleController>();
      final isItalian = localeController.isItalian;
      
      if (isItalian) {
        // Italian: prefer content_it, fallback to description, then content_en
        return contentIt?.isNotEmpty == true 
            ? contentIt! 
            : (description.isNotEmpty ? description : (contentEn ?? ''));
      } else {
        // English: prefer content_en, fallback to description, then content_it
        return contentEn?.isNotEmpty == true 
            ? contentEn! 
            : (description.isNotEmpty ? description : (contentIt ?? ''));
      }
    } catch (e) {
      // Fallback if LocaleController not available
      return description.isNotEmpty ? description : (contentEn ?? contentIt ?? '');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'priority': priority,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }

  String get timeAgo {
    final difference = DateTime.now().difference(timestamp);

    if (difference.inDays > 365) {
      final n = (difference.inDays / 365).floor();
      return '$n ${n == 1 ? 'year_ago'.tr : 'years_ago'.tr}';
    } else if (difference.inDays > 30) {
      final n = (difference.inDays / 30).floor();
      return '$n ${n == 1 ? 'month_ago'.tr : 'months_ago'.tr}';
    } else if (difference.inDays > 0) {
      final n = difference.inDays;
      return '$n ${n == 1 ? 'day_ago'.tr : 'days_ago'.tr}';
    } else if (difference.inHours > 0) {
      final n = difference.inHours;
      return '$n ${n == 1 ? 'hour_ago'.tr : 'hours_ago'.tr}';
    } else if (difference.inMinutes > 0) {
      final n = difference.inMinutes;
      return '$n ${n == 1 ? 'minute_ago'.tr : 'minutes_ago'.tr}';
    } else {
      return 'just_now'.tr;
    }
  }

  /// Localization key for notification title when API has no bilingual fields.
  String get notificationTitleKey {
    switch (type.toLowerCase()) {
      case 'document':
      case 'documents':
        return 'notification_document_uploaded';
      case 'maintenance':
        return 'notification_maintenance_updated';
      case 'announcement':
        return 'notification_announcement';
      default:
        return 'notification_generic';
    }
  }

  /// Localization key for notification description when API has no bilingual fields.
  String get notificationDescriptionKey {
    switch (type.toLowerCase()) {
      case 'document':
      case 'documents':
        return 'notification_document_description';
      case 'maintenance':
        return 'notification_maintenance_description';
      case 'announcement':
        return 'notification_announcement_description';
      default:
        return 'notification_generic_description';
    }
  }

  /// Returns localized title: uses displayTitle when API has bilingual; else type-based key.
  String get localizedDisplayTitle {
    if (titleEn != null && titleEn!.isNotEmpty) return displayTitle;
    if (titleIt != null && titleIt!.isNotEmpty) return displayTitle;
    return notificationTitleKey.tr;
  }

  /// Returns localized description: uses displayContent when API has bilingual; else type-based key.
  String get localizedDisplayContent {
    if (contentEn != null && contentEn!.isNotEmpty) return displayContent;
    if (contentIt != null && contentIt!.isNotEmpty) return displayContent;
    return notificationDescriptionKey.tr;
  }

  /// Create a copy with updated fields (for marking as read)
  FeedItemModel copyWith({
    String? id,
    String? type,
    String? priority,
    String? title,
    String? description,
    DateTime? timestamp,
    bool? isRead,
    String? url,
    String? titleEn,
    String? titleIt,
    String? contentEn,
    String? contentIt,
  }) {
    return FeedItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      url: url ?? this.url,
      titleEn: titleEn ?? this.titleEn,
      titleIt: titleIt ?? this.titleIt,
      contentEn: contentEn ?? this.contentEn,
      contentIt: contentIt ?? this.contentIt,
    );
  }
}