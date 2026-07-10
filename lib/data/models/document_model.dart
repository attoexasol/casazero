import 'package:get/get.dart';
import '../../core/localization/locale_controller.dart';

class DocumentModel {
  final String id;
  final String title;
  final String type;
  /// English category name (used for filter matching / colors).
  final String category;
  /// Italian category name from API (`category_name_it`).
  final String categoryIt;
  /// English type name from API (`type_name`).
  final String typeName;
  /// Italian type name from API (`type_name_it`).
  final String typeNameIt;
  final String date;
  final String size;
  final List<String> tags;
  final String? status;
  final String? fileUrl;
  final String? description;
  final int? categoryId;
  final int? typeId;
  /// Set when the resident uploaded the file via `user_document_upload`.
  final int? uploadedByUserId;

  DocumentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    this.categoryIt = '',
    this.typeName = '',
    this.typeNameIt = '',
    required this.date,
    required this.size,
    required this.tags,
    this.status,
    this.fileUrl,
    this.description,
    this.categoryId,
    this.typeId,
    this.uploadedByUserId,
  });

  /// True when uploaded by a resident (not building admin).
  bool get isUserUploaded => uploadedByUserId != null;

  /// Only the resident who uploaded the document may delete it.
  bool isDeletableByUser(int? currentUserId) {
    if (uploadedByUserId == null || currentUserId == null) return false;
    return uploadedByUserId == currentUserId;
  }

  /// Localized category name: Italian when locale is IT, else English.
  String getCategory() {
    try {
      final localeController = Get.find<LocaleController>();
      if (localeController.isItalian) {
        return categoryIt.isNotEmpty ? categoryIt : category;
      }
    } catch (_) {}
    return category;
  }

  /// Localized document type name: Italian when locale is IT, else English.
  String getTypeName() {
    try {
      final localeController = Get.find<LocaleController>();
      if (localeController.isItalian) {
        return typeNameIt.isNotEmpty ? typeNameIt : typeName;
      }
    } catch (_) {}
    return typeName;
  }

  /// Localized uploaded date (e.g. "15 Jan 2025" / "15 Gen 2025").
  String getLocalizedDate() {
    if (date.trim().isEmpty) return '';

    final parsed = _parseUploadedDate(date);
    if (parsed == null) return date;

    bool isItalian = false;
    try {
      isItalian = Get.find<LocaleController>().isItalian;
    } catch (_) {
      isItalian = Get.locale?.languageCode == 'it';
    }

    final months = isItalian ? _monthAbbrIt : _monthAbbrEn;
    final day = parsed.day.toString().padLeft(2, '0');
    return '$day ${months[parsed.month - 1]} ${parsed.year}';
  }

  /// Parses common API / display date strings.
  static DateTime? _parseUploadedDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    // "yyyy-MM-dd" or "yyyy-MM-dd HH:mm:ss"
    if (value.contains('-') && value.length >= 10 && value[4] == '-') {
      try {
        return DateTime.parse(value.contains(' ') ? value.split(' ')[0] : value);
      } catch (_) {}
    }

    // "dd-MM-yyyy" / "dd/MM/yyyy"
    final numeric = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$');
    final numericMatch = numeric.firstMatch(value);
    if (numericMatch != null) {
      final day = int.tryParse(numericMatch.group(1)!);
      final month = int.tryParse(numericMatch.group(2)!);
      final year = int.tryParse(numericMatch.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    // "15 Jan 2025", "Jan 15, 2025", "15 Gen 2025", etc.
    final monthNames = <String, int>{};
    for (var i = 0; i < _monthAbbrEn.length; i++) {
      monthNames[_monthAbbrEn[i].toLowerCase()] = i + 1;
      monthNames[_monthAbbrIt[i].toLowerCase()] = i + 1;
    }
    // Full English month names sometimes used in mocks
    const fullEn = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december',
    ];
    for (var i = 0; i < fullEn.length; i++) {
      monthNames[fullEn[i]] = i + 1;
    }

    final tokenMatch = RegExp(
      r'^(\d{1,2})[,\s]+([A-Za-zÀ-ÿ]+)[,\s]+(\d{4})$|'
      r'^([A-Za-zÀ-ÿ]+)[,\s]+(\d{1,2})[,\s]+(\d{4})$',
    ).firstMatch(value);
    if (tokenMatch != null) {
      late final int day;
      late final String monthToken;
      late final int year;
      if (tokenMatch.group(1) != null) {
        day = int.parse(tokenMatch.group(1)!);
        monthToken = tokenMatch.group(2)!.toLowerCase();
        year = int.parse(tokenMatch.group(3)!);
      } else {
        monthToken = tokenMatch.group(4)!.toLowerCase();
        day = int.parse(tokenMatch.group(5)!);
        year = int.parse(tokenMatch.group(6)!);
      }
      final month = monthNames[monthToken] ??
          monthNames[monthToken.substring(0, monthToken.length.clamp(0, 3))];
      if (month != null) {
        return DateTime(year, month, day);
      }
    }

    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  static const List<String> _monthAbbrEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<String> _monthAbbrIt = [
    'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
    'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic',
  ];

  /// Tags for UI, with category/type switched by current language.
  /// Order: category, type name, file type (same as English tags).
  List<String> getLocalizedTags() {
    final localized = <String>[];
    final localizedCategory = getCategory();
    if (localizedCategory.isNotEmpty) {
      localized.add(localizedCategory);
    }
    final localizedType = getTypeName();
    if (localizedType.isNotEmpty) {
      localized.add(localizedType);
    }
    // Keep file-type tag (PDF, JPG, …) from stored tags when present.
    for (final tag in tags) {
      final lower = tag.toLowerCase().trim();
      if (lower == category.toLowerCase().trim() ||
          lower == categoryIt.toLowerCase().trim() ||
          lower == typeName.toLowerCase().trim() ||
          lower == typeNameIt.toLowerCase().trim()) {
        continue;
      }
      if (tag.isNotEmpty) {
        localized.add(tag);
      }
    }
    return localized;
  }

  /// Create DocumentModel from API response
  /// Supports both old format (with category_id, type_id) and new format
  /// with nested category/type objects including `*_it` fields.
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    String categoryName;
    String categoryNameIt = '';
    int? categoryId;
    int? typeId;
    String typeNameEn = '';
    String typeNameIt = '';

    if (json['category'] != null && json['category'] is Map) {
      final categoryMap = json['category'] as Map;
      categoryName = categoryMap['category_name']?.toString() ?? '';
      categoryNameIt = categoryMap['category_name_it']?.toString() ?? '';
      categoryId = categoryMap['id'] is int
          ? categoryMap['id'] as int
          : int.tryParse(categoryMap['id']?.toString() ?? '');
    } else {
      categoryId = json['category_id'] is int
          ? json['category_id'] as int
          : int.tryParse(json['category_id']?.toString() ?? '');
      categoryName = _getCategoryName(categoryId);
      categoryNameIt = json['category_name_it']?.toString() ?? '';
    }

    if (json['type'] != null && json['type'] is Map) {
      final typeMap = json['type'] as Map;
      typeNameEn = typeMap['type_name']?.toString() ?? '';
      typeNameIt = typeMap['type_name_it']?.toString() ?? '';
      typeId = typeMap['id'] is int
          ? typeMap['id'] as int
          : int.tryParse(typeMap['id']?.toString() ?? '');
    } else {
      typeId = json['type_id'] is int
          ? json['type_id'] as int
          : int.tryParse(json['type_id']?.toString() ?? '');
      typeNameEn = json['type_name']?.toString() ?? '';
      typeNameIt = json['type_name_it']?.toString() ?? '';
    }

    // Store English tags for stable matching/colors; UI uses getLocalizedTags().
    final tags = _generateTags(json, categoryName, typeNameEn);

    return DocumentModel(
      id: json['id']?.toString() ?? '',
      title: json['document_name'] ?? 'Untitled Document',
      type: (json['file_type'] ?? 'file').toString().toUpperCase(),
      category: categoryName,
      categoryIt: categoryNameIt,
      typeName: typeNameEn,
      typeNameIt: typeNameIt,
      date: json['uploaded_date'] ?? '',
      size: json['file_size'] ?? '',
      tags: tags,
      status: null,
      fileUrl: json['file_url'],
      description: json['document_description'],
      categoryId: categoryId,
      typeId: typeId,
      uploadedByUserId: _parseUploadedByUserId(json),
    );
  }

  /// Resident uploads are tagged in API metadata or via `_<userId>` in [file_url].
  static int? _parseUploadedByUserId(Map<String, dynamic> json) {
    final isAdminUpload = json['is_admin_upload'] ?? json['is_admin_uploaded'];
    if (isAdminUpload == true ||
        isAdminUpload == 1 ||
        isAdminUpload == '1' ||
        isAdminUpload == 'true') {
      return null;
    }

    for (final key in ['uploaded_by', 'uploaded_by_user_id', 'user_id']) {
      final value = json[key];
      if (value == null) continue;
      final id = value is int ? value : int.tryParse(value.toString());
      if (id != null && id > 0) return id;
    }

    final fileUrl = json['file_url']?.toString();
    if (fileUrl == null || fileUrl.isEmpty) return null;

    final fileName = fileUrl.split('/').last;
    final match = RegExp(r'_(\d+)\.[a-zA-Z0-9]+$').firstMatch(fileName);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    return null;
  }

  /// Convert DocumentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_name': title,
      'file_type': type.toLowerCase(),
      'category_id': categoryId,
      'uploaded_date': date,
      'file_size': size,
      'file_url': fileUrl,
      'document_description': description,
      'type_id': typeId,
      'category': {
        'id': categoryId,
        'category_name': category,
        'category_name_it': categoryIt,
      },
      'type': {
        'id': typeId,
        'type_name': typeName,
        'type_name_it': typeNameIt,
      },
      if (uploadedByUserId != null) 'uploaded_by': uploadedByUserId,
    };
  }

  /// Helper method to get category name from category_id
  static String _getCategoryName(int? categoryId) {
    switch (categoryId) {
      case 1:
        return 'Ownership & Legal';
      case 2:
        return 'Technical Building';
      case 3:
        return 'Energy & Environmental';
      case 4:
        return 'Compliance & Safety';
      case 5:
        return 'Administrative & Maintenance';
      default:
        return 'Others';
    }
  }

  /// Helper method to generate tags from document data
  static List<String> _generateTags(
    Map<String, dynamic> json, [
    String? categoryName,
    String? typeName,
  ]) {
    List<String> tags = [];

    if (categoryName != null && categoryName.isNotEmpty) {
      tags.add(categoryName);
    } else {
      final categoryId = json['category_id'];
      if (categoryId != null) {
        tags.add(_getCategoryName(
          categoryId is int ? categoryId : int.tryParse(categoryId.toString()),
        ));
      }
    }

    if (typeName != null && typeName.isNotEmpty) {
      tags.add(typeName);
    }

    if (json['file_type'] != null) {
      tags.add(json['file_type'].toString().toUpperCase());
    }

    return tags;
  }

  /// Copy with method for updating specific fields
  DocumentModel copyWith({
    String? id,
    String? title,
    String? type,
    String? category,
    String? categoryIt,
    String? typeName,
    String? typeNameIt,
    String? date,
    String? size,
    List<String>? tags,
    String? status,
    String? fileUrl,
    String? description,
    int? categoryId,
    int? typeId,
    int? uploadedByUserId,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      categoryIt: categoryIt ?? this.categoryIt,
      typeName: typeName ?? this.typeName,
      typeNameIt: typeNameIt ?? this.typeNameIt,
      date: date ?? this.date,
      size: size ?? this.size,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      typeId: typeId ?? this.typeId,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
    );
  }

  static final mockDocuments = <DocumentModel>[
    DocumentModel(
      id: 'md1',
      title: 'Appliance Warranty - Dishwasher',
      type: 'PDF',
      category: 'My Documents',
      date: 'Nov 3, 2025',
      size: '1.1 MB',
      tags: ['Personal', 'Guarantees'],
    ),
    DocumentModel(
      id: 'md2',
      title: 'Renovation Invoice - Kitchen',
      type: 'PDF',
      category: 'My Documents',
      date: 'Oct 20, 2025',
      size: '0.8 MB',
      tags: ['Personal', 'Invoices'],
    ),
    DocumentModel(
      id: 'md3',
      title: 'Interior Design Plans',
      type: 'JPG',
      category: 'My Documents',
      date: 'Oct 5, 2025',
      size: '3.2 MB',
      tags: ['Personal', 'Others'],
    ),
    DocumentModel(
      id: '1',
      title: 'Energy Performance Certificate 2025',
      type: 'PDF',
      category: 'Energy & Environmental',
      date: 'Oct 28, 2025',
      size: '2.4 MB',
      tags: ['Energy', 'Compliance'],
      status: 'New',
    ),
    DocumentModel(
      id: '2',
      title: 'Building Technical Specifications',
      type: 'PDF',
      category: 'Technical Building',
      date: 'Sep 15, 2025',
      size: '5.8 MB',
      tags: ['Technical', 'Specifications'],
    ),
    DocumentModel(
      id: '3',
      title: 'Property Deed - Unit 4B',
      type: 'PDF',
      category: 'Ownership & Legal',
      date: 'Aug 10, 2025',
      size: '1.2 MB',
      tags: ['Legal', 'Ownership'],
    ),
    DocumentModel(
      id: '4',
      title: 'HVAC System Drawings',
      type: 'DWG',
      category: 'Technical Building',
      date: 'Jul 22, 2025',
      size: '12.5 MB',
      tags: ['Technical', 'HVAC'],
    ),
    DocumentModel(
      id: '5',
      title: 'Fire Safety Compliance Report',
      type: 'PDF',
      date: 'Jun 30, 2025',
      size: '3.1 MB',
      category: 'Compliance & Safety',
      tags: ['Safety', 'Compliance'],
    ),
  ];
}
