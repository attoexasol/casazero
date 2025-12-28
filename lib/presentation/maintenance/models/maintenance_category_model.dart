// presentation/maintenance/models/maintenance_category_model.dart
// Maintenance Category Model

class MaintenanceCategory {
  final int id;
  final String name;
  final String description;

  MaintenanceCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  /// Create MaintenanceCategory from JSON
  factory MaintenanceCategory.fromJson(Map<String, dynamic> json) {
    return MaintenanceCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  /// Convert MaintenanceCategory to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}


