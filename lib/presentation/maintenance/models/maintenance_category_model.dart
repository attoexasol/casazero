// presentation/maintenance/models/maintenance_category_model.dart
// Maintenance Category Model

class MaintenanceCategory {
  final int id;
  final String name;
  final String nameEn;
  final String description;

  MaintenanceCategory({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
  });

  /// Create MaintenanceCategory from JSON
  factory MaintenanceCategory.fromJson(Map<String, dynamic> json) {
    return MaintenanceCategory(
      id: json['id'] as int? ?? 0,
      // New API structure: use name_it, fallback to name or category_name
      name: (json['name_it'] as String? ?? json['name'] as String? ?? json['category_name'] as String? ?? '').toString(),
      // Parse name_en from API response
      nameEn: (json['name_en'] as String? ?? '').toString(),
      // Check both 'description' and 'category_description' keys
      description: (json['description'] as String? ?? json['category_description'] as String? ?? '').toString(),
    );
  }

  /// Convert MaintenanceCategory to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'description': description,
    };
  }
}



