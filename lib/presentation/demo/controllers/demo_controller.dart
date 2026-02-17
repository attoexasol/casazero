// lib/presentation/demo/controllers/demo_controller.dart

import 'package:get/get.dart';

/// Demo user role for UI state (maps to client/admin for future API).
enum DemoUserRole {
  residentClient,
  administrator,
}

/// Demo property status for UI state (maps to ResidenceStatus for future API).
enum DemoPropertyStatus {
  completed,
  underConstruction,
}

/// GetX controller for Demo Controls panel.
/// UI state only; ready for future API integration.
class DemoController extends GetxController {
  final Rx<DemoUserRole> selectedRole =
      DemoUserRole.residentClient.obs;
  final Rx<DemoPropertyStatus> selectedStatus =
      DemoPropertyStatus.completed.obs;
  final RxBool isPanelOpen = false.obs;

  void togglePanel() {
    isPanelOpen.value = !isPanelOpen.value;
  }

  void closePanel() {
    isPanelOpen.value = false;
  }

  void setRole(DemoUserRole role) {
    selectedRole.value = role;
    // Future: sync to API
  }

  void setPropertyStatus(DemoPropertyStatus status) {
    selectedStatus.value = status;
    // Future: sync to API
  }
}
