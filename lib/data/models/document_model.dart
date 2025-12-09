class DocumentModel {
  final String id;
  final String title;
  final String type;
  final String category;
  final String date;
  final String size;
  final List<String> tags;
  final String? status;
  final String? fileUrl;
  final String? description;
  final int? categoryId;
  final int? typeId;

  DocumentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.date,
    required this.size,
    required this.tags,
    this.status,
    this.fileUrl,
    this.description,
    this.categoryId,
    this.typeId,
  });

  /// Create DocumentModel from API response
  /// Supports both old format (with category_id, type_id) and new format (with nested category, type, unit objects)
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    // Handle new API format with nested objects
    String categoryName;
    int? categoryId;
    int? typeId;
    String typeName = '';

    if (json['category'] != null && json['category'] is Map) {
      // New format: nested category object
      categoryName = json['category']['category_name'] ?? '';
      categoryId = json['category']['id'];
    } else {
      // Old format: category_id
      categoryId = json['category_id'];
      categoryName = _getCategoryName(categoryId);
    }

    if (json['type'] != null && json['type'] is Map) {
      // New format: nested type object
      typeName = json['type']['type_name'] ?? '';
      typeId = json['type']['id'];
    } else {
      // Old format: type_id
      typeId = json['type_id'];
    }

    // Generate tags including type name if available
    List<String> tags = _generateTags(json, categoryName, typeName);

    return DocumentModel(
      id: json['id']?.toString() ?? '',
      title: json['document_name'] ?? 'Untitled Document',
      type: (json['file_type'] ?? 'file').toString().toUpperCase(),
      category: categoryName,
      date: json['uploaded_date'] ?? '',
      size: json['file_size'] ?? '',
      tags: tags,
      status: null, // Can be extended later if needed
      fileUrl: json['file_url'],
      description: json['document_description'],
      categoryId: categoryId,
      typeId: typeId,
    );
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
    };
  }

  /// Helper method to get category name from category_id
  static String _getCategoryName(int? categoryId) {
    // Default categories based on common IDs
    // This can be extended based on actual category data
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

    // Add category-based tag
    if (categoryName != null && categoryName.isNotEmpty) {
      tags.add(categoryName);
    } else {
      final categoryId = json['category_id'];
      if (categoryId != null) {
        tags.add(_getCategoryName(categoryId));
      }
    }

    // Add type name tag if available
    if (typeName != null && typeName.isNotEmpty) {
      tags.add(typeName);
    }

    // Add file type tag
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
    String? date,
    String? size,
    List<String>? tags,
    String? status,
    String? fileUrl,
    String? description,
    int? categoryId,
    int? typeId,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      size: size ?? this.size,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      typeId: typeId ?? this.typeId,
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
