// presentation/maintenance/models/maintenance_task_model.dart
// Maintenance Task Models

import 'package:get/get.dart';
import '../../../core/localization/locale_controller.dart';
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
  final String frequency; // maintenance_frequency (deprecated - use getFrequency() for reactive updates)
  final Map<String, dynamic>? frequencyObj; // Raw frequency object from API (for reactive language updates)
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
  final MaintenanceCompany? companyObj; // Nested company object
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
    this.frequencyObj,
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
    this.companyObj,
    this.maintenanceNote,
    required this.dueDate,
    this.lastMaintenanceDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Get frequency based on current language settings (reactive)
  /// Returns name_en for English, name_it for Italian
  String getFrequency() {
    // If frequencyObj exists, use it to get language-specific value
    if (frequencyObj != null) {
      try {
        final localeController = Get.find<LocaleController>();
        final isEnglish = localeController.isEnglish;
        
        if (isEnglish) {
          // English: use name_en, fallback to name
          return frequencyObj!['name_en']?.toString().trim() ?? 
                 frequencyObj!['name']?.toString().trim() ?? 
                 frequency;
        } else {
          // Italian: use name_it, fallback to name_en, then name
          return frequencyObj!['name_it']?.toString().trim() ?? 
                 frequencyObj!['name_en']?.toString().trim() ?? 
                 frequencyObj!['name']?.toString().trim() ?? 
                 frequency;
        }
      } catch (e) {
        // Fallback if LocaleController not available
        return frequencyObj!['name_en']?.toString().trim() ?? 
               frequencyObj!['name']?.toString().trim() ?? 
               frequency;
      }
    }
    // If no frequencyObj, return the stored frequency string
    return frequency;
  }

  /// Get category name based on current language settings (reactive)
  /// Returns name_en for English, name (name_it) for Italian
  String getCategory() {
    // If categoryObj exists, use it to get language-specific value
    if (categoryObj != null) {
      try {
        final localeController = Get.find<LocaleController>();
        final isEnglish = localeController.isEnglish;
        
        if (isEnglish) {
          // English: use nameEn, fallback to name
          return categoryObj!.nameEn.isNotEmpty 
              ? categoryObj!.nameEn 
              : (categoryObj!.name.isNotEmpty ? categoryObj!.name : category);
        } else {
          // Italian: use name (which is mapped from name_it), fallback to nameEn
          return categoryObj!.name.isNotEmpty 
              ? categoryObj!.name 
              : (categoryObj!.nameEn.isNotEmpty ? categoryObj!.nameEn : category);
        }
      } catch (e) {
        // Fallback if LocaleController not available
        return categoryObj!.nameEn.isNotEmpty 
            ? categoryObj!.nameEn 
            : (categoryObj!.name.isNotEmpty ? categoryObj!.name : category);
      }
    }
    // If no categoryObj, return the stored category string
    return category;
  }

  /// Get item name based on current language settings (reactive)
  /// Returns nameEn for English, name (item_name_it) for Italian
  String? getItemName() {
    // If itemObj exists, use it to get language-specific value
    if (itemObj != null) {
      try {
        final localeController = Get.find<LocaleController>();
        final isEnglish = localeController.isEnglish;
        
        if (isEnglish) {
          // English: use nameEn, fallback to name
          return itemObj!.nameEn.isNotEmpty 
              ? itemObj!.nameEn 
              : (itemObj!.name.isNotEmpty ? itemObj!.name : null);
        } else {
          // Italian: use name (which is mapped from item_name_it), fallback to nameEn
          return itemObj!.name.isNotEmpty 
              ? itemObj!.name 
              : (itemObj!.nameEn.isNotEmpty ? itemObj!.nameEn : null);
        }
      } catch (e) {
        // Fallback if LocaleController not available
        return itemObj!.nameEn.isNotEmpty 
            ? itemObj!.nameEn 
            : (itemObj!.name.isNotEmpty ? itemObj!.name : null);
      }
    }
    // If no itemObj, return null
    return null;
  }

  /// Get title based on current language settings (reactive)
  /// Uses item_name_en for English, item_name_it for Italian
  /// Falls back to maintenance_title if item is not available
  String getTitle() {
    // If itemObj exists, use it as title (item_name_en/item_name_it)
    if (itemObj != null) {
      try {
        final localeController = Get.find<LocaleController>();
        final isEnglish = localeController.isEnglish;
        
        if (isEnglish) {
          // English: use nameEn (item_name_en), fallback to name, then title
          return itemObj!.nameEn.isNotEmpty 
              ? itemObj!.nameEn 
              : (itemObj!.name.isNotEmpty ? itemObj!.name : title);
        } else {
          // Italian: use name (item_name_it), fallback to nameEn, then title
          return itemObj!.name.isNotEmpty 
              ? itemObj!.name 
              : (itemObj!.nameEn.isNotEmpty ? itemObj!.nameEn : title);
        }
      } catch (e) {
        // Fallback if LocaleController not available
        return itemObj!.nameEn.isNotEmpty 
            ? itemObj!.nameEn 
            : (itemObj!.name.isNotEmpty ? itemObj!.name : title);
      }
    }
    // If no itemObj, return the stored title (maintenance_title)
    return title;
  }

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

    // Parse nested company object
    MaintenanceCompany? companyObj;
    if (json['company'] != null && json['company'] is Map) {
      companyObj = MaintenanceCompany.fromJson(json['company']);
      // DEBUG: Log company phone for verification
      print('📞 [MaintenanceTask] Company phone: ${companyObj.phone}');
    }

    // Get category name from nested object based on user's language settings
    String categoryName = 'Unknown';
    try {
      final localeController = Get.find<LocaleController>();
      final isEnglish = localeController.isEnglish;
      
      if (categoryObj != null) {
        if (isEnglish) {
          // English: use name_en, fallback to name
          categoryName = categoryObj.nameEn.isNotEmpty 
              ? categoryObj.nameEn 
              : (categoryObj.name.isNotEmpty ? categoryObj.name : 'Unknown');
        } else {
          // Italian: use name (name_it), fallback to name_en
          categoryName = categoryObj.name.isNotEmpty 
              ? categoryObj.name 
              : (categoryObj.nameEn.isNotEmpty ? categoryObj.nameEn : 'Unknown');
        }
      }
    } catch (e) {
      // Fallback if LocaleController not available
      categoryName = categoryObj?.nameEn.isNotEmpty == true 
          ? categoryObj!.nameEn 
          : (categoryObj?.name ?? 'Unknown');
    }

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

    // Parse maintenance_frequency (can be object with name_en/name_it or string)
    String frequencyStr = '';
    Map<String, dynamic>? frequencyObj;
    
    if (json['maintenance_frequency'] != null) {
      if (json['maintenance_frequency'] is Map) {
        // It's an object, store it for reactive language updates
        frequencyObj = Map<String, dynamic>.from(json['maintenance_frequency'] as Map);
        print('🔍 [MaintenanceTask] Frequency object: $frequencyObj');
        print('🔍 [MaintenanceTask] Frequency keys: ${frequencyObj.keys.toList()}');
        
        // Also set initial frequency based on current language
        try {
          final localeController = Get.find<LocaleController>();
          final isEnglish = localeController.isEnglish;
          
          print('🌐 [MaintenanceTask] User language - isEnglish: $isEnglish');
          
          if (isEnglish) {
            // English: use name_en, fallback to name
            frequencyStr = frequencyObj['name_en']?.toString().trim() ?? 
                          frequencyObj['name']?.toString().trim() ?? '';
            print('🌐 [MaintenanceTask] Selected frequency (EN): "$frequencyStr"');
          } else {
            // Italian: use name_it, fallback to name_en, then name
            frequencyStr = frequencyObj['name_it']?.toString().trim() ?? 
                          frequencyObj['name_en']?.toString().trim() ?? 
                          frequencyObj['name']?.toString().trim() ?? '';
            print('🌐 [MaintenanceTask] Selected frequency (IT): "$frequencyStr"');
          }
        } catch (e) {
          print('⚠️ [MaintenanceTask] LocaleController not found, defaulting to English');
          // Fallback if LocaleController not available
          frequencyStr = frequencyObj['name_en']?.toString().trim() ?? 
                        frequencyObj['name']?.toString().trim() ?? '';
        }
      } else {
        // It's a string - store as is
        frequencyStr = json['maintenance_frequency'].toString().trim();
        print('🔍 [MaintenanceTask] Frequency is string: "$frequencyStr"');
      }
    }
    
    print('✅ [MaintenanceTask] Final frequency value: "$frequencyStr"');

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

    // Title will be populated from item_name_en/item_name_it (reactive via getTitle())
    // Fallback to maintenance_title if item is not available
    // Use item name as title if available, otherwise use maintenance_title
    String maintenanceTitle = '';
    
    if (itemObj != null) {
      // Use item name as title (item_name_en/item_name_it)
      try {
        final localeController = Get.find<LocaleController>();
        final isEnglish = localeController.isEnglish;
        
        if (isEnglish) {
          // English: use item_name_en, fallback to item name, then maintenance_title
          maintenanceTitle = itemObj.nameEn.isNotEmpty 
              ? itemObj.nameEn 
              : (itemObj.name.isNotEmpty ? itemObj.name : (json['maintenance_title']?.toString() ?? ''));
        } else {
          // Italian: use item_name_it, fallback to item_name_en, then maintenance_title
          maintenanceTitle = itemObj.name.isNotEmpty 
              ? itemObj.name 
              : (itemObj.nameEn.isNotEmpty ? itemObj.nameEn : (json['maintenance_title']?.toString() ?? ''));
        }
      } catch (e) {
        // Fallback if LocaleController not available
        maintenanceTitle = itemObj.nameEn.isNotEmpty 
            ? itemObj.nameEn 
            : (itemObj.name.isNotEmpty ? itemObj.name : (json['maintenance_title']?.toString() ?? ''));
      }
    } else {
      // If no item, use maintenance_title as fallback
      maintenanceTitle = json['maintenance_title']?.toString() ?? '';
    }
    
    return MaintenanceTask(
      id: (json['id'] ?? 0).toString(), // Convert to String for UI compatibility
      title: maintenanceTitle,
      category: categoryName,
      description: json['maintenance_note']?.toString(),
      priority: priority,
      priorityRaw: priorityRawValue,
      status: status,
      frequency: frequencyStr,
      frequencyObj: frequencyObj, // Store raw object for reactive language updates
      nextDue: dueDateStr.isNotEmpty ? dueDateStr : null,
      lastCompleted: lastMaintenanceDateStr,
      maintenanceCategoryId: maintenanceCategoryId,
      maintenanceItemId: maintenanceItemId,
      residenceId: residenceId,
      categoryObj: categoryObj,
      itemObj: itemObj,
      residenceObj: residenceObj,
      companyObj: companyObj,
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
    // Get item name based on user's language settings
    String itemName = '';
    String itemNameEn = '';
    
    try {
      final localeController = Get.find<LocaleController>();
      final isEnglish = localeController.isEnglish;
      
      // Always store both language versions
      itemNameEn = json['item_name_en']?.toString() ?? 
                   json['name_en']?.toString() ?? '';
      
      // For name field, use the appropriate language
      if (isEnglish) {
        // English: use item_name_en, fallback to name
        itemName = json['item_name_en']?.toString() ?? 
                  json['name_en']?.toString() ?? 
                  json['name']?.toString() ?? '';
      } else {
        // Italian: use item_name_it, fallback to name
        itemName = json['item_name_it']?.toString() ?? 
                  json['name']?.toString() ?? 
                  json['item_name_en']?.toString() ?? 
                  json['name_en']?.toString() ?? '';
      }
    } catch (e) {
      // Fallback if LocaleController not available
      itemName = json['item_name_it']?.toString() ?? 
                json['name']?.toString() ?? '';
      itemNameEn = json['item_name_en']?.toString() ?? 
                   json['name_en']?.toString() ?? '';
    }
    
    return MaintenanceItem(
      id: json['id'] ?? 0,
      name: itemName,
      nameEn: itemNameEn,
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

/// Nested Company model from API
class MaintenanceCompany {
  final int id;
  final String name;
  final String? phone;

  MaintenanceCompany({
    required this.id,
    required this.name,
    this.phone,
  });

  factory MaintenanceCompany.fromJson(Map<String, dynamic> json) {
    return MaintenanceCompany(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
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



