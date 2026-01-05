// presentation/maintenance/models/maintenance_task_model.dart
// Maintenance Task Models

import 'maintenance_category_model.dart';

enum MaintenancePriority { facoltative, obbligatorie, condominiali, personal, n1, n2, n3 }

enum MaintenanceStatus { pending, inProgress, completed, overdue }

/// Maintenance Task Model matching API response structure
class MaintenanceTask {
  final String id; // Converted to String for UI compatibility
  final String title; // maintenance_title
  final String category; // category.name (from nested object)
  final String? description; // maintenance_note (optional)
  final MaintenancePriority priority; // Derived from category or default
  final String? priorityRaw; // Raw priority value from API (N1, N2, N3)
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
    this.priorityRaw,
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
    // DEBUG: Log full task JSON to find priority field
    print('🔍 [MaintenanceTask] Full task JSON for ID ${json['id']}:');
    print('   All keys: ${json.keys.toList()}');
    // Log all fields that might contain priority
    json.forEach((key, value) {
      if (key.toLowerCase().contains('priority') || 
          key.toLowerCase().contains('priorita') ||
          key.toLowerCase().contains('n1') ||
          key.toLowerCase().contains('n2') ||
          key.toLowerCase().contains('n3')) {
        print('   🔑 Found potential priority field: $key = $value (type: ${value.runtimeType})');
      }
    });
    
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

    // Get category name from nested object or fallback (use name_en if available)
    final categoryName = categoryObj?.nameEn.isNotEmpty == true 
        ? categoryObj!.nameEn 
        : (categoryObj?.name ?? 'Unknown');

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

    // Parse priority from API (can be N1, N2, N3 or other values)
    MaintenancePriority priority = MaintenancePriority.personal; // Default fallback
    String? priorityRawValue; // Store raw value from API for direct display
    
    // Try multiple possible field names for priority
    // Check new API structure first (maintenance_priority object)
    dynamic priorityValue;
    
    // Check for maintenance_priority nested object (new API structure) FIRST
    if (json['maintenance_priority'] != null && json['maintenance_priority'] is Map) {
      final priorityObj = json['maintenance_priority'] as Map<String, dynamic>;
      // New API structure: { "name": "N2", "priority_type": "Mandatory" }
      final priorityName = priorityObj['name']?.toString() ?? '';
      final priorityType = priorityObj['priority_type']?.toString() ?? '';
      // Combine as "N2-Mandatory" format
      if (priorityName.isNotEmpty && priorityType.isNotEmpty) {
        priorityRawValue = '$priorityName-$priorityType';
        print('✅ [MaintenanceTask] Combined priority: $priorityRawValue');
        priorityValue = priorityName; // Use name for enum mapping
      } else if (priorityName.isNotEmpty) {
        priorityRawValue = priorityName;
        priorityValue = priorityName;
      } else {
        priorityValue = priorityObj['id'] ?? 
                        priorityObj['value'] ??
                        priorityObj['name_en'] ??
                        priorityObj['priority'];
      }
    } else {
      // Fallback to old structure or direct fields
      priorityValue = json['priority'] ?? 
                     json['priority_id'] ?? 
                     json['maintenance_priority_id'] ??
                     json['priorityId'] ??
                     json['maintenancePriority'] ??
                     json['maintenancePriorityId'] ??
                     json['priority_name'] ??
                     json['priorityName'] ??
                     json['priority_level'] ??
                     json['priorityLevel'];
      
      // If not found, check for nested priority object
      if (priorityValue == null && json['priority'] is Map) {
        final priorityObj = json['priority'] as Map<String, dynamic>;
        priorityValue = priorityObj['id'] ?? 
                       priorityObj['name'] ?? 
                       priorityObj['value'] ??
                       priorityObj['name_en'] ??
                       priorityObj['priority'];
      }
    }
    
    // DEBUG: Log priority data from API
    print('🔍 [MaintenanceTask] Priority field check for task ID: ${json['id']}');
    print('🔍 [MaintenanceTask] priorityValue found: $priorityValue (type: ${priorityValue != null ? priorityValue.runtimeType : 'null'})');
    
    if (priorityValue != null) {
      String priorityStr = '';
      
      // Handle different data types
      if (priorityValue is Map) {
        // Nested object: try common keys
        final priorityObj = priorityValue as Map<String, dynamic>;
        final extractedValue = priorityObj['name'] ?? 
                              priorityObj['priority'] ?? 
                              priorityObj['value'] ?? 
                              priorityObj['name_en'] ?? 
                              '';
        priorityStr = extractedValue.toString().toUpperCase().trim();
        // Store original extracted value (preserve full string for display)
        priorityRawValue = extractedValue.toString().trim();
      } else if (priorityValue is num) {
        // Numeric ID: map 1=N1, 2=N2, 3=N3
        final priorityNum = priorityValue.toInt();
        switch (priorityNum) {
          case 1:
            priorityStr = 'N1';
            priorityRawValue = 'N1';
            break;
          case 2:
            priorityStr = 'N2';
            priorityRawValue = 'N2';
            break;
          case 3:
            priorityStr = 'N3';
            priorityRawValue = 'N3';
            break;
          default:
            priorityStr = priorityValue.toString().toUpperCase().trim();
            priorityRawValue = null;
        }
      } else {
        // String value - store original value for display (preserve full string like "N1-optional")
        priorityStr = priorityValue.toString().toUpperCase().trim();
        // Only overwrite priorityRawValue if it's not already set (preserve combined format like "N2-Mandatory")
        if (priorityRawValue == null || !priorityRawValue.contains('-')) {
          priorityRawValue = priorityValue.toString().trim();
        }
      }
      
      // Map priority string to enum
      switch (priorityStr) {
        case 'N1':
        case '1':
          priority = MaintenancePriority.n1;
          if (priorityRawValue == null) priorityRawValue = 'N1';
          break;
        case 'N2':
        case '2':
          priority = MaintenancePriority.n2;
          if (priorityRawValue == null) priorityRawValue = 'N2';
          break;
        case 'N3':
        case '3':
          priority = MaintenancePriority.n3;
          if (priorityRawValue == null) priorityRawValue = 'N3';
          break;
        case 'FACOLTATIVE':
        case 'FACOLTATIVA':
          priority = MaintenancePriority.facoltative;
          break;
        case 'OBBLIGATORIE':
        case 'OBBLIGATORIA':
          priority = MaintenancePriority.obbligatorie;
          break;
        case 'CONDOMINIALI':
        case 'CONDOMINIALE':
          priority = MaintenancePriority.condominiali;
          break;
        case 'PERSONAL':
        case 'PERSONALE':
          priority = MaintenancePriority.personal;
          break;
        default:
          // If not recognized, try to use the raw value if it looks like N1/N2/N3
          if (priorityRawValue != null && 
              (priorityRawValue.toUpperCase().contains('N1') || 
               priorityRawValue.toUpperCase().contains('N2') || 
               priorityRawValue.toUpperCase().contains('N3'))) {
            // Map to enum based on which priority is found, but preserve original value for display
            if (priorityRawValue.toUpperCase().contains('N1')) {
              priority = MaintenancePriority.n1;
              // Keep original priorityRawValue (don't overwrite)
            } else if (priorityRawValue.toUpperCase().contains('N2')) {
              priority = MaintenancePriority.n2;
              // Keep original priorityRawValue (don't overwrite)
            } else if (priorityRawValue.toUpperCase().contains('N3')) {
              priority = MaintenancePriority.n3;
              // Keep original priorityRawValue (don't overwrite)
            } else {
              priority = MaintenancePriority.personal;
            }
          } else {
            priority = MaintenancePriority.personal;
          }
      }
      
      // DEBUG: Log parsed priority
      print('🔍 [MaintenanceTask] Parsed priority: enum=$priority, raw=$priorityRawValue');
    } else {
      print('⚠️ [MaintenanceTask] No priority value found in API response, using default: personal');
    }

    // Parse maintenance_frequency (can be object with name_en or string)
    String frequencyStr = '';
    if (json['maintenance_frequency'] != null) {
      if (json['maintenance_frequency'] is Map) {
        // It's an object, extract name_en
        final freqObj = json['maintenance_frequency'] as Map<String, dynamic>;
        frequencyStr = freqObj['name_en']?.toString() ?? 
                      freqObj['name']?.toString() ?? '';
      } else {
        // It's a string
        frequencyStr = json['maintenance_frequency'].toString();
      }
    }

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

    // Get IDs from nested objects if not present directly
    final maintenanceCategoryId = json['maintenance_category_id'] ?? categoryObj?.id ?? 0;
    final residenceId = json['residence_id'] ?? residenceObj?.id ?? 0;
    final maintenanceItemId = json['maintenance_item_id'] ?? itemObj?.id;

    return MaintenanceTask(
      id: (json['id'] ?? 0).toString(), // Convert to String for UI compatibility
      title: json['maintenance_title']?.toString() ?? '',
      category: categoryName,
      description: json['maintenance_note']?.toString(),
      priority: priority,
      priorityRaw: priorityRawValue,
      status: status,
      frequency: frequencyStr,
      nextDue: dueDateStr.isNotEmpty ? dueDateStr : null,
      lastCompleted: lastMaintenanceDateStr,
      maintenanceCategoryId: maintenanceCategoryId,
      maintenanceItemId: maintenanceItemId,
      residenceId: residenceId,
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
  final String nameEn;

  MaintenanceItem({
    required this.id,
    required this.name,
    required this.nameEn,
  });

  factory MaintenanceItem.fromJson(Map<String, dynamic> json) {
    return MaintenanceItem(
      id: json['id'] ?? 0,
      name: json['item_name_it']?.toString() ?? json['name']?.toString() ?? '',
      nameEn: json['item_name_en']?.toString() ?? json['name_en']?.toString() ?? '',
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



