// presentation/maintenance/models/maintenance_task_model.dart
// Maintenance Task Models

import 'package:get/get.dart';
import '../../../core/localization/locale_controller.dart';
import 'maintenance_category_model.dart';

enum MaintenancePriority { facoltative, obbligatorie, condominiali, personal, n1, n2, n3 }

enum MaintenanceStatus { pending, inProgress, completed, overdue, due }

/// Maintenance Task Model matching API response structure
class MaintenanceTask {
  final String id; // Converted to String for UI compatibility
  final String title; // maintenance_title
  final String category; // category.name (from nested object)
  final String? description; // maintenance_note (optional)
  final MaintenancePriority priority; // Derived from category or default
  final String? priorityRaw; // Raw priority value from API (usually Italian `name`)
  /// English priority label from API (`priority.priority_type` / `priority_info.type`)
  final String? priorityNameEn;
  /// Italian priority label from API (`priority.name` / `priority_info.name`)
  final String? priorityNameIt;
  /// Parsed from API `status` only (e.g. pending, Due / In Scadenza, overdue)
  final MaintenanceStatus status;
  /// Raw `status` string from API
  final String? statusRaw;
  /// English status label from API when provided
  final String? statusNameEn;
  /// Italian status label from API when provided
  final String? statusNameIt;
  final String frequency; // maintenance_frequency (deprecated - use getFrequency() for reactive updates)
  final Map<String, dynamic>? frequencyObj; // Raw frequency object from API (for reactive language updates)
  final String? nextDue; // due_date formatted
  final String? lastCompleted; // last_maintenance_date formatted
  final List<TaskAttachment>? attachments;
  final List<TaskContact>? contacts;
  
  // API fields
  final int maintenanceCategoryId;
  final int? maintenanceItemId;
  /// Pivot id for residence-maintenance row (`maintenance_residence_id`).
  /// Used by change/undo maintenance status APIs.
  final int? maintenanceResidenceId;
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
    this.priorityNameEn,
    this.priorityNameIt,
    required this.status,
    this.statusRaw,
    this.statusNameEn,
    this.statusNameIt,
    required this.frequency,
    this.frequencyObj,
    this.nextDue,
    this.lastCompleted,
    this.attachments,
    this.contacts,
    required this.maintenanceCategoryId,
    this.maintenanceItemId,
    this.maintenanceResidenceId,
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

  /// Status badge label from API `status`, bilingual and reactive.
  /// Prefer API EN/IT labels; otherwise map known values; else show raw status.
  String getStatusLabel() {
    try {
      final localeController = Get.find<LocaleController>();
      if (localeController.isEnglish) {
        final en = statusNameEn?.trim();
        if (en != null && en.isNotEmpty) return en;
        final it = statusNameIt?.trim();
        if (it != null && it.isNotEmpty) {
          // Known IT → EN display when only IT was returned
          final mapped = _statusDisplayFromKnownValue(it);
          if (mapped != null) return mapped;
        }
      } else {
        final it = statusNameIt?.trim();
        if (it != null && it.isNotEmpty) return it;
        final en = statusNameEn?.trim();
        if (en != null && en.isNotEmpty) {
          final mapped = _statusDisplayFromKnownValue(en);
          if (mapped != null) return mapped;
        }
      }
    } catch (_) {}

    final mapped = _statusDisplayFromKnownValue(statusRaw) ??
        _statusDisplayFromEnum(status);
    if (mapped != null && mapped.isNotEmpty) return mapped;

    return statusRaw?.trim() ?? '';
  }

  String? _statusDisplayFromEnum(MaintenanceStatus value) {
    switch (value) {
      case MaintenanceStatus.pending:
        return 'pendingStatus'.tr;
      case MaintenanceStatus.inProgress:
        return 'inProgressStatus'.tr;
      case MaintenanceStatus.completed:
        return 'completedStatus'.tr;
      case MaintenanceStatus.overdue:
        return 'overdueStatus'.tr;
      case MaintenanceStatus.due:
        return 'dueStatus'.tr;
    }
  }

  String? _statusDisplayFromKnownValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final n = raw.toLowerCase().trim().replaceAll('-', '_').replaceAll(' ', '_');
    if (n == 'pending' || n == 'in_attesa' || n == 'attesa') {
      return 'pendingStatus'.tr;
    }
    if (n == 'in_progress' ||
        n == 'inprogress' ||
        n == 'in_corso' ||
        n.contains('progress') ||
        n.contains('corso')) {
      return 'inProgressStatus'.tr;
    }
    if (n == 'completed' ||
        n == 'done' ||
        n == 'completato' ||
        n == 'completata' ||
        n.contains('complet')) {
      return 'completedStatus'.tr;
    }
    if (n == 'overdue' || n == 'scaduto' || n == 'scaduta') {
      return 'overdueStatus'.tr;
    }
    // "In Scadenza" / "Due" (coming due) — distinct from overdue/scaduto
    if (n == 'due' ||
        n == 'in_scadenza' ||
        n == 'scadenza' ||
        n.contains('in_scadenza') ||
        n.contains('scadenza')) {
      return 'dueStatus'.tr;
    }
    return null;
  }

  /// Priority badge label from API, bilingual and reactive:
  /// EN → `priority.priority_type` / `priority_info.type` (Optional, Mandatory, Administrative)
  /// IT → `priority.name` / `priority_info.name` (Facoltativa, Obbligatoria, Condominiale)
  String getPriorityLabel() {
    try {
      final localeController = Get.find<LocaleController>();
      if (localeController.isEnglish) {
        final en = priorityNameEn?.trim();
        if (en != null && en.isNotEmpty) return en;
        final it = priorityNameIt?.trim();
        if (it != null && it.isNotEmpty) return it;
      } else {
        final it = priorityNameIt?.trim();
        if (it != null && it.isNotEmpty) return it;
        final en = priorityNameEn?.trim();
        if (en != null && en.isNotEmpty) return en;
      }
    } catch (_) {}

    return priorityRaw?.trim() ?? '';
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
  /// [fallbackResidenceId] is used when the payload omits `residence_id` (e.g. residence-wise list API).
  factory MaintenanceTask.fromJson(
    Map<String, dynamic> json, {
    int? fallbackResidenceId,
  }) {
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

    // Parse status from API `status` only (never maintenance_status).
    // Examples: "pending", "Due", "In Scadenza", "overdue", "completed"
    String? statusRawValue;
    String? statusNameEnValue;
    String? statusNameItValue;
    final statusField = json['status'];

    if (statusField is Map) {
      final map = Map<String, dynamic>.from(statusField);
      statusNameItValue = (map['name_it'] ?? map['name'])?.toString().trim();
      statusNameEnValue =
          (map['name_en'] ?? map['type'] ?? map['status'])?.toString().trim();
      statusRawValue = statusNameItValue?.isNotEmpty == true
          ? statusNameItValue
          : statusNameEnValue;
    } else if (statusField != null && statusField is! bool) {
      final text = statusField.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        statusRawValue = text;
        final lower = text.toLowerCase();

        // Combined forms e.g. "In Scadenza( Due)" / "Due (In Scadenza)"
        final parenMatch = RegExp(
          r'^\s*(.+?)\s*[\(\[]\s*(.+?)\s*[\)\]]\s*$',
        ).firstMatch(text);
        if (parenMatch != null) {
          final first = parenMatch.group(1)!.trim();
          final second = parenMatch.group(2)!.trim();
          final firstLower = first.toLowerCase();
          final secondLower = second.toLowerCase();
          if (firstLower.contains('scadenza') || secondLower == 'due') {
            statusNameItValue = firstLower.contains('scadenza') ? first : second;
            statusNameEnValue = secondLower == 'due' ? second : first;
          } else if (firstLower == 'due' || secondLower.contains('scadenza')) {
            statusNameEnValue = firstLower == 'due' ? first : second;
            statusNameItValue =
                secondLower.contains('scadenza') ? second : first;
          }
        }

        // Assign bilingual labels for known Due / In Scadenza values
        if (statusNameEnValue == null && statusNameItValue == null) {
          if (lower == 'due' ||
              lower == 'in scadenza' ||
              lower == 'in_scadenza' ||
              lower.contains('scadenza')) {
            statusNameEnValue = 'Due';
            statusNameItValue = 'In Scadenza';
          } else if (lower == 'pending' ||
              lower == 'in attesa' ||
              lower == 'in_attesa') {
            statusNameEnValue = 'Pending';
            statusNameItValue = 'In Attesa';
          } else if (lower == 'in progress' ||
              lower == 'in_progress' ||
              lower == 'in corso' ||
              lower == 'in_corso') {
            statusNameEnValue = 'In Progress';
            statusNameItValue = 'In Corso';
          } else if (lower == 'completed' ||
              lower == 'done' ||
              lower == 'completato' ||
              lower == 'completata') {
            statusNameEnValue = 'Completed';
            statusNameItValue = 'Completato';
          } else if (lower == 'overdue' ||
              lower == 'scaduto' ||
              lower == 'scaduta') {
            statusNameEnValue = 'Overdue';
            statusNameItValue = 'Scaduto';
          } else {
            // Unknown API value — show exactly what API returned
            statusNameEnValue = text;
            statusNameItValue = text;
          }
        }
      }
    }

    final statusString = (statusRawValue ?? '')
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    MaintenanceStatus status;
    if (statusString.isEmpty) {
      status = MaintenanceStatus.pending;
    } else if (statusString == 'pending' ||
        statusString == 'in_attesa' ||
        statusString == 'attesa') {
      status = MaintenanceStatus.pending;
    } else if (statusString == 'in_progress' ||
        statusString == 'inprogress' ||
        statusString == 'in_corso' ||
        statusString.contains('progress') ||
        (statusString.contains('corso') && !statusString.contains('scadenza'))) {
      status = MaintenanceStatus.inProgress;
    } else if (statusString == 'completed' ||
        statusString == 'done' ||
        statusString == 'completato' ||
        statusString == 'completata' ||
        statusString.contains('complet')) {
      status = MaintenanceStatus.completed;
    } else if (statusString == 'due' ||
        statusString == 'in_scadenza' ||
        statusString == 'scadenza' ||
        statusString.contains('in_scadenza') ||
        statusString.contains('scadenza')) {
      // "Due" / "In Scadenza" — must be checked before overdue/scaduto
      status = MaintenanceStatus.due;
    } else if (statusString == 'overdue' ||
        statusString == 'scaduto' ||
        statusString == 'scaduta' ||
        statusString.contains('overdue') ||
        statusString.contains('scadut')) {
      status = MaintenanceStatus.overdue;
    } else {
      // Keep unknown API status displayable via statusRaw; default enum for colors
      status = MaintenanceStatus.pending;
    }

    // Parse priority from API.
    // Live API shape:
    //   priority: { id, name: "Facoltativa", priority_type: "Optional" }
    //   priority_info: { name: "Facoltativa", type: "Optional" }
    // IT label = name, EN label = priority_type / type
    MaintenancePriority priority = MaintenancePriority.personal; // Default fallback
    String? priorityRawValue; // Store raw value from API for direct display
    String? priorityNameEnValue;
    String? priorityNameItValue;
    
    // Prefer nested objects that carry bilingual labels.
    Map<String, dynamic>? priorityMap;
    if (json['priority'] is Map) {
      priorityMap = Map<String, dynamic>.from(json['priority'] as Map);
    } else if (json['maintenance_priority'] is Map) {
      priorityMap = Map<String, dynamic>.from(json['maintenance_priority'] as Map);
    } else if (json['priority_info'] is Map) {
      priorityMap = Map<String, dynamic>.from(json['priority_info'] as Map);
    }

    if (priorityMap != null) {
      priorityNameItValue = priorityMap['name']?.toString().trim();
      priorityNameEnValue = (priorityMap['priority_type'] ??
              priorityMap['type'] ??
              priorityMap['name_en'])
          ?.toString()
          .trim();

      // Keep Italian name as raw fallback for older UI paths / colors.
      if (priorityNameItValue != null && priorityNameItValue.isNotEmpty) {
        priorityRawValue = priorityNameItValue;
      } else if (priorityNameEnValue != null && priorityNameEnValue.isNotEmpty) {
        priorityRawValue = priorityNameEnValue;
      }
    }

    dynamic priorityValue = priorityMap ??
        json['maintenance_priority'] ??
        json['priority'] ??
        json['priority_info'] ??
        json['priority_id'] ??
        json['maintenance_priority_id'] ??
        json['priorityId'] ??
        json['maintenancePriority'] ??
        json['maintenancePriorityId'] ??
        json['priority_name'] ??
        json['priorityName'] ??
        json['priority_level'] ??
        json['priorityLevel'];
    
    // DEBUG: Log priority data from API
    print('🔍 [MaintenanceTask] Priority field check for task ID: ${json['id']}');
    print('🔍 [MaintenanceTask] priorityValue found: $priorityValue (type: ${priorityValue != null ? priorityValue.runtimeType : 'null'})');
    print('🔍 [MaintenanceTask] priority IT="$priorityNameItValue" EN="$priorityNameEnValue"');
    
    if (priorityValue != null) {
      String priorityStr = '';
      
      // Handle different data types
      if (priorityValue is Map) {
        // Nested object: prefer Italian name for enum, English type already captured above
        final priorityObj = Map<String, dynamic>.from(priorityValue);
        priorityNameItValue ??= priorityObj['name']?.toString().trim();
        priorityNameEnValue ??= (priorityObj['priority_type'] ??
                priorityObj['type'] ??
                priorityObj['name_en'])
            ?.toString()
            .trim();

        final extractedValue = priorityObj['name'] ??
            priorityObj['priority_type'] ??
            priorityObj['type'] ??
            priorityObj['priority'] ??
            priorityObj['value'] ??
            priorityObj['name_en'] ??
            '';
        priorityStr = extractedValue.toString().toUpperCase().trim();
        // Store original extracted value (preserve full string for display)
        priorityRawValue ??= extractedValue.toString().trim();
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
      
      // Map priority string to enum — also check English type + Italian name
      final enumSource = [
        priorityStr,
        priorityNameItValue?.toUpperCase() ?? '',
        priorityNameEnValue?.toUpperCase() ?? '',
        priorityRawValue?.toUpperCase() ?? '',
      ].join(' ');

      if (enumSource.contains('FACOLTATIV') ||
          enumSource.contains('OPTIONAL') ||
          enumSource.contains('N1')) {
        priority = MaintenancePriority.facoltative;
        if (priorityRawValue == null) priorityRawValue = 'Facoltativa';
      } else if (enumSource.contains('OBBLIGATOR') ||
          enumSource.contains('MANDATORY') ||
          enumSource.contains('N2')) {
        priority = MaintenancePriority.obbligatorie;
        if (priorityRawValue == null) priorityRawValue = 'Obbligatoria';
      } else if (enumSource.contains('CONDOMINIAL') ||
          enumSource.contains('ADMINISTRATIVE') ||
          enumSource.contains('N3')) {
        priority = MaintenancePriority.condominiali;
        if (priorityRawValue == null) priorityRawValue = 'Condominiale';
      } else if (enumSource.contains('PERSONAL') ||
          enumSource.contains('PERSONALE')) {
        priority = MaintenancePriority.personal;
      } else {
        // Fall back to exact switch for legacy N1/N2/N3 values
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
          default:
            priority = MaintenancePriority.personal;
        }
      }
      
      // DEBUG: Log parsed priority
      print('🔍 [MaintenanceTask] Parsed priority: enum=$priority, raw=$priorityRawValue, en=$priorityNameEnValue, it=$priorityNameItValue');
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

    // Format dates (due_date / last_maintenance_date from API)
    String dueDateStr = json['due_date']?.toString().trim() ?? '';
    if (dueDateStr.isEmpty || dueDateStr.toLowerCase() == 'null') {
      dueDateStr = '';
    }
    String? lastMaintenanceDateStr =
        json['last_maintenance_date']?.toString().trim();
    if (lastMaintenanceDateStr == null ||
        lastMaintenanceDateStr.isEmpty ||
        lastMaintenanceDateStr.toLowerCase() == 'null') {
      lastMaintenanceDateStr = null;
    }

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
    final residenceId = json['residence_id'] ??
        residenceObj?.id ??
        fallbackResidenceId ??
        0;
    final maintenanceItemId = json['maintenance_item_id'] ?? itemObj?.id;
    final maintenanceResidenceIdRaw = json['maintenance_residence_id'];
    final int? maintenanceResidenceId = maintenanceResidenceIdRaw == null
        ? null
        : int.tryParse(maintenanceResidenceIdRaw.toString());

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
      priorityNameEn: priorityNameEnValue,
      priorityNameIt: priorityNameItValue,
      status: status,
      statusRaw: statusRawValue,
      statusNameEn: statusNameEnValue,
      statusNameIt: statusNameItValue,
      frequency: frequencyStr,
      frequencyObj: frequencyObj, // Store raw object for reactive language updates
      nextDue: dueDateStr.isNotEmpty ? dueDateStr : null,
      lastCompleted: lastMaintenanceDateStr,
      maintenanceCategoryId: maintenanceCategoryId,
      maintenanceItemId: maintenanceItemId,
      maintenanceResidenceId: maintenanceResidenceId,
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
      name: json['company_name']?.toString() ??
          json['name']?.toString() ??
          '',
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



