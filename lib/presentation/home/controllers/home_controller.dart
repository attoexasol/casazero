import 'package:casazero/presentation/documents/controllers/documents_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/feed_item_model.dart';
import '../../../data/models/construction_phase_model.dart';
import '../../../data/models/residence_model.dart';
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

  // Residence management
  final residences = <ResidenceModel>[].obs;
  final selectedResidence = Rx<ResidenceModel?>(null);
  final isLoadingResidences = false.obs;

  // Screen navigation
  final currentScreen = AppScreen.home.obs;
  final screenHistory = <AppScreen>[].obs;

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
    fetchResidences(); // Fetch residences on init
  }

  //   @override
  // void onInit() {
  //   super.onInit();

  //   fetchDocumentCategories();

  //   // WAIT for HomeController to finish loading residences
  //   ever(Get.find<HomeController>().selectedResidence, (residence) {
  //     if (residence != null) {
  //       fetchDocuments();
  //     }
  //   });
  // }

  @override
  void onReady() {
    super.onReady();
    fetchHomeData();
  }

  Future<void> _loadUserData() async {
    final userData = _storageService.getUserData();
    if (userData != null) {
      currentUser.value = UserModel.fromJson(userData);
    }
  }

  /// Fetch user residences from API
  Future<void> fetchResidences() async {
    try {
      isLoadingResidences.value = true;

      final result = await _homeRepository.getUserResidences();

      if (result['success'] == true) {
        residences.value = result['data'] as List<ResidenceModel>;

        // Auto-select first residence if available and none selected
        if (residences.isNotEmpty && selectedResidence.value == null) {
          selectedResidence.value = residences.first;
          print(
            'âœ… Auto-selected residence: ${selectedResidence.value?.residenceName}',
          );

          Get.find<DocumentsController>().fetchDocuments();
        }

        print('âœ… Loaded ${residences.length} residences');
      } else {
        print('âŒ Failed to fetch residences: ${result['error']}');
        Get.snackbar(
          'error'.tr,
          result['error'] ?? 'Failed to load residences',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[700],
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('âŒ Error fetching residences: $e');
    } finally {
      isLoadingResidences.value = false;
    }
  }

  /// Select a residence
  void selectResidence(ResidenceModel residence) {
    selectedResidence.value = residence;
    print('Selected residence: ${residence.residenceName}');
    // Optionally refresh data for the selected residence
    // fetchHomeData();
    Get.find<DocumentsController>().fetchDocuments();
  }

  /// Show residence selector dialog
  void showResidenceSelector(BuildContext context) {
    if (residences.isEmpty) {
      Get.snackbar(
        'info'.tr,
        'No residences available',
        snackPosition: SnackPosition.BOTTOM,
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
      Get.snackbar(
        'Error',
        'Failed to load home data: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> refreshData() async {
    await fetchHomeData();
  }

  // SCREEN NAVIGATION METHODS

  /// Navigate to a screen and add to history
  void navigateToScreen(AppScreen screen, {bool addToHistory = true}) {
    if (addToHistory && currentScreen.value != screen) {
      screenHistory.add(currentScreen.value);
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
      case 'trusted-devices':
      case 'trusted_devices':
      case 'trusteddevices':
        navigateToScreen(AppScreen.trustedDevices);
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
      currentScreen.value = previousScreen;
    } else {
      // If no history, go to home
      currentScreen.value = AppScreen.home;
    }
  }

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
  }

  // LOGOUT
  Future<void> logout() async {
    try {
      await _storageService.clearAll();
      Get.offAllNamed(AppRoutes.AUTH);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
