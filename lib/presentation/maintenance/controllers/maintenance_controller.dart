// presentation/maintenance/controllers/maintenance_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For compute()
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import '../models/maintenance_task_model.dart';
import '../models/maintenance_category_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../home/controllers/home_controller.dart';

class MaintenanceController extends GetxController {
  // API Service
  final ApiService _apiService = Get.find<ApiService>();

  // Reactive variables for tasks
  final RxList<MaintenanceTask> tasks = <MaintenanceTask>[].obs; // Unfiltered list
  final RxList<MaintenanceTask> filteredTasks = <MaintenanceTask>[].obs; // Filtered list
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

  // Category task counts (dynamically calculated)
  final RxMap<int, int> categoryTaskCounts = <int, int>{}.obs;

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
    fetchMaintenanceCategories();
    fetchMaintenanceTasks();
  }

  /// Fetch maintenance tasks from API
  /// GET /maintenance/list
  /// Authorization header is automatically added by ApiService interceptor
  Future<void> fetchMaintenanceTasks() async {
    try {
      isLoadingTasks.value = true;
      errorMessage.value = '';
      hasError.value = false;

      print('📡 [MaintenanceController] Fetching maintenance tasks from API...');
      print('🔗 [MaintenanceController] Endpoint: ${ApiConstants.GET_MAINTENANCE_TASKS}');
      print('🔑 [MaintenanceController] Authorization: Bearer token (handled by ApiService)');

      // Call GET API endpoint
      // Authorization header is automatically added by ApiService interceptor
      // See: ApiService.onRequest() interceptor adds 'Authorization: Bearer {token}'
      final response = await _apiService.get(
        ApiConstants.GET_MAINTENANCE_TASKS,
      );

      // Check response status
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        
        if (responseData['status'] == true && responseData['data'] != null) {
          final List<dynamic> dataList = responseData['data'] is List
              ? responseData['data']
              : [];

          // Parse tasks from API response with nested objects
          final List<MaintenanceTask> fetchedTasks = dataList
              .map((item) {
                try {
                  return MaintenanceTask.fromJson(item as Map<String, dynamic>);
                } catch (e) {
                  print('⚠️ [MaintenanceController] Error parsing task: $e');
                  print('⚠️ [MaintenanceController] Task data: $item');
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

          print('✅ [MaintenanceController] Loaded ${tasks.length} maintenance tasks from API');
        } else {
          // API returned error or empty data
          final message = responseData['message']?.toString() ?? 'Failed to fetch maintenance tasks';
          throw Exception(message);
        }
      } else {
        throw Exception('Invalid response status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [MaintenanceController] Error in fetchMaintenanceTasks: $e');
      print('❌ [MaintenanceController] Stack trace: $stackTrace');
      errorMessage.value = 'An error occurred while fetching tasks: ${e.toString()}';
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

      // Validate required fields
      if (title.isEmpty) {
        throw Exception('Title is required');
      }
      if (dueDate.isEmpty) {
        throw Exception('Due date is required');
      }
      if (residenceId <= 0) {
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
        'residence_id': residenceId,
      };

      // Add optional fields
      if (notes != null && notes.isNotEmpty) {
        requestBody['maintenance_note'] = notes;
      }
      if (lastMaintenanceDate != null && lastMaintenanceDate.isNotEmpty) {
        requestBody['last_maintenance_date'] = lastMaintenanceDate;
      }

      print('📡 [MaintenanceController] Creating maintenance task...');
      print('📦 [MaintenanceController] Request body: $requestBody');

      // Call API
      final response = await _apiService.post(
        ApiConstants.CREATE_MAINTENANCE_TASK,
        data: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;
        
        if (responseData['status'] == true) {
          print('✅ [MaintenanceController] Maintenance task created successfully');
          
          // Refresh maintenance list to include the new task
          await fetchMaintenanceTasks();
          
          // Show success snackbar (top positioned)
          Get.snackbar(
            'Success',
            responseData['message'] ?? 'Maintenance created successfully',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green[700],
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          
          return true;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to create maintenance');
        }
      } else {
        throw Exception('Invalid response status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [MaintenanceController] Error creating maintenance task: $e');
      
      // Show error snackbar (top positioned)
      String errorMessage = 'Failed to create maintenance';
      if (e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else if (e.toString().isNotEmpty) {
        errorMessage = e.toString();
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
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
  Future<void> markTaskCompleted(String taskId) async {
    try {
      // TODO: Replace with actual API call
      final taskIndex = tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        final task = tasks[taskIndex];
        // Update task status
        // Note: Since MaintenanceTask is immutable, we'd need to create a new instance
        // For now, just show a message
        Get.snackbar(
          'Success',
          'Task marked as completed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[700],
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        await fetchMaintenanceTasks(); // Refresh
      }
    } catch (e) {
      print('❌ Error marking task as completed: $e');
    }
  }

  /// Schedule a visit for a task
  Future<void> scheduleVisit(String taskId) async {
    try {
      // TODO: Implement scheduling logic
      Get.snackbar(
        'Info',
        'Schedule visit functionality coming soon',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue[700],
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ Error scheduling visit: $e');
    }
  }

  /// Fetch maintenance categories from API
  Future<void> fetchMaintenanceCategories() async {
    // Don't refetch if already loaded
    if (categories.isNotEmpty && !hasCategoriesError.value) {
      return;
    }

    try {
      isLoadingCategories.value = true;
      categoriesErrorMessage.value = '';
      hasCategoriesError.value = false;

      print('📡 [MaintenanceController] Fetching maintenance categories...');
      final response = await _apiService.get(ApiConstants.GET_MAINTENANCE_CATEGORIES);

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        
        if (responseData['status'] == true && responseData['data'] != null) {
          final List<dynamic> categoriesData = responseData['data'] as List<dynamic>;
          final List<MaintenanceCategory> fetchedCategories = categoriesData
              .map((json) {
                // Debug: Log raw category data to verify API response structure
                print('🔍 [MaintenanceController] Raw category JSON: $json');
                return MaintenanceCategory.fromJson(json as Map<String, dynamic>);
              })
              .toList();
          
          categories.value = fetchedCategories;
          
          // Debug: Log parsed categories to verify name_en field is populated
          for (final category in fetchedCategories) {
            print('🔍 [MaintenanceController] Parsed category - ID: ${category.id}, Name: "${category.name}", Name_EN: "${category.nameEn}", Description: "${category.description}"');
          }
          _updateCategoryTaskCounts();
          _applyFilter(); // Reapply filter in case category selection needs updating
          
          print('✅ [MaintenanceController] Loaded ${categories.length} maintenance categories');
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch categories');
        }
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print('❌ [MaintenanceController] Error fetching categories: $e');
      // Only log error, don't affect UI or behavior
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// Update category task counts based on loaded tasks
  void _updateCategoryTaskCounts() {
    categoryTaskCounts.clear();
    
    for (final category in categories) {
      // Count tasks that match this category by ID (more accurate than name matching)
      final count = tasks.where((task) => task.maintenanceCategoryId == category.id).length;
      categoryTaskCounts[category.id] = count;
    }
    
    // Trigger reactive update for filter list rebuild
    categoryTaskCounts.refresh();
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
      // Category selected - filter by category ID
      final categoryId = selectedCategoryId.value!;
      // Filter tasks by maintenanceCategoryId (more accurate than name matching)
      filteredTasks.value = tasks.where((task) => task.maintenanceCategoryId == categoryId).toList();
    }
  }

  /// Build filter list: [All] + API categories
  /// Returns list of filter items with id, label, and count
  List<Map<String, dynamic>> buildFilterList() {
    final filterList = <Map<String, dynamic>>[];
    
    // Always add "All" filter first
    filterList.add({
      'id': 'all',
      'label': 'All',
      'count': totalTaskCount.value,
    });
    
    // Add category filters dynamically from API
    if (categories.isNotEmpty) {
      for (final category in categories) {
        final count = categoryTaskCounts[category.id] ?? 0;
        // Use name_en for display label
        final label = category.nameEn.isNotEmpty ? category.nameEn : (category.name.isNotEmpty ? category.name : 'Category ${category.id}');
        filterList.add({
          'id': 'category_${category.id}',
          'categoryId': category.id,
          'label': label,
          'count': count,
        });
      }
    }
    
    return filterList;
  }

  /// Refresh all data (pull-to-refresh)
  Future<void> refreshData() async {
    await Future.wait([
      fetchMaintenanceCategories(),
      fetchMaintenanceTasks(),
    ]);
  }

  /// Pick a file for attachment (PDF, Images, DOC/DOCX)
  /// Returns true on success, false on failure or cancel
  /// Uses isolates for heavy file operations to prevent UI blocking
  Future<bool> pickFile() async {
    // Prevent multiple simultaneous file picks
    if (isPickingFile.value) {
      print('⚠️ [MaintenanceController] File picker already in progress');
      return false;
    }

    try {
      isPickingFile.value = true;
      print('📁 [MaintenanceController] Opening file picker...');
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );

      // User cancelled
      if (result == null || result.files.isEmpty) {
        print('📁 [MaintenanceController] File picker cancelled');
        return false;
      }

      final pickedFile = result.files.single;
      print('📁 [MaintenanceController] File selected: ${pickedFile.name}');

      // Check file size before processing (prevent memory issues and Android killing app)
      // This check happens BEFORE any heavy operations
      final fileSize = pickedFile.size;
      if (fileSize <= 0) {
        throw Exception('Invalid file size: $fileSize bytes');
      }
      if (fileSize > maxFileSizeBytes) {
        throw Exception('File size (${_formatFileSize(fileSize)}) exceeds maximum allowed size (${_formatFileSize(maxFileSizeBytes)})');
      }
      print('📁 [MaintenanceController] File size: ${_formatFileSize(fileSize)}');

      // Get app documents directory for permanent storage (lightweight operation)
      final appDocDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${appDocDir.path}/maintenance_attachments');
      
      // Create directory if it doesn't exist (lightweight)
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      // Generate unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = pickedFile.name;
      final fileExtension = fileName.contains('.') ? fileName.split('.').last : 'file';
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
            selectedFileName.value = fileName; // Keep original filename for display
            selectedFileSize.value = _formatFileSize(fileProcessResult.fileSize);
          }
        });
      }

      print('✅ [MaintenanceController] File selected successfully: $fileName (${selectedFileSize.value})');
      print('📁 [MaintenanceController] File saved to: $permanentFilePath');
      return true;
    } catch (e, stackTrace) {
      print('❌ [MaintenanceController] Error picking file: $e');
      print('❌ [MaintenanceController] Stack trace: $stackTrace');
      
      // Only show snackbar if controller is still valid
      if (!isClosed) {
        Get.snackbar(
          'Error',
          'Failed to pick file: ${e.toString()}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[700],
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
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
    
    print('🗑️ [MaintenanceController] File removed');
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
    personalCount.value = tasks.where((t) => t.priority == MaintenancePriority.personal).length;
    facoltativeCount.value = tasks.where((t) => t.priority == MaintenancePriority.facoltative).length;
    obbligatorieCount.value = tasks.where((t) => t.priority == MaintenancePriority.obbligatorie).length;
    condominialiCount.value = tasks.where((t) => t.priority == MaintenancePriority.condominiali).length;
    pendingCount.value = tasks.where((t) => t.status == MaintenanceStatus.pending).length;
    overdueCount.value = tasks.where((t) => t.status == MaintenanceStatus.overdue).length;
  }

  /// Get mock tasks (kept for fallback/testing - not used when API is available)
  List<MaintenanceTask> _getMockTasks() {
    return [
      MaintenanceTask(
        id: 'p1',
        title: 'Filter Replacement - Kitchen Hood',
        category: 'Appliances',
        description: 'Replace grease filters in kitchen ventilation hood for optimal performance.',
        priority: MaintenancePriority.personal,
        status: MaintenanceStatus.pending,
        frequency: 'Every 3 months',
        nextDue: '10 Nov 2025',
        lastCompleted: '10 Aug 2025',
        maintenanceCategoryId: 1,
        residenceId: 1,
        dueDate: '2025-11-10',
        lastMaintenanceDate: '2025-08-10',
      ),
      MaintenanceTask(
        id: 'p2',
        title: 'Fridge Coil Cleaning',
        category: 'Appliances',
        description: 'Clean refrigerator coils to improve efficiency and reduce energy consumption.',
        priority: MaintenancePriority.personal,
        status: MaintenanceStatus.inProgress,
        frequency: 'Every 6 months',
        nextDue: '5 Dec 2025',
        maintenanceCategoryId: 1,
        residenceId: 1,
        dueDate: '2025-12-05',
        attachments: [
          TaskAttachment(name: 'cleaning_guide.pdf', type: 'PDF', url: '#'),
        ],
      ),
      MaintenanceTask(
        id: '1',
        title: 'Ispezione Annuale Sistema HVAC',
        category: 'Climatizzazione',
        description: 'Ispezione annuale e sostituzione dei filtri per il sistema di riscaldamento, ventilazione e climatizzazione. Richiesto per la conformità alla garanzia e per garantire l\'efficienza energetica ottimale.',
        priority: MaintenancePriority.obbligatorie,
        status: MaintenanceStatus.overdue,
        frequency: 'Annualmente',
        nextDue: '30 Ott 2025',
        lastCompleted: '28 Ott 2024',
        maintenanceCategoryId: 1,
        residenceId: 1,
        dueDate: '2025-10-30',
        lastMaintenanceDate: '2024-10-28',
        attachments: [
          TaskAttachment(name: 'Certificato_Ispezione_2024.pdf', type: 'PDF', url: '#'),
          TaskAttachment(name: 'Manuale_HVAC.pdf', type: 'PDF', url: '#'),
        ],
        contacts: [
          TaskContact(
            name: 'TechClima Services',
            role: 'Specialista HVAC',
            phone: '+39 02 1234 5678',
            email: 'info@techclima.it',
          ),
        ],
      ),
      MaintenanceTask(
        id: '2',
        title: 'Controllo Pressione Caldaia',
        category: 'Riscaldamento',
        description: 'Controllo di routine della pressione e ottimizzazione del sistema. Raccomandato per prestazioni ottimali ed efficienza energetica.',
        priority: MaintenancePriority.facoltative,
        status: MaintenanceStatus.pending,
        frequency: 'Ogni 6 mesi',
        nextDue: '15 Nov 2025',
        lastCompleted: '10 Mag 2025',
        maintenanceCategoryId: 1,
        residenceId: 1,
        dueDate: '2025-11-15',
        lastMaintenanceDate: '2025-05-10',
      ),
      MaintenanceTask(
        id: '3',
        title: 'Ispezione Sicurezza Ascensore',
        category: 'Sistemi Edificio',
        description: 'Ispezione di sicurezza obbligatoria secondo le normative edilizie. Gestito dall\'amministratore condominiale.',
        priority: MaintenancePriority.condominiali,
        status: MaintenanceStatus.inProgress,
        frequency: 'Annualmente',
        nextDue: '8 Nov 2025',
        maintenanceCategoryId: 1,
        residenceId: 1,
        dueDate: '2025-11-08',
        attachments: [
          TaskAttachment(name: 'Certificato_Sicurezza.pdf', type: 'PDF', url: '#'),
        ],
        contacts: [
          TaskContact(
            name: 'SafeLift Italia',
            role: 'Ispettore Certificato',
            phone: '+39 02 9876 5432',
          ),
        ],
      ),
      MaintenanceTask(
        id: '4',
        title: 'Sostituzione Batterie Rilevatori di Fumo',
        category: 'Sicurezza',
        description: 'Sostituire le batterie in tutti i rilevatori di fumo per garantire il corretto funzionamento. Requisito di sicurezza critico.',
        priority: MaintenancePriority.obbligatorie,
        status: MaintenanceStatus.pending,
        frequency: 'Ogni 12 mesi',
        nextDue: '20 Nov 2025',
        lastCompleted: '18 Nov 2024',
        maintenanceCategoryId: 1,
        residenceId: 1,
        dueDate: '2025-11-20',
        lastMaintenanceDate: '2024-11-18',
      ),
      MaintenanceTask(
        id: '5',
        title: 'Manutenzione Scaldabagno',
        category: 'Idraulica',
        description: 'Decalcificazione e controllo dell\'efficienza. Aiuta a prevenire guasti e prolunga la vita dell\'apparecchiatura.',
        priority: MaintenancePriority.facoltative,
        status: MaintenanceStatus.pending,
        frequency: 'Ogni 18 mesi',
        nextDue: '1 Dic 2025',
        lastCompleted: '1 Giu 2024',
        maintenanceCategoryId: 1,
        residenceId: 1,
        dueDate: '2025-12-01',
        lastMaintenanceDate: '2024-06-01',
      ),
      MaintenanceTask(
        id: '6',
        title: 'Ispezione Guarnizioni Finestre',
        category: 'Involucro Edificio',
        description: 'Controllare e mantenere le guarnizioni delle finestre per l\'efficienza energetica. Raccomandato prima della stagione invernale.',
        priority: MaintenancePriority.facoltative,
        status: MaintenanceStatus.pending,
        frequency: 'Annualmente',
        nextDue: '5 Nov 2025',
        maintenanceCategoryId: 1,
        residenceId: 1,
        dueDate: '2025-11-05',
      ),
      MaintenanceTask(
        id: '7',
        title: 'Controllo Estintori',
        category: 'Sicurezza',
        description: 'Ispezione annuale obbligatoria di tutte le attrezzature antincendio.',
        priority: MaintenancePriority.obbligatorie,
        status: MaintenanceStatus.pending,
        frequency: 'Annualmente',
        nextDue: '12 Nov 2025',
        lastCompleted: '10 Nov 2024',
        maintenanceCategoryId: 1,
        residenceId: 1,
        dueDate: '2025-11-12',
        lastMaintenanceDate: '2024-11-10',
        contacts: [
          TaskContact(
            name: 'FireSafe Solutions',
            role: 'Ispettore Sicurezza',
          ),
        ],
      ),
      MaintenanceTask(
        id: '8',
        title: 'Aggiornamento Illuminazione Aree Comuni',
        category: 'Sistemi Edificio',
        description: 'Progetto di aggiornamento LED per corridoi e spazi comuni dell\'edificio. Gestito dall\'amministratore.',
        priority: MaintenancePriority.condominiali,
        status: MaintenanceStatus.pending,
        frequency: 'Progetto una tantum',
        nextDue: '25 Nov 2025',
        maintenanceCategoryId: 1,
        residenceId: 1,
        dueDate: '2025-11-25',
      ),
    ];
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
Future<_FileProcessResult> _processFileInIsolate(_FileProcessParams params) async {
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
    if (fileBytes == null || fileBytes.isEmpty) {
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

    return _FileProcessResult(
      success: true,
      fileSize: fileSize,
    );
  } catch (e, stackTrace) {
    // Log error details for debugging
    print('❌ [Isolate] Error processing file: $e');
    print('❌ [Isolate] Stack trace: $stackTrace');
    return _FileProcessResult(
      success: false,
      error: 'File processing failed: ${e.toString()}',
      fileSize: 0,
    );
  }
}

