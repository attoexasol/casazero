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

  /// Parsed from API: document_name, file_name, task_name, etc.
  final String? relatedEntityName;

  /// Parsed from API: category, document_category, etc.
  final String? categoryName;

  /// Optional API subtitle field (shown as modal main title).
  final String? subtitle;

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
    this.relatedEntityName,
    this.categoryName,
    this.subtitle,
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
    title = json['title']?.toString() ?? '';
    final titleEn = _readString(json['title_en']);
    final titleIt = _readString(json['title_it']);

    // Handle description/content (API uses 'content', old format uses 'description')
    description =
        json['content']?.toString() ?? json['description']?.toString() ?? '';
    final contentEn = _readString(json['content_en']);
    final contentIt = _readString(json['content_it']);

    // Handle timestamp (API uses 'created_at', old format uses 'timestamp')
    if (json['created_at'] != null) {
      timestamp = DateTime.parse(json['created_at'].toString());
    } else if (json['timestamp'] != null) {
      timestamp = DateTime.parse(json['timestamp'].toString());
    } else {
      timestamp = DateTime.now();
    }

    // Handle is_read (API uses 0/1, old format uses bool)
    if (json['is_read'] is int) {
      isRead = json['is_read'] == 1;
    } else {
      isRead = json['is_read'] == true;
    }

    url = _pickUrl(json);
    final relatedEntityName = _pickEntityName(json);
    final categoryName = _pickCategoryName(json);
    final subtitle = _readString(json['subtitle']) ??
        _readString(json['sub_title']) ??
        _readString(json['subtitle_en']) ??
        _readString(json['subtitle_it']);

    return FeedItemModel(
      id: id,
      type: type,
      priority: _readString(json['priority']),
      title: title,
      description: description,
      timestamp: timestamp,
      isRead: isRead,
      url: url,
      titleEn: titleEn,
      titleIt: titleIt,
      contentEn: contentEn,
      contentIt: contentIt,
      relatedEntityName: relatedEntityName,
      categoryName: categoryName,
      subtitle: subtitle,
    );
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _pickFromMap(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = _readString(map[key]);
      if (value != null) return value;
    }
    return null;
  }

  static String? _pickEntityName(Map<String, dynamic> json) {
    const keys = [
      'document_name',
      'document_title',
      'file_name',
      'filename',
      'task_name',
      'maintenance_title',
      'ticket_subject',
      'subject',
      'name',
    ];

    final direct = _pickFromMap(json, keys);
    if (direct != null) return direct;

    for (final nestedKey in ['data', 'metadata', 'payload', 'extra']) {
      final nested = json[nestedKey];
      if (nested is Map<String, dynamic>) {
        final nestedValue = _pickFromMap(nested, keys);
        if (nestedValue != null) return nestedValue;
      }
    }

    return null;
  }

  static String? _pickCategoryName(Map<String, dynamic> json) {
    const keys = [
      'category',
      'category_name',
      'document_category',
      'maintenance_category',
    ];

    final direct = _pickFromMap(json, keys);
    if (direct != null) return direct;

    for (final nestedKey in ['data', 'metadata', 'payload', 'extra']) {
      final nested = json[nestedKey];
      if (nested is Map<String, dynamic>) {
        final nestedValue = _pickFromMap(nested, keys);
        if (nestedValue != null) return nestedValue;
      }
    }

    return null;
  }

  static String? _pickUrl(Map<String, dynamic> json) {
    const keys = ['url', 'file_url', 'document_url'];
    final direct = _pickFromMap(json, keys);
    if (direct != null) return direct;

    for (final nestedKey in ['data', 'metadata', 'payload', 'extra']) {
      final nested = json[nestedKey];
      if (nested is Map<String, dynamic>) {
        final nestedValue = _pickFromMap(nested, keys);
        if (nestedValue != null) return nestedValue;
      }
    }

    return null;
  }

  bool get _isDocumentType {
    final normalized = type.toLowerCase();
    return normalized == 'document' || normalized == 'documents';
  }

  /// File name extracted from [url] when present (e.g. documents/foo.pdf).
  String? get fileNameFromUrl {
    if (url == null || url!.isEmpty) return null;

    final cleaned = url!.split('?').first;
    final segments = cleaned.split('/');
    if (segments.isEmpty) return null;

    final last = Uri.decodeComponent(segments.last);
    if (last.isEmpty || !last.contains('.')) return null;
    return last;
  }

  bool get _isGenericApiTitle {
    final lower = title.toLowerCase().trim();
    if (lower.isEmpty) return true;

    const genericPatterns = [
      'new document uploaded',
      'document uploaded',
      'nuovo documento caricato',
      'documento caricato',
      'maintenance status updated',
      'stato manutenzione aggiornato',
      'community announcement',
      'annuncio della comunità',
      'notification',
      'notifica',
    ];

    return genericPatterns.any((pattern) => lower.contains(pattern));
  }

  /// Get display title based on current language (reactive)
  String get displayTitle {
    try {
      final localeController = Get.find<LocaleController>();
      final isItalian = localeController.isItalian;

      if (isItalian) {
        return titleIt?.isNotEmpty == true
            ? titleIt!
            : (title.isNotEmpty ? title : (titleEn ?? ''));
      } else {
        return titleEn?.isNotEmpty == true
            ? titleEn!
            : (title.isNotEmpty ? title : (titleIt ?? ''));
      }
    } catch (e) {
      return title.isNotEmpty ? title : (titleEn ?? titleIt ?? '');
    }
  }

  /// Get display content/description based on current language (reactive)
  String get displayContent {
    try {
      final localeController = Get.find<LocaleController>();
      final isItalian = localeController.isItalian;

      if (isItalian) {
        return contentIt?.isNotEmpty == true
            ? contentIt!
            : (description.isNotEmpty ? description : (contentEn ?? ''));
      } else {
        return contentEn?.isNotEmpty == true
            ? contentEn!
            : (description.isNotEmpty ? description : (contentIt ?? ''));
      }
    } catch (e) {
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
      'url': url,
      'related_entity_name': relatedEntityName,
      'category_name': categoryName,
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

  /// Title shown in notification modal — prefers API / entity data over generic keys.
  String get localizedDisplayTitle {
    if (titleEn != null && titleEn!.isNotEmpty) return displayTitle;
    if (titleIt != null && titleIt!.isNotEmpty) return displayTitle;

    if (relatedEntityName != null && relatedEntityName!.isNotEmpty) {
      if (_isGenericApiTitle || _isDocumentType) return relatedEntityName!;
    }

    if (_isDocumentType) {
      final fileName = fileNameFromUrl;
      if (fileName != null) return fileName;
    }

    if (title.isNotEmpty && !_isGenericApiTitle) return title;

    if (relatedEntityName != null && relatedEntityName!.isNotEmpty) {
      return relatedEntityName!;
    }

    if (title.isNotEmpty) return title;

    return notificationTitleKey.tr;
  }

  /// Description shown in notification modal — prefers API content over generic keys.
  String get localizedDisplayContent {
    if (contentEn != null && contentEn!.isNotEmpty) return displayContent;
    if (contentIt != null && contentIt!.isNotEmpty) return displayContent;

    final parts = <String>[];

    if (description.isNotEmpty) {
      parts.add(description);
    }

    if (categoryName != null &&
        categoryName!.isNotEmpty &&
        !parts.any((p) => p.toLowerCase().contains(categoryName!.toLowerCase()))) {
      parts.add(categoryName!);
    }

    if (_isDocumentType) {
      final fileName = fileNameFromUrl;
      if (fileName != null &&
          fileName != localizedDisplayTitle &&
          !parts.any((p) => p.contains(fileName))) {
        parts.add(fileName);
      }
    }

    if (parts.isNotEmpty) return parts.join(' • ');

    return notificationDescriptionKey.tr;
  }

  /// Notification modal main heading: API subtitle/content (detailed line).
  String get modalTitle {
    if (subtitle != null && subtitle!.isNotEmpty) return subtitle!;
    return localizedDisplayContent;
  }

  /// Notification modal subheading: API title (generic/summary line).
  String get modalSubtitle {
    if (titleEn != null && titleEn!.isNotEmpty) return displayTitle;
    if (titleIt != null && titleIt!.isNotEmpty) return displayTitle;
    if (title.isNotEmpty) return title;
    return notificationTitleKey.tr;
  }

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
    String? relatedEntityName,
    String? categoryName,
    String? subtitle,
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
      relatedEntityName: relatedEntityName ?? this.relatedEntityName,
      categoryName: categoryName ?? this.categoryName,
      subtitle: subtitle ?? this.subtitle,
    );
  }
}
