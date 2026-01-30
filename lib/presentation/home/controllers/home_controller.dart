import 'package:casazero/presentation/documents/controllers/documents_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/message_popup_controller.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/feed_item_model.dart';
import '../../../data/models/construction_phase_model.dart';
import '../../../data/models/residence_model.dart';
import '../../../data/models/document_model.dart';
import '../../../core/utils/permissions.dart';
import '../../../app/routes/app_routes.dart';
import '../../main/main_scaffold.dart'; // Import for AppScreen enum

class HomeController extends GetxController {
  final HomeRepository _homeRepository = Get.find();
  final StorageService _storageService = Get.find();

  // Reactive variables
  final isLoading = false.obs;
  final currentUser = Rx<UserModel?>(null);
  final feedItems = <FeedItemModel>[].obs;
  final constructionPhases = <ConstructionPhaseModel>[].obs;

  // Unread notification count from API (single source of truth)
  final unreadCount = 0.obs;

  // API Token state (single source of truth - ensures token is ready before API calls)
  final apiToken = RxString('');
  final _isInitialized = false.obs; // Prevent duplicate initialization

  // Residence management
  final residences = <ResidenceModel>[].obs;
  final selectedResidence = Rx<ResidenceModel?>(null);
  final isLoadingResidences = false.obs;

  // Residence data for Home Screen (from API)
  final residenceData = Rx<Map<String, dynamic>?>(null);

  // Screen navigation
  final currentScreen = AppScreen.home.obs;
  final screenHistory = <AppScreen>[].obs;
  final forwardHistory = <AppScreen>[].obs;

  // Computed properties
  Permissions get permissions =>
      Permissions.fromRole(currentUser.value?.role ?? Role.client);

  // Bottom navigation tabs
  List<BottomNavTab> get bottomNavTabs => [
    const BottomNavTab(
      screen: AppScreen.home,
      label: 'Home',
      //icon: Icons.home_outlined,
      assetIcon: 'assets/images/home.svg',
    ),
    const BottomNavTab(
      screen: AppScreen.documents,
      label: 'Documents',
      //icon: Icons.description,
      assetIcon: 'assets/images/document.svg',
    ),
    const BottomNavTab(
      screen: AppScreen.hubScreen,
      label: 'AI',
      assetIcon: "assets/images/casa_zero_nav_bar.svg",
    ),
    const BottomNavTab(
      screen: AppScreen.maintenance,
      label: 'Maintenance',
      //icon: Icons.build_outlined,
      assetIcon: "assets/images/maintainance.svg",
    ),
    const BottomNavTab(
      screen: AppScreen.profile,
      label: 'Profile',
      assetIcon: "assets/images/profile.svg",
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadApiToken(); // Load token FIRST before any API calls
  }

  @override
  void onReady() {
    super.onReady();

    // CRITICAL: Always check token and initialize if available
    // This ensures notifications are fetched on app launch
    if (apiToken.value.isNotEmpty) {
      if (!_isInitialized.value) {
        print(
          '✅ [HomeController] API token available, initializing data (including notifications)...',
        );
        _initializeDataWithToken();
      } else {
        print('⚠️ [HomeController] Already initialized, skipping');
      }
    } else {
      print(
        '⚠️ [HomeController] API token not available yet, setting up listener...',
      );
      // Wait for token to be ready before making API calls
      // Use one-time listener to trigger APIs when token becomes available
      once(apiToken, (token) {
        if (token.isNotEmpty && !_isInitialized.value) {
          print(
            '✅ [HomeController] API token ready via listener, initializing data (including notifications)...',
          );
          _initializeDataWithToken();
        }
      });
    }
  }

  /// Load API token from storage
  void _loadApiToken() {
    final token = _storageService.getAccessToken();
    apiToken.value = token ?? '';
    print(
      '🔑 [HomeController] Loaded apiToken: ${token != null && token.isNotEmpty ? "${token.substring(0, 10)}..." : "NO TOKEN"}',
    );
    // Note: Initialization is handled in onReady() to ensure proper lifecycle order
  }

  /// Public method to reload token (e.g., after login)
  void reloadToken() {
    _loadApiToken();
  }

  /// Initialize all data after token is confirmed available
  void _initializeDataWithToken() {
    // Only initialize once to avoid duplicate calls
    if (_isInitialized.value) {
      print('⚠️ [HomeController] Already initialized, skipping');
      return;
    }

    if (apiToken.value.isEmpty) {
      print('❌ [HomeController] Cannot initialize: API token is empty');
      return;
    }

    _isInitialized.value = true;
    print('✅ [HomeController] Initializing data with token...');

    fetchResidences(); // Fetch residences
    fetchHomeData();
    fetchResidenceData();
    fetchNotifications(); // Fetch notifications from API
    fetchUnreadCount(); // Fetch unread count from API
    // Pre-load documents in background after login
    _preloadDocuments();
  }

  /// Pre-load documents in background after login
  /// This ensures documents are ready when user navigates to documents screen
  void _preloadDocuments() {
    // Call in background - don't await
    Future.microtask(() async {
      try {
        print('Pre-loading documents in HomeController...');
        final documentRepository = DocumentRepository();
        final result = await documentRepository.getDocumentsByUnit();

        if (result['success'] == true) {
          // Initialize DocumentsController with pre-loaded data
          if (!Get.isRegistered<DocumentsController>()) {
            final documentsController = Get.put(DocumentsController());
            // Update documents list with pre-loaded data
            final documentsData = result['data'];

            // Handle both List<DocumentModel> and List<Map> cases
            if (documentsData is List) {
              if (documentsData.isNotEmpty &&
                  documentsData.first is DocumentModel) {
                // Already DocumentModel objects
                documentsController.documents.value = documentsData
                    .cast<DocumentModel>();
              } else {
                // Raw JSON maps - need to parse
                documentsController.documents.value = documentsData
                    .map(
                      (item) =>
                          DocumentModel.fromJson(item as Map<String, dynamic>),
                    )
                    .toList();
              }
            }
            print(
              '✅ Documents pre-loaded in HomeController: ${documentsData.length} documents',
            );
          } else {
            // If controller exists, just refresh
            final documentsController = Get.find<DocumentsController>();
            await documentsController.fetchDocuments();
          }
        } else {
          print('⚠️  Failed to pre-load documents: ${result['error']}');
        }
      } catch (e) {
        print('⚠️  Error pre-loading documents: $e');
        // Don't block - just log the error
      }
    });
  }

  Future<void> _loadUserData() async {
    final userData = _storageService.getUserData();
    if (userData != null) {
      currentUser.value = UserModel.fromJson(userData);
    }
  }

  /// Fetch user residences from API
  Future<void> fetchResidences() async {
    // Guard: Check token before API call
    if (apiToken.value.isEmpty) {
      print(
        '⚠️ [HomeController] fetchResidences: API token not ready, skipping',
      );
      return;
    }

    try {
      isLoadingResidences.value = true;

      final result = await _homeRepository.getUserResidences();

      if (result['success'] == true) {
        residences.value = result['data'] as List<ResidenceModel>;

        // Auto-select first residence if available and none selected
        if (residences.isNotEmpty && selectedResidence.value == null) {
          selectedResidence.value = residences.first;
          print(
            'Auto-selected residence: ${selectedResidence.value?.residenceName}',
          );

          if (Get.isRegistered<DocumentsController>()) {
            Get.find<DocumentsController>().fetchDocuments();
          }
        }

        print('Loaded ${residences.length} residences');
      } else {
        print('Failed to fetch residences: ${result['error']}');
        MessagePopupController.showError(
          messageKey: result['error'] ?? 'failed_to_load_residences',
          titleKey: 'error',
        );
      }
    } catch (e) {
      print('Error fetching residences: $e');
    } finally {
      isLoadingResidences.value = false;
    }
  }

  /// Select a residence
  void selectResidence(ResidenceModel residence) {
    selectedResidence.value = residence;
    print('Selected residence: ${residence.residenceName}');
    if (Get.isRegistered<DocumentsController>()) {
      Get.find<DocumentsController>().fetchDocuments();
    }
  }

  /// Show residence selector dialog
  void showResidenceSelector(BuildContext context) {
    if (residences.isEmpty) {
      MessagePopupController.showInfo(
        messageKey: 'no_residences_available',
        titleKey: 'info',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Residence'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: residences.length,
            itemBuilder: (context, index) {
              final residence = residences[index];
              final isSelected = selectedResidence.value?.id == residence.id;

              return ListTile(
                leading: Icon(
                  Icons.apartment_rounded,
                  color: isSelected ? Colors.green : Colors.grey,
                ),
                title: Text(
                  residence.residenceName,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: residence.residenceAddress != null
                    ? Text(residence.residenceAddress!)
                    : null,
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  selectResidence(residence);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> fetchHomeData() async {
    try {
      isLoading.value = true;

      // Fetch feed items
      final feedResponse = await _homeRepository.getFeedItems();
      // if (feedResponse['success']) {
      //   feedItems.value = (feedResponse['data'] as List)
      //       .map((item) => FeedItemModel.fromJson(item))
      //       .toList();
      // }

      // Fetch construction phases if under construction
      // if (currentUser.value?.residenceStatus == ResidenceStatus.underConstruction) {
      //   final phasesResponse = await _homeRepository.getConstructionPhases();
      //   if (phasesResponse['success']) {
      //     constructionPhases.value = (phasesResponse['data'] as List)
      //         .map((phase) => ConstructionPhaseModel.fromJson(phase))
      //         .toList();
      //   }
      // }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      MessagePopupController.showError(
        messageKey: 'failed_to_load_home_data',
        titleKey: 'error',
      );
    }
  }

  Future<void> refreshData() async {
    // Reload token before refresh to ensure it's current
    _loadApiToken();

    // Only proceed if token is available
    if (apiToken.value.isEmpty) {
      print(
        '⚠️ [HomeController] refreshData: API token not available, skipping refresh',
      );
      return;
    }

    await fetchHomeData();
    await fetchResidenceData();
    await fetchNotifications(); // Refresh notifications on pull-to-refresh
    await fetchUnreadCount(); // Refresh unread count on pull-to-refresh
  }

  /// Fetch notifications from API (user-wise)
  Future<void> fetchNotifications() async {
    // Guard: Check token before API call
    if (apiToken.value.isEmpty) {
      print(
        '⚠️ [HomeController] fetchNotifications: API token not ready, skipping',
      );
      return;
    }

    try {
      print('🔔 [HomeController] Fetching notifications from API...');

      final result = await _homeRepository.getUserNotifications();

      if (result['success'] == true) {
        final notifications = result['data'] as List<FeedItemModel>;
        feedItems.value = notifications;
        print(
          '✅ [HomeController] Successfully loaded ${notifications.length} notifications',
        );

        // Refresh unread count after fetching notifications to stay in sync
        await fetchUnreadCount();
      } else {
        print(
          '❌ [HomeController] Failed to fetch notifications: ${result['error']}',
        );
        // On error, set empty list (don't show mock data)
        feedItems.value = [];
      }
    } catch (e) {
      print('❌ [HomeController] Error fetching notifications: $e');
      // On error, set empty list (don't show mock data)
      feedItems.value = [];
    }
  }

  /// Fetch unread notification count from API (single source of truth)
  Future<void> fetchUnreadCount() async {
    // Guard: Check token before API call
    if (apiToken.value.isEmpty) {
      print(
        '⚠️ [HomeController] fetchUnreadCount: API token not ready, skipping',
      );
      return;
    }

    try {
      print(
        '🔔 [HomeController] Fetching unread notification count from API...',
      );

      final result = await _homeRepository.getUnreadNotificationCount();

      if (result['success'] == true) {
        final count = result['unread_count'] as int? ?? 0;
        unreadCount.value = count;
        print('✅ [HomeController] Unread count updated: $count');
      } else {
        final errorMessage = result['error'] ?? 'Unknown error';
        print('❌ [HomeController] Failed to fetch unread count: $errorMessage');
        // Keep last known value on error (don't reset to 0)
        print(
          '⚠️ [HomeController] Keeping last known unread count: ${unreadCount.value}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ [HomeController] Exception fetching unread count: $e');
      print('❌ [HomeController] Exception type: ${e.runtimeType}');
      print('📚 [HomeController] Stack trace: $stackTrace');
      // Keep last known value on error (don't reset to 0)
      print(
        '⚠️ [HomeController] Keeping last known unread count: ${unreadCount.value}',
      );
    }
  }

  /// Mark notification as read (with API sync)
  Future<void> markNotificationAsRead(String notificationId) async {
    // Guard: Check token before API call
    if (apiToken.value.isEmpty) {
      print(
        '⚠️ [HomeController] markNotificationAsRead: API token not ready, skipping',
      );
      return;
    }

    // Check if notification is already read (avoid unnecessary API call)
    final index = feedItems.indexWhere((item) => item.id == notificationId);
    if (index == -1) {
      print('⚠️ [HomeController] Notification not found: $notificationId');
      return;
    }

    final notification = feedItems[index];
    if (notification.isRead) {
      print('ℹ️ [HomeController] Notification already read: $notificationId');
      return; // Already read, don't call API
    }

    try {
      // Parse notification ID to int (API expects int)
      final notificationIdInt = int.tryParse(notificationId);
      if (notificationIdInt == null) {
        print(
          '❌ [HomeController] Invalid notification ID format: $notificationId',
        );
        return;
      }

      print(
        '📝 [HomeController] Marking notification as read: $notificationId',
      );

      // Call API to mark as read
      final result = await _homeRepository.markNotificationAsRead(
        notificationIdInt,
      );

      if (result['success'] == true) {
        // Update local state optimistically
        feedItems[index] = notification.copyWith(isRead: true);
        feedItems.refresh(); // Trigger reactive update

        print('✅ [HomeController] Notification marked as read successfully');

        // Refresh unread count from API to stay in sync
        await fetchUnreadCount();
      } else {
        print(
          '❌ [HomeController] Failed to mark notification as read: ${result['error']}',
        );
        // Don't update local state if API call failed
      }
    } catch (e) {
      print('❌ [HomeController] Error marking notification as read: $e');
      // Don't update local state if API call failed
    }
  }

  /// Handle Chat action for notification (API-ready)
  void onNotificationChat(FeedItemModel notification) {
    // TODO: Integrate chat API
    // Example: Navigate to chat screen with notification context
    // Get.toNamed('/chat', arguments: {'notificationId': notification.id});
    print('📱 Chat pressed for notification: ${notification.id}');
  }

  /// Handle Assistance action for notification (API-ready)
  void onNotificationAssistance(FeedItemModel notification) {
    // TODO: Integrate assistance API
    // Example: Open assistance form or contact support
    // Get.toNamed('/assistance', arguments: {'notificationId': notification.id});
    print('🆘 Assistance pressed for notification: ${notification.id}');
  }

  /// Handle AI Support action for notification (API-ready)
  void onNotificationAiSupport(FeedItemModel notification) {
    // TODO: Integrate AI support API
    // Example: Navigate to AI chat with notification context
    // Get.toNamed('/ai-chat', arguments: {'notificationId': notification.id});
    print('🤖 AI Support pressed for notification: ${notification.id}');
  }

  /// Fetch residence data for Home Screen
  Future<void> fetchResidenceData() async {
    // Guard: Check token before API call
    if (apiToken.value.isEmpty) {
      print(
        '⚠️ [HomeController] fetchResidenceData: API token not ready, skipping',
      );
      return;
    }

    try {
      print('🏠 [HomeController] Fetching residence data...');
      final result = await _homeRepository.getResidenceByToken();

      if (result['success'] == true) {
        residenceData.value = result['data'] as Map<String, dynamic>;
        print(
          '✅ [HomeController] Residence data loaded: ${residenceData.value}',
        );
        // Temporary log: Confirm residence_photo is available
        final photo = residenceData.value?['residence_photo'];
        print('🏠 [HomeController] Residence image URL from data: $photo');
      } else {
        print(
          '❌ [HomeController] Failed to fetch residence data: ${result['error']}',
        );
        // Log error but don't show UI - as per requirements
      }
    } catch (e) {
      print('❌ [HomeController] Error fetching residence data: $e');
      // Log error but don't show UI - as per requirements
    }
  }

  // SCREEN NAVIGATION METHODS

  /// Navigate to a screen and add to history
  void navigateToScreen(AppScreen screen, {bool addToHistory = true}) {
    if (addToHistory && currentScreen.value != screen) {
      screenHistory.add(currentScreen.value);
      // Clear forward history when navigating to a new screen
      forwardHistory.clear();
    }
    currentScreen.value = screen;
  }

  /// Navigate by string (for compatibility with existing code)
  void navigateToScreenByString(String destination) {
    switch (destination.toLowerCase()) {
      case 'home':
        navigateToScreen(AppScreen.home);
        break;
      case 'documents':
        navigateToScreen(AppScreen.documents);
        break;
      case 'aichat':
      case 'ai':
        navigateToScreen(AppScreen.ai);
        break;
      case 'maintenance':
        navigateToScreen(AppScreen.maintenance);
        break;
      case 'profile':
        navigateToScreen(AppScreen.profile);
        break;
      case 'smarthome':
      case 'smart_home':
        navigateToScreen(AppScreen.smartHome);
        break;
      case 'change_password':
      case 'changepassword':
        navigateToScreen(AppScreen.changePassword);
        break;

      case 'chat':
        navigateToScreen(AppScreen.chat);
        break;

      case 'tickets':
        navigateToScreen(AppScreen.tickets);
        break;

      case 'buildings':
        // Handle buildings navigation
        navigateToScreen(AppScreen.home);
        break;
      default:
        print('Unknown destination: $destination');
        navigateToScreen(AppScreen.home);
    }
  }

  /// Go back to previous screen
  void goBack() {
    if (screenHistory.isNotEmpty) {
      final previousScreen = screenHistory.removeLast();
      // Add current screen to forward history
      forwardHistory.add(currentScreen.value);
      currentScreen.value = previousScreen;
    } else {
      // If no history, go to home
      if (currentScreen.value != AppScreen.home) {
        forwardHistory.add(currentScreen.value);
        currentScreen.value = AppScreen.home;
      }
    }
  }

  /// Go forward to next screen
  void goForward() {
    if (forwardHistory.isNotEmpty) {
      final nextScreen = forwardHistory.removeLast();
      // Add current screen to back history
      screenHistory.add(currentScreen.value);
      currentScreen.value = nextScreen;
    }
  }

  /// Check if can go back
  bool get canGoBack =>
      screenHistory.isNotEmpty || currentScreen.value != AppScreen.home;

  /// Check if can go forward
  bool get canGoForward => forwardHistory.isNotEmpty;

  /// Handle system back button
  Future<bool> handleBackNavigation() async {
    // Check if we're on a main bottom nav screen
    final mainScreens = bottomNavTabs.map((tab) => tab.screen).toList();

    if (!mainScreens.contains(currentScreen.value)) {
      // We're on a sub-screen, go back
      goBack();
      return false; // Don't exit app
    } else if (currentScreen.value != AppScreen.home) {
      // We're on a main screen but not home, go to home
      navigateToScreen(AppScreen.home, addToHistory: false);
      return false; // Don't exit app
    } else {
      // We're on home, allow app exit
      return true; // Exit app
    }
  }

  // Clear navigation history
  void clearHistory() {
    screenHistory.clear();
    forwardHistory.clear();
  }

  // LOGOUT
  Future<void> logout() async {
    try {
      print('🚪 Starting logout process from HomeController...');

      // Import AuthRepository
      final authRepository = AuthRepository();

      // Call logout API first
      final result = await authRepository.logout();

      if (result['success'] == true) {
        print('✅ Logout API successful: ${result['message']}');
      } else {
        print('⚠️  Logout API failed: ${result['error']}');
        // Still proceed with clearing storage even if API fails
      }

      // Clear all storage regardless of API result
      await _storageService.clearAll();
      print('✅ All storage cleared');

      // Navigate to auth screen
      Get.offAllNamed(AppRoutes.AUTH);
      print('✅ Navigated to auth screen');
    } catch (e) {
      print('❌ Error during logout: $e');
      // Even if there's an error, try to clear storage and navigate
      try {
        await _storageService.clearAll();
        Get.offAllNamed(AppRoutes.AUTH);
      } catch (clearError) {
        print('❌ Error clearing storage: $clearError');
        MessagePopupController.showError(
          messageKey: 'failed_to_logout',
          titleKey: 'error',
        );
      }
    }
  }
}
