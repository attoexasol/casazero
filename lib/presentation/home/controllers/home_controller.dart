import 'dart:async';

import 'package:casazero/presentation/documents/controllers/documents_controller.dart';
import 'package:casazero/presentation/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/controllers/message_popup_controller.dart';
import '../../../core/widgets/responsive_alert_dialog.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/feed_item_model.dart';
import '../../../data/models/construction_phase_model.dart';
import '../../../data/models/residence_model.dart';
import '../../../data/models/residence_status_phase_model.dart';
import '../../../data/models/document_model.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/navigation/auth_navigation.dart';
import '../../../core/services/session_expiry_service.dart';
import '../../chat/controllers/private_chat_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../main/main_scaffold.dart'; // Import for AppScreen enum

class HomeController extends GetxController {
  final HomeRepository _homeRepository = Get.find();
  final StorageService _storageService = Get.find();

  // Reactive variables
  final isLoading = false.obs;
  final currentUser = Rx<UserModel?>(null);
  final feedItems = <FeedItemModel>[].obs;
  final constructionPhases = <ConstructionPhaseModel>[].obs;

  /// Construction phases from API (status-with-phases). Used for Construction Progress section.
  final constructionPhasesFromApi = <ResidenceStatusPhaseModel>[].obs;
  final constructionPhasesLoading = false.obs;

  // Unread notification count from API (single source of truth)
  final unreadCount = 0.obs;

  // API Token state (single source of truth - ensures token is ready before API calls)
  final apiToken = RxString('');
  final _isInitialized = false.obs; // Prevent duplicate initialization
  bool _initialLoadInProgress = false;
  bool _residenceDataFetchInProgress = false;

  // Residence management
  final residences = <ResidenceModel>[].obs;
  final selectedResidence = Rx<ResidenceModel?>(null);
  final isLoadingResidences = false.obs;

  // Residence data for Home Screen (from GET /single_residence/{id})
  final residenceData = Rx<Map<String, dynamic>?>(null);

  /// Assigned residence admin — stored when single_residence API loads.
  final residenceAdminId = RxnInt();
  final residenceAdminName = RxnString();

  // Screen navigation
  final currentScreen = AppScreen.home.obs;
  final screenHistory = <AppScreen>[].obs;
  final forwardHistory = <AppScreen>[].obs;

  // Computed properties
  Permissions get permissions =>
      Permissions.fromRole(currentUser.value?.role ?? Role.client);

  /// Resolved status: prefer live API residence data, then selected residence, then cached user.
  ResidenceStatus? get resolvedResidenceStatus {
    final fromApi = UserModel.parseResidenceStatus(
      residenceData.value?['residence_status']?.toString(),
    );
    if (fromApi != null) return fromApi;

    final fromSelected = UserModel.parseResidenceStatus(
      selectedResidence.value?.residenceStatus,
    );
    if (fromSelected != null) return fromSelected;

    return currentUser.value?.residenceStatus;
  }

  bool get isResidenceUnderConstruction =>
      resolvedResidenceStatus == ResidenceStatus.underConstruction;

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

  /// Clears user-specific state when user logs out so next login gets fresh data.
  void clearStateOnLogout() {
    apiToken.value = '';
    currentUser.value = null;
    feedItems.clear();
    unreadCount.value = 0;
    residences.clear();
    selectedResidence.value = null;
    residenceData.value = null;
    residenceAdminId.value = null;
    residenceAdminName.value = null;
    constructionPhasesFromApi.clear();
    _isInitialized.value = false;
    _initialLoadInProgress = false;
    isLoading.value = false;
    print('🧹 [HomeController] State cleared for logout');
  }

  /// Ensures home data (notifications, residences, user) matches the current user in storage.
  /// Call when navigating to HOME so that after a different user logs in, we refetch everything.
  void ensureDataForCurrentUser() {
    final userData = _storageService.getUserData();
    final storageUserId = userData?['id'];
    final currentId = currentUser.value?.id;

    final int? storageId = storageUserId is int
        ? storageUserId
        : int.tryParse(storageUserId?.toString() ?? '');

    final bool userChanged = storageId != null &&
        (currentId == null || currentId != storageId);
    final bool noUserInController = currentId == null && storageId != null;

    if (!userChanged && !noUserInController) {
      ensureHomeResidenceLoaded();
      return;
    }

    _loadUserData();
    // onReady may have initialized already — avoid wiping state and reloading twice.
    if (_isInitialized.value &&
        storageId != null &&
        currentUser.value?.id == storageId) {
      return;
    }

    print(
      '🔄 [HomeController] User changed or first load (storage: $storageId, current: $currentId), reinitializing...',
    );

    _loadApiToken();

    feedItems.clear();
    unreadCount.value = 0;
    residences.clear();
    selectedResidence.value = null;
    residenceData.value = null;
    residenceAdminId.value = null;
    residenceAdminName.value = null;
    _isInitialized.value = false;

    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().forceReloadUser();
    }
    if (Get.isRegistered<DocumentsController>()) {
      Get.find<DocumentsController>().clearDocuments();
    }

    if (apiToken.value.isNotEmpty) {
      _initializeDataWithToken();
    } else {
      once(apiToken, (_) {
        if (apiToken.value.isNotEmpty && !_isInitialized.value) {
          _initializeDataWithToken();
        }
      });
    }
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

    unawaited(_loadInitialHomeData());
    fetchNotifications(); // Also refreshes unread count on success
    _preloadDocuments();
  }

  /// Single coordinated home load — avoids full-screen loader + section loaders flashing twice.
  Future<void> _loadInitialHomeData() async {
    if (apiToken.value.isEmpty || _initialLoadInProgress) return;

    _initialLoadInProgress = true;
    try {
      isLoading.value = true;
      await fetchResidences();
      await fetchResidenceData();
    } catch (e) {
      print('❌ [HomeController] _loadInitialHomeData: $e');
    } finally {
      isLoading.value = false;
      _initialLoadInProgress = false;
    }
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
            final documentsController = Get.put(
              DocumentsController(skipInitialFetch: true),
            );
            // Update documents list with pre-loaded data
            final documentsData = result['data'];

            // Handle both List<DocumentModel> and List<Map> cases
            if (documentsData is List) {
              final parsed = documentsData.map<DocumentModel>((item) {
                if (item is DocumentModel) return item;
                return DocumentModel.fromJson(item as Map<String, dynamic>);
              }).toList();
              documentsController.applyDocuments(parsed);
            }
            await documentsController.fetchDocumentCategories();
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
          _syncResidenceStatus(selectedResidence.value?.residenceStatus);
          print(
            'Auto-selected residence: ${selectedResidence.value?.residenceName}',
          );
        }

        print('Loaded ${residences.length} residences');
      } else {
        print('Failed to fetch residences: ${result['error']}');
        MessagePopupController.showError(
          messageKey: 'failed_to_load_residences',
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
    _syncResidenceStatus(residence.residenceStatus);
    print('Selected residence: ${residence.residenceName}');
    unawaited(fetchResidenceData());
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
      builder: (dialogContext) => ResponsiveAlertDialog(
        scrollable: true,
        title: Text(
          'Select Residence',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: ResponsiveAlertDialog.boundedList(
          context: dialogContext,
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
                    fontSize: 15.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: residence.residenceAddress != null
                    ? Text(
                        residence.residenceAddress!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.sp),
                      )
                    : null,
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  selectResidence(residence);
                  Navigator.pop(dialogContext);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'cancel'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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

    await fetchResidences();
    await fetchResidenceData();
    await fetchNotifications();
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

  /// Delete notification (with API sync)
  Future<void> deleteNotification(String notificationId) async {
    if (apiToken.value.isEmpty) {
      print(
        '⚠️ [HomeController] deleteNotification: API token not ready, skipping',
      );
      return;
    }

    final index = feedItems.indexWhere((item) => item.id == notificationId);
    if (index == -1) {
      print('⚠️ [HomeController] Notification not found: $notificationId');
      return;
    }

    final notification = feedItems[index];
    final wasUnread = !notification.isRead;

    try {
      final notificationIdInt = int.tryParse(notificationId);
      if (notificationIdInt == null) {
        print(
          '❌ [HomeController] Invalid notification ID format: $notificationId',
        );
        return;
      }

      print('🗑️ [HomeController] Deleting notification: $notificationId');

      final result = await _homeRepository.deleteNotification(
        notificationIdInt,
      );

      if (result['success'] == true) {
        feedItems.removeAt(index);
        feedItems.refresh();

        if (wasUnread) {
          await fetchUnreadCount();
        }

        print('✅ [HomeController] Notification deleted successfully');
      } else {
        print(
          '❌ [HomeController] Failed to delete notification: ${result['error']}',
        );
        MessagePopupController.showError(
          messageKey: 'failed_to_delete_notification',
          titleKey: 'notifications',
        );
      }
    } catch (e) {
      print('❌ [HomeController] Error deleting notification: $e');
      MessagePopupController.showError(
        messageKey: 'failed_to_delete_notification',
        titleKey: 'notifications',
      );
    }
  }

  /// Handle Chat action for notification — opens condominium group chat or admin DM.
  void onNotificationChat(FeedItemModel notification) {
    if (notification.isAdminChatNotification) {
      if (Get.isRegistered<PrivateChatController>()) {
        Get.delete<PrivateChatController>();
      }
      if (!Get.isRegistered<PrivateChatController>()) {
        Get.put(PrivateChatController());
      }
      navigateToScreen(AppScreen.adminChat);
      return;
    }

    if (!Get.isRegistered<ChatController>()) {
      Get.put(ChatController());
    }
    navigateToScreen(AppScreen.chat);
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

  /// Fetch residence via GET /single_residence/{id} and store admin for private chat.
  Future<void> fetchResidenceData() async {
    if (apiToken.value.isEmpty) {
      print(
        '⚠️ [HomeController] fetchResidenceData: API token not ready, skipping',
      );
      return;
    }

    final residenceId = _resolveResidenceIdForSingleResidence();
    if (residenceId == null) {
      print('⚠️ [HomeController] fetchResidenceData: no residence id yet');
      return;
    }

    try {
      print('🏠 [HomeController] Fetching single_residence/$residenceId...');
      final result = await _homeRepository.getSingleResidence(residenceId);

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        residenceData.value = {
          ...data,
          'id': data['id'] ?? residenceId,
        };
        _storeResidenceAdminFromData(data);
        print('✅ [HomeController] Residence data loaded: id=$residenceId');

        _syncResidenceStatus(data['residence_status']?.toString());
        if (isResidenceUnderConstruction) {
          await fetchConstructionPhases();
        } else {
          constructionPhasesFromApi.clear();
        }
      } else {
        print(
          '❌ [HomeController] Failed to fetch residence data: ${result['error']}',
        );
      }
    } catch (e) {
      print('❌ [HomeController] Error fetching residence data: $e');
    }
  }

  int? _resolveResidenceIdForSingleResidence() {
    if (selectedResidence.value != null) return selectedResidence.value!.id;
    if (residences.isNotEmpty) return residences.first.id;

    final existing = residenceData.value?['id'];
    if (existing is int) return existing;
    final parsed = int.tryParse(existing?.toString() ?? '');
    if (parsed != null) return parsed;

    final rid = currentUser.value?.residenceId;
    if (rid != null && rid.isNotEmpty) {
      return int.tryParse(rid);
    }

    final userData = _storageService.getUserData();
    final stored = userData?['residence_id'] ?? userData?['unit_id'];
    if (stored is int) return stored;
    return int.tryParse(stored?.toString() ?? '');
  }

  void _storeResidenceAdminFromData(Map<String, dynamic> data) {
    final admin = data['admin'];
    if (admin is! Map) {
      residenceAdminId.value = null;
      residenceAdminName.value = null;
      print('⚠️ [HomeController] single_residence has no admin object');
      return;
    }

    final rawId = admin['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    residenceAdminId.value = id != null && id > 0 ? id : null;
    residenceAdminName.value = admin['user_name']?.toString();

    print(
      '🏠 [HomeController] Stored residence admin '
      'id=${residenceAdminId.value} name=${residenceAdminName.value}',
    );
  }

  /// Ensures residence status/phases are loaded when the home tab is shown.
  void ensureHomeResidenceLoaded() {
    if (apiToken.value.isEmpty) return;

    if (residenceData.value == null) {
      if (_residenceDataFetchInProgress || _initialLoadInProgress) return;
      _residenceDataFetchInProgress = true;
      unawaited(
        fetchResidenceData().whenComplete(() {
          _residenceDataFetchInProgress = false;
        }),
      );
      return;
    }

    if (isResidenceUnderConstruction &&
        constructionPhasesFromApi.isEmpty &&
        !constructionPhasesLoading.value) {
      unawaited(fetchConstructionPhases());
    }
  }

  void _syncResidenceStatus(String? statusStr) {
    final status = UserModel.parseResidenceStatus(statusStr);
    if (status == null) return;

    final user = currentUser.value;
    if (user != null && user.residenceStatus != status) {
      currentUser.value = user.copyWith(residenceStatus: status);
    }
  }

  /// Fetch construction phases (status-with-phases) when residence is under construction.
  Future<void> fetchConstructionPhases() async {
    if (apiToken.value.isEmpty || !isResidenceUnderConstruction) return;
    final id = _resolveResidenceIdForSingleResidence();
    if (id == null) return;

    constructionPhasesLoading.value = true;
    try {
      final result = await _homeRepository.getResidenceStatusWithPhases(
        apiToken: apiToken.value,
        residenceId: id,
      );
      if (result['success'] == true && result['data'] is List) {
        constructionPhasesFromApi.value =
            (result['data'] as List).cast<ResidenceStatusPhaseModel>();
      } else {
        constructionPhasesFromApi.clear();
      }
    } catch (e) {
      print('❌ [HomeController] fetchConstructionPhases: $e');
      constructionPhasesFromApi.clear();
    } finally {
      constructionPhasesLoading.value = false;
    }
  }

  // SCREEN NAVIGATION METHODS

  /// Navigate to a screen and add to history
  void navigateToScreen(AppScreen screen, {bool addToHistory = true}) {
    final previous = currentScreen.value;
    if (addToHistory && previous != screen) {
      screenHistory.add(previous);
      // Clear forward history when navigating to a new screen
      forwardHistory.clear();
    }
    if (previous == screen) {
      currentScreen.refresh();
      return;
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

      case 'chathub':
      case 'chat_hub':
      case 'chatHub':
        navigateToScreen(AppScreen.chatHub);
        break;

      case 'groupchat':
      case 'group_chat':
        navigateToScreen(AppScreen.chat);
        break;

      case 'adminchat':
      case 'admin_chat':
        if (Get.isRegistered<PrivateChatController>()) {
          Get.delete<PrivateChatController>();
        }
        navigateToScreen(AppScreen.adminChat);
        break;

      case 'chat':
        navigateToScreen(AppScreen.chatHub);
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

  /// Handle system back button — walks [screenHistory] one step at a time.
  Future<bool> handleBackNavigation() async {
    if (screenHistory.isNotEmpty || currentScreen.value != AppScreen.home) {
      goBack();
      return false;
    }
    return true;
  }

  // Clear navigation history
  void clearHistory() {
    screenHistory.clear();
    forwardHistory.clear();
  }

  // LOGOUT
  Future<void> logout() async {
    SessionExpiryService.beginForcedSignOut();
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

      clearStateOnLogout();
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().user.value = null;
      }

      // Clear all storage regardless of API result
      await _storageService.clearAll();
      print('✅ All storage cleared');

      // Navigate to auth screen
      AuthNavigation.replaceStackWithAuth();
      print('✅ Navigated to auth screen');
    } catch (e) {
      print('❌ Error during logout: $e');
      // Even if there's an error, try to clear storage and navigate
      try {
        await _storageService.clearAll();
        AuthNavigation.replaceStackWithAuth();
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
