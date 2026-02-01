// presentation/trusted_devices/controllers/trusted_devices_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/message_popup_controller.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/models/trusted_device_model.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/utils/time_formatter.dart';

class TrustedDevicesController extends GetxController {
  final ProfileRepository _profileRepository = Get.find();
  final GeocodingService _geocodingService = GeocodingService();

  // Observables
  final RxList<TrustedDeviceModel> devices = <TrustedDeviceModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingLocations = false.obs;
  final RxMap<String, String> locationCache = <String, String>{}.obs;
  final RxString errorMessage = ''.obs;
  final RxString expandedDeviceId = ''.obs; // For expandable device cards

  @override
  void onInit() {
    super.onInit();
    loadTrustedDevices();
  }

  /// Load all trusted devices
  Future<void> loadTrustedDevices() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _profileRepository.getAllTrustedDevices();

    if (result['success']) {
      devices.value = result['devices'] as List<TrustedDeviceModel>;

      // Load locations for all devices in background
      _loadLocationsForDevices();
    } else {
      errorMessage.value = result['error'] ?? 'failed_to_load_devices';
      MessagePopupController.showError(
        messageKey: 'failed_to_load_devices',
        titleKey: 'error',
      );
    }

    isLoading.value = false;
  }

  /// Load locations for all devices in background
  Future<void> _loadLocationsForDevices() async {
    isLoadingLocations.value = true;

    for (final device in devices) {
      if (device.hasLocation) {
        final cacheKey = GeocodingService.getCacheKey(device.lat!, device.lng!);

        // Skip if already in cache
        if (locationCache.containsKey(cacheKey)) {
          continue;
        }

        // Fetch location
        final location = await _geocodingService.getLocationFromCoordinates(
          device.lat!,
          device.lng!,
        );

        locationCache[cacheKey] = location;
      }
    }

    isLoadingLocations.value = false;
  }

  /// Remove/Delete a device
  Future<void> revokeDevice(TrustedDeviceModel device) async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remove Device'),
        content: Text(
          'Are you sure you want to remove "${device.deviceName}"?\n\n'
              'This device will need to verify again on next login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    // Use device_id (string) instead of id (int)
    final result = await _profileRepository.deleteUserDevice(device.deviceId.toString());

    // Close loading dialog
    Get.back();

    if (result['success']) {
      MessagePopupController.showSuccess(
        messageKey: result['message'] ?? 'device_removed_successfully',
        titleKey: 'success',
      );

      await loadTrustedDevices();
    } else {
      MessagePopupController.showError(
        messageKey: 'failed_to_remove_device',
        titleKey: 'error',
      );
    }
  }



/// Get location for a device
  String getDeviceLocation(TrustedDeviceModel device) {
    if (!device.hasLocation) {
      return 'Location not available';
    }

    final cacheKey = GeocodingService.getCacheKey(device.lat!, device.lng!);
    return locationCache[cacheKey] ?? 'Loading location...';
  }

  /// Get formatted last login time
  String getLastLoginTime(TrustedDeviceModel device) {
    if (device.lastLoginAt == null) {
      return 'Never';
    }

    return TimeFormatter.formatTimeAgo(device.lastLoginAt!);
  }

  /// Get trusted until status
  String getTrustedUntilStatus(TrustedDeviceModel device) {
    if (device.trustedUntil == null) {
      return 'Trusted indefinitely';
    }

    if (device.isTrustedValid) {
      return TimeFormatter.formatTrustedUntil(device.trustedUntil!);
    } else {
      return 'Expired';
    }
  }

  /// Revoke a device


  /// Refresh devices
  Future<void> refreshDevices() async {
    await loadTrustedDevices();
  }

  /// Get current device (if exists in list)
  TrustedDeviceModel? get currentDevice {
    // This would need to match against current device ID
    // For now, return the most recent device
    if (devices.isEmpty) return null;

    final sortedDevices = List<TrustedDeviceModel>.from(devices);
    sortedDevices.sort((a, b) {
      if (a.lastLoginAt == null) return 1;
      if (b.lastLoginAt == null) return -1;
      return b.lastLoginAt!.compareTo(a.lastLoginAt!);
    });

    return sortedDevices.first;
  }

  /// Get active devices count
  int get activeDevicesCount {
    return devices.where((d) => d.isActive && d.isTrustedValid).length;
  }

  /// Get revoked devices count
  int get revokedDevicesCount {
    return devices.where((d) => d.isRevoked).length;
  }

  /// Get expired devices count
  int get expiredDevicesCount {
    return devices.where((d) => !d.isTrustedValid && !d.isRevoked).length;
  }

  /// Filter active devices
  List<TrustedDeviceModel> get activeDevices {
    return devices.where((d) => d.isActive && d.isTrustedValid).toList();
  }

  /// Filter inactive devices (revoked or expired)
  List<TrustedDeviceModel> get inactiveDevices {
    return devices.where((d) => d.isRevoked || !d.isTrustedValid).toList();
  }
}