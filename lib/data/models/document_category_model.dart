class DocumentCategoryModel {
  final int id;
  final String categoryName;
  final String categoryDescription;
  final String createdAt;
  final String updatedAt;

  // Additional field for UI display
  final int count;

  DocumentCategoryModel({
    required this.id,
    required this.categoryName,
    required this.categoryDescription,
    required this.createdAt,
    required this.updatedAt,
    this.count = 0,
  });

  factory DocumentCategoryModel.fromJson(Map<String, dynamic> json) {
    return DocumentCategoryModel(
      id: json['id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      categoryDescription: json['category_description'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_name': categoryName,
      'category_description': categoryDescription,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'count': count,
    };
  }

  DocumentCategoryModel copyWith({
    int? id,
    String? categoryName,
    String? categoryDescription,
    String? createdAt,
    String? updatedAt,
    int? count,
  }) {
    return DocumentCategoryModel(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      categoryDescription: categoryDescription ?? this.categoryDescription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      count: count ?? this.count,
    );
  }
}
