// presentation/maintenance/controllers/maintenance_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/maintenance_task_model.dart';
import '../models/maintenance_category_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class MaintenanceController extends GetxController {
  // API Service
  final ApiService _apiService = Get.find<ApiService>();

  // Reactive variables for tasks
  final RxList<MaintenanceTask> tasks = <MaintenanceTask>[].obs;
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

  @override
  void onInit() {
    super.onInit();
    fetchMaintenanceCategories();
    fetchMaintenanceTasks();
  }

  /// Fetch maintenance tasks from API or mock data
  Future<void> fetchMaintenanceTasks() async {
    try {
      isLoadingTasks.value = true;
      errorMessage.value = '';
      hasError.value = false;

      // TODO: Replace with actual API call
      // For now, using mock data
      await Future.delayed(const Duration(milliseconds: 500));

      final mockTasks = _getMockTasks();
      tasks.value = mockTasks;
      totalTaskCount.value = mockTasks.length;
      _updateFilterCounts(mockTasks);
      _updateCategoryTaskCounts(); // Update category counts when tasks are loaded

      print('✅ Loaded ${tasks.length} maintenance tasks');
    } catch (e) {
      print('❌ Error in fetchMaintenanceTasks: $e');
      errorMessage.value = 'An error occurred while fetching tasks';
      hasError.value = true;
      tasks.clear();
    } finally {
      isLoadingTasks.value = false;
    }
  }

  /// Create a new maintenance task
  Future<void> createMaintenanceTask({
    required String title,
    required String category,
    required String frequency,
    String? notes,
    File? attachment,
  }) async {
    try {
      isLoadingTasks.value = true;

      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 1000));

      // Create new task
      final newTask = MaintenanceTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        category: category,
        description: notes ?? '',
        priority: MaintenancePriority.personal,
        status: MaintenanceStatus.pending,
        frequency: frequency,
      );

      tasks.add(newTask);
      totalTaskCount.value = tasks.length;
      _updateFilterCounts(tasks);
      _updateCategoryTaskCounts(); // Update category counts

      Get.snackbar(
        'Success',
        'Maintenance task created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF6A8F7B),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      print('✅ Created maintenance task: $title');
    } catch (e) {
      print('❌ Error creating maintenance task: $e');
      Get.snackbar(
        'Error',
        'Failed to create maintenance task',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
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
              .map((json) => MaintenanceCategory.fromJson(json as Map<String, dynamic>))
              .toList();
          
          categories.value = fetchedCategories;
          _updateCategoryTaskCounts();
          
          print('✅ [MaintenanceController] Loaded ${categories.length} maintenance categories');
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch categories');
        }
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print('❌ [MaintenanceController] Error fetching categories: $e');
      categoriesErrorMessage.value = 'Failed to load categories';
      hasCategoriesError.value = true;
      categories.clear();
      // Don't crash - continue with empty categories
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// Update category task counts based on loaded tasks
  void _updateCategoryTaskCounts() {
    categoryTaskCounts.clear();
    
    for (final category in categories) {
      // Count tasks that match this category by name
      // Note: This assumes tasks have category names. If tasks have category IDs, update accordingly
      final count = tasks.where((task) => task.category == category.name).length;
      categoryTaskCounts[category.id] = count;
    }
  }

  /// Set selected category ID for filtering
  void setSelectedCategoryId(int? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  /// Refresh all data (pull-to-refresh)
  Future<void> refreshData() async {
    await Future.wait([
      fetchMaintenanceCategories(),
      fetchMaintenanceTasks(),
    ]);
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

  /// Get mock tasks (replace with API call)
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
      ),
    ];
  }
}

