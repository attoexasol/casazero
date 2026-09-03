// presentation/maintenance/controllers/maintenance_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For compute() and Uint8List
import 'package:dio/dio.dart' as dio;
import '../../../core/controllers/message_popup_controller.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/maintenance_task_model.dart';
import '../models/maintenance_category_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/localization/locale_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../../core/logging/diagnostic_logger.dart';
import '../../../data/models/user_model.dart';

class MaintenanceController extends GetxController {
  // API Service
  final ApiService _apiService = Get.find<ApiService>();

  // Reactive variables for tasks
  final RxList<MaintenanceTask> tasks =
      <MaintenanceTask>[].obs; // Unfiltered list
  final RxList<MaintenanceTask> filteredTasks =
      <MaintenanceTask>[].obs; // Filtered list
  final RxBool isLoadingTasks = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  // Reactive variables for categories
  final RxList<MaintenanceCategory> categories = <MaintenanceCategory>[].obs;
  final RxBool isLoadingCategories = false.obs;
  final RxString categoriesErrorMessage = ''.obs;
  final RxBool hasCategoriesError = false.obs;
  final Rxn<int> selectedCategoryId = Rxn<int>(); // null means "all"

  // Task counts per filter
  final RxInt totalTaskCount = 0.obs;
  final RxInt personalCount = 0.obs;
  final RxInt facoltativeCount = 0.obs;
  final RxInt obbligatorieCount = 0.obs;
  final RxInt condominialiCount = 0.obs;
  final RxInt pendingCount = 0.obs;
  final RxInt overdueCount = 0.obs;

  /// When set (e.g. from notification deep link), screen can focus this task id.
  final Rxn<String> pendingFocusTaskId = Rxn<String>();

  // Category task counts (dynamically calculated)
  final RxMap<int, int> categoryTaskCounts = <int, int>{}.obs;

  /// Pre-built filter chips — updated atomically so the bar renders all at once.
  final RxList<Map<String, dynamic>> filterItems = <Map<String, dynamic>>[].obs;

  // Expanded card state
  final Rxn<String> expandedCardId = Rxn<String>();

  // File attachment state (for creating maintenance task)
  final Rxn<File> selectedFile = Rxn<File>();
  final RxString selectedFileName = ''.obs;
  final RxString selectedFileSize = ''.obs;
  final RxBool isPickingFile = false.obs; // Prevent multiple simultaneous picks

  // Maximum file size: 10MB (to prevent memory issues)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  @override
  void onInit() {
    super.onInit();
    // Initialize filteredTasks with empty list (will be updated when tasks load)
    filteredTasks.value = [];
    selectedCategoryId.value = null; // Default to "All"
    // Initialize file state
    selectedFile.value = null;
    selectedFileName.value = '';
    selectedFileSize.value = '';

    // Handle deep-link task focus
    ever(pendingFocusTaskId, (String? taskId) {
      if (taskId != null && taskId.isNotEmpty) {
        expandedCardId.value = taskId;
        selectedCategoryId.value = null;
        _applyFilter();
      }
    });
    if (pendingFocusTaskId.value != null &&
        pendingFocusTaskId.value!.isNotEmpty) {
      expandedCardId.value = pendingFocusTaskId.value;
      selectedCategoryId.value = null;
    }

    fetchMaintenanceCategories();
    _bindResidenceAndFetchTasks();
  }

  /// Refetch tasks when the selected residence changes (and on first load if already set).
  void _bindResidenceAndFetchTasks() {
    try {
      final home = Get.find<HomeController>();
      ever(home.selectedResidence, (dynamic _) {
        if (home.selectedResidence.value != null) {
          fetchMaintenanceTasks();
        } else {
          tasks.clear();
          filteredTasks.clear();
          totalTaskCount.value = 0;
          hasError.value = false;
          errorMessage.value = '';
          _updateFilterCounts([]);
          _updateCategoryTaskCounts();
          _applyFilter();
        }
      });
      if (home.selectedResidence.value != null) {
        fetchMaintenanceTasks();
      }
    } catch (e) {
      DiagnosticLogger.instance.warning(
        '⚠️ [MaintenanceController] HomeController unavailable, skipping residence-wise bind: $e',
      );
    }
  }

  /// Fetch maintenance tasks from API
  /// POST /residence_wise/maintenance — body: { "residence_id": `<id>` }
  /// Authorization header is automatically added by ApiService interceptor
  Future<void> fetchMaintenanceTasks() async {
    try {
      isLoadingTasks.value = true;
      errorMessage.value = '';
      hasError.value = false;

      int? residenceId;
      try {
        final home = Get.find<HomeController>();
        residenceId = UserModel.parseResidenceIdAsInt(home.selectedResidence.value?.id) ??
            UserModel.parseResidenceIdAsInt(home.residenceData.value?['id']) ??
            UserModel.parseResidenceIdAsInt(home.currentUser.value?.residenceId);
      } catch (_) {}

      residenceId = UserModel.parseResidenceIdAsInt(residenceId);

      if (residenceId == null || residenceId <= 0) {
        DiagnosticLogger.instance.warning(
          '⚠️ [MaintenanceController] No residence selected; skip maintenance list fetch',
        );
        tasks.clear();
        filteredTasks.clear();
        totalTaskCount.value = 0;
        _updateFilterCounts([]);
        _updateCategoryTaskCounts();
        _applyFilter();
        hasError.value = true;
        errorMessage.value = 'please_select_residence'.tr;
        return;
      }

      DiagnosticLogger.instance.info(
        '📡 [MaintenanceController] Fetching maintenance tasks from API...',
      );
      DiagnosticLogger.instance.debug(
        '🔗 [MaintenanceController] Endpoint: ${ApiConstants.POST_RESIDENCE_WISE_MAINTENANCE} residence_id=$residenceId',
      );
      DiagnosticLogger.instance.debug(
        '🔑 [MaintenanceController] Authorization: Bearer token (handled by ApiService)',
      );

      final response = await _apiService.post(
        ApiConstants.POST_RESIDENCE_WISE_MAINTENANCE,
        data: {'residence_id': residenceId},
      );

      // Print full API response for debugging
      DiagnosticLogger.instance.debug('');
      DiagnosticLogger.instance.debug(
        '═══════════════════════════════════════════════════════════════════════════════',
      );
      DiagnosticLogger.instance.debug(
        '📥 [MaintenanceController] RESIDENCE_WISE_MAINTENANCE API RESPONSE',
      );
      DiagnosticLogger.instance.debug(
        '═══════════════════════════════════════════════════════════════════════════════',
      );
      DiagnosticLogger.instance.debug('📥 [MaintenanceController] Status Code: ${response.statusCode}');
      DiagnosticLogger.instance.debug('📥 [MaintenanceController] Response Headers: ${response.headers}');
      DiagnosticLogger.instance.debug('');
      DiagnosticLogger.instance.debug('📥 [MaintenanceController] FULL RESPONSE DATA:');
      DiagnosticLogger.instance.debug(
        '───────────────────────────────────────────────────────────────────────────────',
      );
      // Print the full response data in a readable format
      try {
        // Convert to JSON string for better readability
        final jsonString = response.data.toString();
        DiagnosticLogger.instance.debug('📥 [MaintenanceController] $jsonString');
      } catch (e) {
        DiagnosticLogger.instance.debug('📥 [MaintenanceController] ${response.data}');
      }
      DiagnosticLogger.instance.debug(
        '───────────────────────────────────────────────────────────────────────────────',
      );
      DiagnosticLogger.instance.debug(
        '═══════════════════════════════════════════════════════════════════════════════',
      );
      DiagnosticLogger.instance.debug('');

      final okStatus = response.statusCode == 200 || response.statusCode == 201;
      // Check response status
      if (okStatus && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        // Print parsed response structure
        DiagnosticLogger.instance.debug('📋 [MaintenanceController] Parsed Response Structure:');
        DiagnosticLogger.instance.debug('📋 [MaintenanceController] - status: ${responseData['status']}');
        DiagnosticLogger.instance.debug(
          '📋 [MaintenanceController] - message: ${responseData['message']}',
        );
        DiagnosticLogger.instance.debug(
          '📋 [MaintenanceController] - data type: ${responseData['data']?.runtimeType}',
        );
        if (responseData['data'] is List) {
          DiagnosticLogger.instance.debug(
            '📋 [MaintenanceController] - data length: ${(responseData['data'] as List).length}',
          );
        }

        if (responseData['status'] == true && responseData['data'] != null) {
          final List<dynamic> dataList = responseData['data'] is List
              ? responseData['data']
              : [];

          // Parse tasks from API response with nested objects
          final List<MaintenanceTask> fetchedTasks = dataList
              .map((item) {
                try {
                  // DEBUG: Log full task JSON to find priority field
                  final taskMap = item as Map<String, dynamic>;
                  DiagnosticLogger.instance.debug(
                    '🔍 [MaintenanceController] Full task JSON for ID ${taskMap['id']}:',
                  );
                  DiagnosticLogger.instance.debug('   All keys: ${taskMap.keys.toList()}');
                  // Log the entire task structure (first task only to avoid spam)
                  if (dataList.indexOf(item) == 0) {
                    DiagnosticLogger.instance.debug('   Full task JSON: $taskMap');
                  }
                  return MaintenanceTask.fromJson(
                    taskMap,
                    fallbackResidenceId: residenceId,
                  );
                } catch (e) {
                  DiagnosticLogger.instance.error('⚠️ [MaintenanceController] Error parsing task: $e');
                  DiagnosticLogger.instance.warning('⚠️ [MaintenanceController] Task data: $item');
                  return null;
                }
              })
              .whereType<MaintenanceTask>() // Filter out null values
              .toList();

          tasks.value = fetchedTasks;
          totalTaskCount.value = fetchedTasks.length;
          _updateFilterCounts(fetchedTasks);
          _updateCategoryTaskCounts(); // Update category counts when tasks are loaded
          _applyFilter(); // Apply current filter to update filteredTasks
          if (pendingFocusTaskId.value != null &&
              pendingFocusTaskId.value!.isNotEmpty) {
            expandedCardId.value = pendingFocusTaskId.value;
          }

          DiagnosticLogger.instance.info('');
          DiagnosticLogger.instance.info(
            '✅ [MaintenanceController] Successfully parsed ${tasks.length} maintenance tasks from API',
          );
          DiagnosticLogger.instance.info(
            '✅ [MaintenanceController] Total task count: ${totalTaskCount.value}',
          );
          DiagnosticLogger.instance.info(
            '✅ [MaintenanceController] Filtered task count: ${filteredTasks.length}',
          );
          DiagnosticLogger.instance.warning('');
        } else {
          // API returned error or empty data
          final message =
              responseData['message']?.toString() ??
              'Failed to fetch maintenance tasks';
          throw Exception(message);
        }
      } else {
        throw Exception('Invalid response status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      DiagnosticLogger.instance.error('❌ [MaintenanceController] Error in fetchMaintenanceTasks: $e');
      DiagnosticLogger.instance.error('❌ [MaintenanceController] Stack trace: $stackTrace');
      errorMessage.value =
          'An error occurred while fetching tasks: ${e.toString()}';
      hasError.value = true;
      tasks.clear();
      filteredTasks.clear();
    } finally {
      isLoadingTasks.value = false;
    }
  }

  /// Create a new maintenance task via API
  /// Returns true on success, false on failure
  Future<bool> createMaintenanceTask({
    required String title,
    required int categoryId,
    required String frequency,
    required String dueDate, // Format: "YYYY-MM-DD"
    String? notes,
    String? lastMaintenanceDate, // Format: "YYYY-MM-DD", optional
    int? maintenanceItemId, // Optional, defaults to 1 if not provided
    required int residenceId,
  }) async {
    try {
      isLoadingTasks.value = true;

      final cleanResidenceId =
          UserModel.parseResidenceIdAsInt(residenceId) ?? residenceId;

      // Validate required fields
      if (title.isEmpty) {
        throw Exception('Title is required');
      }
      if (dueDate.isEmpty) {
        throw Exception('Due date is required');
      }
      if (cleanResidenceId <= 0) {
        throw Exception('Residence ID is required');
      }

      // Build request body
      final requestBody = <String, dynamic>{
        'maintenance_title': title,
        'maintenance_frequency': frequency,
        'maintenance_status': 'pending',
        'due_date': dueDate,
        'maintenance_category_id': categoryId,
        'maintenance_item_id': maintenanceItemId ?? 1,
        'residence_id': cleanResidenceId,
      };

      // Add optional fields
      if (notes != null && notes.isNotEmpty) {
        requestBody['maintenance_note'] = notes;
      }
      if (lastMaintenanceDate != null && lastMaintenanceDate.isNotEmpty) {
        requestBody['last_maintenance_date'] = lastMaintenanceDate;
      }

      DiagnosticLogger.instance.info('📡 [MaintenanceController] Creating maintenance task...');
      DiagnosticLogger.instance.debug('📦 [MaintenanceController] Request body: $requestBody');

      // Call API
      final response = await _apiService.post(
        ApiConstants.CREATE_MAINTENANCE_TASK,
        data: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['status'] == true) {
          DiagnosticLogger.instance.info(
            '✅ [MaintenanceController] Maintenance task created successfully',
          );

          // Refresh maintenance list to include the new task
          await fetchMaintenanceTasks();

          MessagePopupController.showSuccess(
            messageKey: 'maintenance_created_successfully',
            titleKey: 'success',
          );

          return true;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to create maintenance',
          );
        }
      } else {
        throw Exception('Invalid response status: ${response.statusCode}');
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [MaintenanceController] Error creating maintenance task: $e');

      MessagePopupController.showError(
        messageKey: 'failed_to_create_maintenance',
        titleKey: 'error',
      );

      return false;
    } finally {
      isLoadingTasks.value = false;
    }
  }

  /// Toggle expanded state for a task card
  void toggleExpanded(String? taskId) {
    if (expandedCardId.value == taskId) {
      expandedCardId.value = null;
    } else {
      expandedCardId.value = taskId;
    }
  }

  /// Mark task as completed
  /// Toggle task completion status
  /// If task is completed, reverts via undoMaintenanceStatus
  /// If task is not completed, marks completed via changeMaintenanceStatus
  Future<void> markTaskCompleted(String taskId) async {
    try {
      isLoadingTasks.value = true;

      // Find the task to check current status
      MaintenanceTask? task;
      try {
        task = tasks.firstWhere((t) => t.id == taskId);
      } catch (e) {
        task = null;
      }

      final isCompleted = task?.status == MaintenanceStatus.completed;
      final endpoint = isCompleted
          ? ApiConstants.UNDO_MAINTENANCE_STATUS
          : ApiConstants.CHANGE_MAINTENANCE_STATUS;
      final action = isCompleted ? 'reverting' : 'marking as completed';

      final storageService = Get.find<StorageService>();
      final apiToken = storageService.getAccessToken();
      if (apiToken == null || apiToken.isEmpty) {
        throw Exception('User API token not found in local storage');
      }

      // Endpoint validates against maintenance_residence table — use
      // maintenance_residence_id, not the maintenance task id.
      final maintenanceResidenceId = task?.maintenanceResidenceId;
      if (maintenanceResidenceId == null || maintenanceResidenceId <= 0) {
        throw Exception('Invalid maintenance_residence_id for task: $taskId');
      }

      // Mark complete: { api_token, id: maintenance_residence_id, status: "completato" }
      // Undo:         { api_token, id: maintenance_residence_id }
      final requestBody = <String, dynamic>{
        'api_token': apiToken,
        'id': maintenanceResidenceId,
        if (!isCompleted) 'status': 'completato',
      };

      DiagnosticLogger.instance.debug('🔄 [MaintenanceController] $action task: $taskId');
      DiagnosticLogger.instance.debug(
        '🆔 [MaintenanceController] maintenance_residence_id: $maintenanceResidenceId',
      );
      DiagnosticLogger.instance.debug('🔗 [MaintenanceController] Endpoint: $endpoint');
      DiagnosticLogger.instance.debug('📤 [MaintenanceController] Request body: $requestBody');

      final response = await _apiService.post(endpoint, data: requestBody);

      DiagnosticLogger.instance.debug(
        '📥 [MaintenanceController] Response status: ${response.statusCode}',
      );
      DiagnosticLogger.instance.debug('📥 [MaintenanceController] Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['status'] == true) {
          DiagnosticLogger.instance.info('✅ [MaintenanceController] Task status updated successfully');

          // Refresh maintenance list to get updated task with new status
          await fetchMaintenanceTasks();

          MessagePopupController.showSuccess(
            messageKey: isCompleted
                ? 'task_reverted_successfully'
                : 'task_marked_completed_successfully',
            titleKey: 'success',
          );
        } else {
          throw Exception(
            responseData['message'] ??
                (isCompleted
                    ? 'Failed to revert task status'
                    : 'Failed to mark task as completed'),
          );
        }
      } else {
        throw Exception('Invalid response status: ${response.statusCode}');
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [MaintenanceController] Error updating task status: $e');
      MessagePopupController.showError(
        messageKey: 'failed_to_update_task_status',
        titleKey: 'error',
      );
    } finally {
      isLoadingTasks.value = false;
    }
  }

  /// Schedule a visit for a task
  /// Opens date picker and updates task due_date
  Future<void> scheduleVisit(String taskId) async {
    try {
      // Find the task to get current due date
      MaintenanceTask? task;
      try {
        task = tasks.firstWhere((t) => t.id == taskId);
      } catch (e) {
        task = null;
      }

      // Parse existing due_date if available
      DateTime? initialDate;
      if (task != null && task.dueDate.isNotEmpty) {
        try {
          // Parse date from format "yyyy-MM-dd HH:mm:ss" or "yyyy-MM-dd"
          if (task.dueDate.contains(' ')) {
            initialDate = DateTime.parse(task.dueDate.split(' ')[0]);
          } else {
            initialDate = DateTime.parse(task.dueDate);
          }
        } catch (e) {
          DiagnosticLogger.instance.warning(
            '⚠️ [MaintenanceController] Could not parse existing due_date: ${task.dueDate}',
          );
          initialDate = DateTime.now();
        }
      }

      initialDate ??= DateTime.now();

      // Show date picker
      final DateTime? selectedDate = await showDatePicker(
        context: Get.context!,
        initialDate: initialDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(
          const Duration(days: 365 * 5),
        ), // 5 years from now
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.brandSage500,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (selectedDate == null) {
        // User cancelled
        return;
      }

      // Format date as "yyyy-MM-dd" to match API format (same as CREATE endpoint)
      final formattedDate =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

      // Update task via API
      await _updateTaskSchedule(taskId, formattedDate);
    } catch (e) {
      DiagnosticLogger.instance.error('❌ Error scheduling visit: $e');
      MessagePopupController.showError(
        messageKey: 'failed_to_schedule_visit',
        titleKey: 'error',
      );
    }
  }

  /// Update task schedule (due_date) via API
  Future<void> _updateTaskSchedule(String taskId, String dueDate) async {
    try {
      isLoadingTasks.value = true;

      DiagnosticLogger.instance.debug(
        '📅 [MaintenanceController] Updating task schedule: $taskId with date: $dueDate',
      );

      // Find task to get all required fields
      MaintenanceTask? task;
      try {
        task = tasks.firstWhere((t) => t.id == taskId);
      } catch (e) {
        task = null;
      }
      if (task == null) {
        throw Exception('Task not found');
      }

      // Build request body - include all required fields from create pattern
      // Map status enum to API format (snake_case for in_progress)
      String statusString;
      switch (task.status) {
        case MaintenanceStatus.pending:
          statusString = 'pending';
          break;
        case MaintenanceStatus.inProgress:
          statusString = 'in_progress';
          break;
        case MaintenanceStatus.completed:
          statusString = 'completed';
          break;
        case MaintenanceStatus.overdue:
          statusString = 'overdue';
          break;
        case MaintenanceStatus.due:
          statusString = 'due';
          break;
      }

      final cleanResidenceId =
          UserModel.parseResidenceIdAsInt(task.residenceId) ?? task.residenceId;

      final requestBody = <String, dynamic>{
        'maintenance_title': task.title,
        'maintenance_frequency': task.frequency,
        'maintenance_status': statusString,
        'due_date': dueDate,
        'maintenance_category_id': task.maintenanceCategoryId,
        'maintenance_item_id': task.maintenanceItemId ?? 1,
        'residence_id': cleanResidenceId,
      };

      // Add optional fields
      if (task.maintenanceNote != null && task.maintenanceNote!.isNotEmpty) {
        requestBody['maintenance_note'] = task.maintenanceNote;
      }
      if (task.lastMaintenanceDate != null &&
          task.lastMaintenanceDate!.isNotEmpty) {
        requestBody['last_maintenance_date'] = task.lastMaintenanceDate;
      }

      // Try PUT to /maintenance/update/{id} or /maintenance/{id}
      // If that doesn't work, try PUT to /maintenance/store/{id}
      dio.Response? response;
      String? errorMessage;

      try {
        // Try RESTful PUT to /maintenance/{id}
        DiagnosticLogger.instance.debug('🔄 [MaintenanceController] Trying PUT /maintenance/$taskId');
        response = await _apiService.put(
          '/maintenance/$taskId',
          data: requestBody,
        );
        DiagnosticLogger.instance.warning('✅ [MaintenanceController] PUT /maintenance/$taskId succeeded');
      } catch (e) {
        DiagnosticLogger.instance.warning('⚠️ [MaintenanceController] PUT /maintenance/{id} failed: $e');
        DiagnosticLogger.instance.warning('⚠️ [MaintenanceController] Trying alternative endpoint...');
        try {
          // Try PUT to /maintenance/update/{id}
          DiagnosticLogger.instance.debug(
            '🔄 [MaintenanceController] Trying PUT /maintenance/update/$taskId',
          );
          response = await _apiService.put(
            '/maintenance/update/$taskId',
            data: requestBody,
          );
          DiagnosticLogger.instance.warning(
            '✅ [MaintenanceController] PUT /maintenance/update/$taskId succeeded',
          );
        } catch (e2) {
          DiagnosticLogger.instance.warning(
            '⚠️ [MaintenanceController] PUT /maintenance/update/{id} failed: $e2',
          );
          DiagnosticLogger.instance.warning('⚠️ [MaintenanceController] Trying POST as last resort...');
          try {
            // Try POST to /maintenance/update with ID (Laravel-style update)
            requestBody['id'] = int.parse(taskId);
            DiagnosticLogger.instance.debug(
              '🔄 [MaintenanceController] Trying POST /maintenance/update with id: $taskId',
            );
            response = await _apiService.post(
              '/maintenance/update',
              data: requestBody,
            );
            DiagnosticLogger.instance.error(
              '✅ [MaintenanceController] POST /maintenance/update succeeded',
            );
          } catch (e3) {
            DiagnosticLogger.instance.error(
              '❌ [MaintenanceController] POST /maintenance/update failed: $e3',
            );
            errorMessage =
                'Failed to update task. Please ensure the API endpoint is available.';
          }
        }
      }

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['status'] == true) {
          DiagnosticLogger.instance.info('✅ [MaintenanceController] Task schedule updated successfully');

          // Refresh maintenance list to get updated task
          await fetchMaintenanceTasks();

          MessagePopupController.showSuccess(
            messageKey: 'schedule_updated_successfully',
            titleKey: 'success',
          );
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to update schedule',
          );
        }
      } else if (errorMessage != null) {
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Invalid response status: ${response?.statusCode ?? 'unknown'}',
        );
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [MaintenanceController] Error updating task schedule: $e');
      MessagePopupController.showError(
        messageKey: 'failed_to_update_schedule',
        titleKey: 'error',
      );
      rethrow;
    } finally {
      isLoadingTasks.value = false;
    }
  }

  /// Delete a maintenance task
  /// Immediately updates UI after successful deletion
  Future<bool> deleteMaintenanceTask(String taskId) async {
    try {
      DiagnosticLogger.instance.debug('🗑️ [MaintenanceController] Deleting maintenance task: $taskId');

      // Call DELETE API endpoint
      final response = await _apiService.delete(
        '${ApiConstants.DELETE_MAINTENANCE_TASK}/$taskId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['status'] == true) {
          DiagnosticLogger.instance.info(
            '✅ [MaintenanceController] Delete success, updating UI immediately',
          );

          // OPTIMISTIC UPDATE: Remove from tasks list immediately
          tasks.removeWhere((task) => task.id == taskId);

          // Update filtered tasks
          _applyFilter();

          // Update counts
          totalTaskCount.value = tasks.length;
          _updateFilterCounts(tasks.toList());
          _updateCategoryTaskCounts();

          // Also refresh from API to ensure consistency
          await fetchMaintenanceTasks();

          MessagePopupController.showSuccess(
            messageKey: 'maintenance_deleted_successfully',
            titleKey: 'success',
          );

          return true;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to delete maintenance',
          );
        }
      } else {
        throw Exception('Invalid response status: ${response.statusCode}');
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [MaintenanceController] Error deleting maintenance task: $e');

      MessagePopupController.showError(
        messageKey: 'failed_to_delete_maintenance',
        titleKey: 'error',
      );

      return false;
    }
  }

  /// Fetch maintenance categories from API
  Future<void> fetchMaintenanceCategories() async {
    // Don't refetch if already loaded
    if (categories.isNotEmpty && !hasCategoriesError.value) {
      _syncFilterItems();
      return;
    }

    try {
      isLoadingCategories.value = true;
      categoriesErrorMessage.value = '';
      hasCategoriesError.value = false;

      DiagnosticLogger.instance.info('📡 [MaintenanceController] Fetching maintenance categories...');
      DiagnosticLogger.instance.debug(
        '🔗 [MaintenanceController] Endpoint: ${ApiConstants.GET_MAINTENANCE_CATEGORIES}',
      );
      final response = await _apiService.get(
        ApiConstants.GET_MAINTENANCE_CATEGORIES,
      );

      // Print full API response for debugging
      DiagnosticLogger.instance.debug('');
      DiagnosticLogger.instance.debug(
        '═══════════════════════════════════════════════════════════════════════════════',
      );
      DiagnosticLogger.instance.debug(
        '📥 [MaintenanceController] GET_MAINTENANCE_CATEGORIES API RESPONSE',
      );
      DiagnosticLogger.instance.debug(
        '═══════════════════════════════════════════════════════════════════════════════',
      );
      DiagnosticLogger.instance.debug('📥 [MaintenanceController] Status Code: ${response.statusCode}');
      DiagnosticLogger.instance.debug('📥 [MaintenanceController] Response Headers: ${response.headers}');
      DiagnosticLogger.instance.debug('');
      DiagnosticLogger.instance.debug('📥 [MaintenanceController] FULL RESPONSE DATA:');
      DiagnosticLogger.instance.debug(
        '───────────────────────────────────────────────────────────────────────────────',
      );
      // Print the full response data in a readable format
      try {
        // Convert to JSON string for better readability
        final jsonString = response.data.toString();
        DiagnosticLogger.instance.debug('📥 [MaintenanceController] $jsonString');
      } catch (e) {
        DiagnosticLogger.instance.debug('📥 [MaintenanceController] ${response.data}');
      }
      DiagnosticLogger.instance.debug(
        '───────────────────────────────────────────────────────────────────────────────',
      );
      DiagnosticLogger.instance.debug(
        '═══════════════════════════════════════════════════════════════════════════════',
      );
      DiagnosticLogger.instance.debug('');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        // Print parsed response structure
        DiagnosticLogger.instance.debug('📋 [MaintenanceController] Parsed Response Structure:');
        DiagnosticLogger.instance.debug('📋 [MaintenanceController] - status: ${responseData['status']}');
        DiagnosticLogger.instance.debug(
          '📋 [MaintenanceController] - message: ${responseData['message']}',
        );
        DiagnosticLogger.instance.debug(
          '📋 [MaintenanceController] - data type: ${responseData['data']?.runtimeType}',
        );
        if (responseData['data'] is List) {
          DiagnosticLogger.instance.debug(
            '📋 [MaintenanceController] - data length: ${(responseData['data'] as List).length}',
          );
        }

        if (responseData['status'] == true && responseData['data'] != null) {
          final List<dynamic> categoriesData =
              responseData['data'] as List<dynamic>;
          final List<MaintenanceCategory> fetchedCategories = categoriesData
              .map((json) {
                // Debug: Log raw category data to verify API response structure
                DiagnosticLogger.instance.debug('🔍 [MaintenanceController] Raw category JSON: $json');
                return MaintenanceCategory.fromJson(
                  json as Map<String, dynamic>,
                );
              })
              .toList();

          categories.value = fetchedCategories;

          // Debug: Log parsed categories to verify name_en and name_it fields are populated
          DiagnosticLogger.instance.debug('');
          DiagnosticLogger.instance.debug('📋 [MaintenanceController] Parsed Categories:');
          for (final category in fetchedCategories) {
            DiagnosticLogger.instance.debug(
              '   📁 ID: ${category.id} | Name (IT): "${category.name}" | Name (EN): "${category.nameEn}" | Description: "${category.description}"',
            );
          }
          DiagnosticLogger.instance.info('');

          _updateCategoryTaskCounts();
          _applyFilter(); // Reapply filter in case category selection needs updating

          DiagnosticLogger.instance.info(
            '✅ [MaintenanceController] Successfully loaded ${categories.length} maintenance categories',
          );
          DiagnosticLogger.instance.error('');
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch categories',
          );
        }
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [MaintenanceController] Error fetching categories: $e');
      _syncFilterItems();
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// Update category task counts based on loaded tasks
  void _updateCategoryTaskCounts() {
    categoryTaskCounts.clear();

    for (final category in categories) {
      // Count tasks that match this category by category.id (from nested category object)
      final count = tasks
          .where((task) => task.categoryObj?.id == category.id)
          .length;
      categoryTaskCounts[category.id] = count;
    }

    // Trigger reactive update for filter list rebuild
    categoryTaskCounts.refresh();
    _syncFilterItems();
  }

  /// Set selected category ID for filtering
  void setSelectedCategoryId(int? categoryId) {
    selectedCategoryId.value = categoryId;
    _applyFilter(); // Apply filter when category changes
  }

  /// Apply filter based on selectedCategoryId
  void _applyFilter() {
    if (selectedCategoryId.value == null) {
      // "All" selected - show all tasks
      filteredTasks.value = tasks.toList();
    } else {
      // Category selected - filter by category.id (from nested category object)
      final categoryId = selectedCategoryId.value!;
      // Filter tasks by category.id (matching requirement: maintenance.category.id == selectedCategory.id)
      filteredTasks.value = tasks
          .where((task) => task.categoryObj?.id == categoryId)
          .toList();
    }
  }

  /// Rebuild filter list atomically: [All] + API categories.
  /// Called after categories or task counts change so chips appear together.
  void _syncFilterItems() {
    final filterList = <Map<String, dynamic>>[];

    String allLabel;
    bool useEnglish = true;
    try {
      final localeController = Get.find<LocaleController>();
      useEnglish = localeController.isEnglish;
      allLabel = 'allCategories'.tr;
    } catch (_) {
      allLabel = 'All';
    }

    filterList.add({
      'id': 'all',
      'label': allLabel,
      'count': totalTaskCount.value,
    });

    for (final category in categories) {
      final count = categoryTaskCounts[category.id] ?? 0;

      final String label;
      if (useEnglish) {
        label = category.nameEn.isNotEmpty
            ? category.nameEn
            : (category.name.isNotEmpty
                  ? category.name
                  : 'Category ${category.id}');
      } else {
        label = category.name.isNotEmpty
            ? category.name
            : (category.nameEn.isNotEmpty
                  ? category.nameEn
                  : 'Categoria ${category.id}');
      }

      filterList.add({
        'id': 'category_${category.id}',
        'categoryId': category.id,
        'label': label,
        'count': count,
      });
    }

    filterItems.assignAll(filterList);
  }

  /// Refresh all data (pull-to-refresh)
  Future<void> refreshData() async {
    await Future.wait([fetchMaintenanceCategories(), fetchMaintenanceTasks()]);
  }

  /// Pick a file for attachment (PDF, Images, DOC/DOCX)
  /// Returns true on success, false on failure or cancel
  /// Uses isolates for heavy file operations to prevent UI blocking
  Future<bool> pickFile() async {
    // Prevent multiple simultaneous file picks
    if (isPickingFile.value) {
      DiagnosticLogger.instance.warning('⚠️ [MaintenanceController] File picker already in progress');
      return false;
    }

    try {
      isPickingFile.value = true;
      DiagnosticLogger.instance.debug('📁 [MaintenanceController] Opening file picker...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );

      // User cancelled
      if (result == null || result.files.isEmpty) {
        DiagnosticLogger.instance.debug('📁 [MaintenanceController] File picker cancelled');
        return false;
      }

      final pickedFile = result.files.single;
      DiagnosticLogger.instance.debug('📁 [MaintenanceController] File selected: ${pickedFile.name}');

      // Check file size before processing (prevent memory issues and Android killing app)
      // This check happens BEFORE any heavy operations
      final fileSize = pickedFile.size;
      if (fileSize <= 0) {
        throw Exception('Invalid file size: $fileSize bytes');
      }
      if (fileSize > maxFileSizeBytes) {
        throw Exception(
          'File size (${_formatFileSize(fileSize)}) exceeds maximum allowed size (${_formatFileSize(maxFileSizeBytes)})',
        );
      }
      DiagnosticLogger.instance.debug(
        '📁 [MaintenanceController] File size: ${_formatFileSize(fileSize)}',
      );

      // Get app documents directory for permanent storage (lightweight operation)
      final appDocDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(
        '${appDocDir.path}/maintenance_attachments',
      );

      // Create directory if it doesn't exist (lightweight)
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      // Generate unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = pickedFile.name;
      final fileExtension = fileName.contains('.')
          ? fileName.split('.').last
          : 'file';
      final fileNameWithoutExt = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;
      final uniqueFileName = '${fileNameWithoutExt}_$timestamp.$fileExtension';
      final permanentFilePath = '${attachmentsDir.path}/$uniqueFileName';

      // Process file in isolate to prevent UI blocking
      // This moves heavy file operations off the main thread
      // Note: compute() requires a top-level function, so we use a lambda wrapper
      final fileProcessResult = await compute(
        _processFileInIsolate,
        _FileProcessParams(
          sourcePath: pickedFile.path,
          sourceBytes: pickedFile.bytes,
          destinationPath: permanentFilePath,
          fileName: fileName,
        ),
      );

      if (!fileProcessResult.success) {
        throw Exception(fileProcessResult.error ?? 'Failed to process file');
      }

      // Verify file exists (lightweight check)
      final permanentFile = File(permanentFilePath);
      if (!await permanentFile.exists()) {
        throw Exception('Failed to save file to permanent location');
      }

      // Update reactive state only after successful processing
      // Check if controller is still valid before updating (prevents updates after disposal)
      if (!isClosed) {
        // Use microtask to ensure UI updates happen after current frame
        // This prevents jank and ensures smooth UI updates
        await Future.microtask(() {
          if (!isClosed) {
            selectedFile.value = permanentFile;
            selectedFileName.value =
                fileName; // Keep original filename for display
            selectedFileSize.value = _formatFileSize(
              fileProcessResult.fileSize,
            );
          }
        });
      }

      DiagnosticLogger.instance.info(
        '✅ [MaintenanceController] File selected successfully: $fileName (${selectedFileSize.value})',
      );
      DiagnosticLogger.instance.error('📁 [MaintenanceController] File saved to: $permanentFilePath');
      return true;
    } catch (e, stackTrace) {
      DiagnosticLogger.instance.error('❌ [MaintenanceController] Error picking file: $e');
      DiagnosticLogger.instance.error('❌ [MaintenanceController] Stack trace: $stackTrace');

      // Only show popup if controller is still valid
      if (!isClosed) {
        MessagePopupController.showError(
          messageKey: 'failed_to_pick_file',
          titleKey: 'error',
        );
      }
      return false;
    } finally {
      // Always reset picking state, even on error
      if (!isClosed) {
        isPickingFile.value = false;
      }
    }
  }

  /// Remove selected file
  /// Cleans up file reference to prevent memory leaks
  void removeSelectedFile() {
    // Check if controller is still valid before updating (prevents updates after disposal)
    if (isClosed) return;

    // Clear file reference first to allow GC
    selectedFile.value = null;
    selectedFileName.value = '';
    selectedFileSize.value = '';

    DiagnosticLogger.instance.debug('🗑️ [MaintenanceController] File removed');
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Update filter counts based on loaded tasks
  void _updateFilterCounts(List<MaintenanceTask> tasks) {
    personalCount.value = tasks
        .where((t) => t.priority == MaintenancePriority.personal)
        .length;
    facoltativeCount.value = tasks
        .where((t) => t.priority == MaintenancePriority.facoltative)
        .length;
    obbligatorieCount.value = tasks
        .where((t) => t.priority == MaintenancePriority.obbligatorie)
        .length;
    condominialiCount.value = tasks
        .where((t) => t.priority == MaintenancePriority.condominiali)
        .length;
    pendingCount.value = tasks
        .where((t) => t.status == MaintenanceStatus.pending)
        .length;
    overdueCount.value = tasks
        .where((t) => t.status == MaintenanceStatus.overdue)
        .length;
  }
}

// ============================================================================
// ISOLATE FUNCTIONS FOR HEAVY FILE OPERATIONS
// ============================================================================

/// Parameters for file processing in isolate
/// Must be serializable (no File objects, only paths/bytes)
class _FileProcessParams {
  final String? sourcePath;
  final Uint8List? sourceBytes;
  final String destinationPath;
  final String fileName;

  _FileProcessParams({
    this.sourcePath,
    this.sourceBytes,
    required this.destinationPath,
    required this.fileName,
  });
}

/// Result of file processing in isolate
class _FileProcessResult {
  final bool success;
  final String? error;
  final int fileSize;

  _FileProcessResult({
    required this.success,
    this.error,
    required this.fileSize,
  });
}

/// Process file in isolate to prevent UI blocking
/// This function runs in a separate isolate, so it can't access controller state
/// It only performs file I/O operations
/// Must be top-level function for compute() to work
///
/// IMPORTANT: All parameters must be serializable for isolate communication
/// Uint8List is serializable, so this works correctly
Future<_FileProcessResult> _processFileInIsolate(
  _FileProcessParams params,
) async {
  try {
    Uint8List? fileBytes;

    // Read file bytes (heavy operation - done in isolate to prevent UI blocking)
    // This prevents Android from killing the app due to main thread blocking
    if (params.sourcePath != null && params.sourcePath!.isNotEmpty) {
      // Android/Desktop - read from path
      final sourceFile = File(params.sourcePath!);
      if (!await sourceFile.exists()) {
        return _FileProcessResult(
          success: false,
          error: 'Source file does not exist at path: ${params.sourcePath}',
          fileSize: 0,
        );
      }
      // Read file bytes (heavy operation moved to isolate)
      fileBytes = await sourceFile.readAsBytes();
    } else if (params.sourceBytes != null && params.sourceBytes!.isNotEmpty) {
      // iOS/Web - use bytes directly (already in memory)
      fileBytes = params.sourceBytes!;
    } else {
      return _FileProcessResult(
        success: false,
        error: 'File path and bytes are both null or empty',
        fileSize: 0,
      );
    }

    // Validate bytes were read successfully
    if (fileBytes.isEmpty) {
      return _FileProcessResult(
        success: false,
        error: 'Failed to read file bytes',
        fileSize: 0,
      );
    }

    // Write to permanent location (heavy operation - done in isolate)
    // This prevents blocking the main thread during file write
    final permanentFile = File(params.destinationPath);

    // Ensure parent directory exists
    final parentDir = permanentFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    // Write bytes to file
    await permanentFile.writeAsBytes(fileBytes);

    // Verify file exists and get size
    if (!await permanentFile.exists()) {
      return _FileProcessResult(
        success: false,
        error: 'Failed to save file to permanent location',
        fileSize: 0,
      );
    }

    // Get file size (lightweight operation)
    final fileSize = await permanentFile.length();

    return _FileProcessResult(success: true, fileSize: fileSize);
  } catch (e, stackTrace) {
    // Log error details for debugging
    DiagnosticLogger.instance.error('❌ [Isolate] Error processing file: $e');
    DiagnosticLogger.instance.error('❌ [Isolate] Stack trace: $stackTrace');
    return _FileProcessResult(
      success: false,
      error: 'File processing failed: ${e.toString()}',
      fileSize: 0,
    );
  }
}
