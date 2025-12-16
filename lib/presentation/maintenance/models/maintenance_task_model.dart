// presentation/maintenance/models/maintenance_task_model.dart
// Maintenance Task Models

import 'maintenance_category_model.dart';

enum MaintenancePriority { facoltative, obbligatorie, condominiali, personal }

enum MaintenanceStatus { pending, inProgress, completed, overdue }

/// Maintenance Task Model matching API response structure
class MaintenanceTask {
  final String id; // Converted to String for UI compatibility
  final String title; // maintenance_title
  final String category; // category.name (from nested object)
  final String? description; // maintenance_note (optional)
  final MaintenancePriority priority; // Derived from category or default
  final MaintenanceStatus status; // maintenance_status
  final String frequency; // maintenance_frequency
  final String? nextDue; // due_date formatted
  final String? lastCompleted; // last_maintenance_date formatted
  final List<TaskAttachment>? attachments;
  final List<TaskContact>? contacts;
  
  // API fields
  final int maintenanceCategoryId;
  final int? maintenanceItemId;
  final int residenceId;
  final MaintenanceCategory? categoryObj; // Nested category object (using existing model)
  final MaintenanceItem? itemObj; // Nested item object
  final MaintenanceResidence? residenceObj; // Nested residence object
  final String? maintenanceNote;
  final String dueDate; // Raw due_date from API
  final String? lastMaintenanceDate; // Raw last_maintenance_date from API
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MaintenanceTask({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    required this.priority,
    required this.status,
    required this.frequency,
    this.nextDue,
    this.lastCompleted,
    this.attachments,
    this.contacts,
    required this.maintenanceCategoryId,
    this.maintenanceItemId,
    required this.residenceId,
    this.categoryObj,
    this.itemObj,
    this.residenceObj,
    this.maintenanceNote,
    required this.dueDate,
    this.lastMaintenanceDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to parse from API JSON
  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    // Parse nested category object (using existing MaintenanceCategory model)
    MaintenanceCategory? categoryObj;
    if (json['category'] != null && json['category'] is Map) {
      categoryObj = MaintenanceCategory.fromJson(json['category']);
    }

    // Parse nested item object
    MaintenanceItem? itemObj;
    if (json['item'] != null && json['item'] is Map) {
      itemObj = MaintenanceItem.fromJson(json['item']);
    }

    // Parse nested residence object
    MaintenanceResidence? residenceObj;
    if (json['residence'] != null && json['residence'] is Map) {
      residenceObj = MaintenanceResidence.fromJson(json['residence']);
    }

    // Get category name from nested object or fallback
    final categoryName = categoryObj?.name ?? 'Unknown';

    // Parse status (API returns string like "pending")
    final statusString = json['maintenance_status']?.toString().toLowerCase() ?? 'pending';
    MaintenanceStatus status;
    switch (statusString) {
      case 'pending':
        status = MaintenanceStatus.pending;
        break;
      case 'in_progress':
      case 'inprogress':
        status = MaintenanceStatus.inProgress;
        break;
      case 'completed':
      case 'done':
        status = MaintenanceStatus.completed;
        break;
      case 'overdue':
        status = MaintenanceStatus.overdue;
        break;
      default:
        status = MaintenanceStatus.pending;
    }

    // Determine priority (default to personal if not specified)
    // This can be enhanced based on business logic
    MaintenancePriority priority = MaintenancePriority.personal;

    // Format dates
    final dueDateStr = json['due_date']?.toString() ?? '';
    final lastMaintenanceDateStr = json['last_maintenance_date']?.toString();

    // Parse dates
    DateTime? createdAt;
    DateTime? updatedAt;
    try {
      if (json['created_at'] != null) {
        createdAt = DateTime.parse(json['created_at'].toString());
      }
      if (json['updated_at'] != null) {
        updatedAt = DateTime.parse(json['updated_at'].toString());
      }
    } catch (e) {
      print('Error parsing dates: $e');
    }

    return MaintenanceTask(
      id: (json['id'] ?? 0).toString(), // Convert to String for UI compatibility
      title: json['maintenance_title']?.toString() ?? '',
      category: categoryName,
      description: json['maintenance_note']?.toString(),
      priority: priority,
      status: status,
      frequency: json['maintenance_frequency']?.toString() ?? '',
      nextDue: dueDateStr.isNotEmpty ? dueDateStr : null,
      lastCompleted: lastMaintenanceDateStr,
      maintenanceCategoryId: json['maintenance_category_id'] ?? 0,
      maintenanceItemId: json['maintenance_item_id'],
      residenceId: json['residence_id'] ?? 0,
      categoryObj: categoryObj,
      itemObj: itemObj,
      residenceObj: residenceObj,
      maintenanceNote: json['maintenance_note']?.toString(),
      dueDate: dueDateStr,
      lastMaintenanceDate: lastMaintenanceDateStr,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Nested Item model from API
class MaintenanceItem {
  final int id;
  final String name;

  MaintenanceItem({
    required this.id,
    required this.name,
  });

  factory MaintenanceItem.fromJson(Map<String, dynamic> json) {
    return MaintenanceItem(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Nested Residence model from API
class MaintenanceResidence {
  final int id;
  final String residenceName;
  final String? residencePhoto;

  MaintenanceResidence({
    required this.id,
    required this.residenceName,
    this.residencePhoto,
  });

  factory MaintenanceResidence.fromJson(Map<String, dynamic> json) {
    return MaintenanceResidence(
      id: json['id'] ?? 0,
      residenceName: json['residence_name']?.toString() ?? '',
      residencePhoto: json['residence_photo']?.toString(),
    );
  }
}

class TaskAttachment {
  final String name;
  final String type;
  final String url;

  TaskAttachment({
    required this.name,
    required this.type,
    required this.url,
  });
}

class TaskContact {
  final String name;
  final String role;
  final String? phone;
  final String? email;

  TaskContact({
    required this.name,
    required this.role,
    this.phone,
    this.email,
  });
}



