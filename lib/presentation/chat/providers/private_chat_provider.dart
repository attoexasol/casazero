import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/services/presence_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/firebase_error_handler.dart';
import '../../home/controllers/home_controller.dart';

/// Resolves residence admin from [HomeController] (stored via single_residence API).
class PrivateChatProvider extends GetxController {
  PresenceService get _presenceService => Get.find<PresenceService>();
  StorageService get _storageService => Get.find<StorageService>();

  final RxBool adminOnline = false.obs;
  final RxBool isContextReady = false.obs;

  int? _residentId;
  int? _adminId;
  int? _residenceId;
  String _adminName = 'Administrator Support';
  String _residenceName = '';

  int? _presenceAdminId;
  StreamSubscription<bool>? _presenceSub;

  int? get residentId => _residentId;
  int? get adminId => _adminId;
  int? get residenceId => _residenceId;
  String get adminName => _adminName;
  String get residenceName => _residenceName;

  /// Uses admin id stored on [HomeController] after GET /single_residence/{id}.
  bool prepareChat() {
    final residentId = _resolveResidentId();
    final adminId = _resolveAdminId();
    final residenceId = _resolveResidenceId();
    final residenceName = _resolveResidenceName();
    final adminName = _resolveAdminName();

    debugPrint('[PrivateChat] Resident ID: ${residentId ?? '-'}');
    debugPrint('[PrivateChat] Residence ID: ${residenceId ?? '-'}');
    debugPrint('[PrivateChat] Admin ID: ${adminId ?? '-'}');

    if (residentId == null) {
      isContextReady.value = false;
      return false;
    }

    _residentId = residentId;
    _presenceService.bindLifecycle(residentId);

    if (residenceId == null || adminId == null || adminId <= 0) {
      isContextReady.value = false;
      return false;
    }

    _adminId = adminId;
    _residenceId = residenceId;
    _residenceName = residenceName;
    _adminName = adminName;
    isContextReady.value = true;

    _watchAdminPresence(adminId);
    return true;
  }

  int? _resolveResidentId() {
    if (Get.isRegistered<HomeController>()) {
      final id = Get.find<HomeController>().currentUser.value?.id;
      if (id != null && id > 0) return id;
    }
    final raw = _storageService.getUserData()?['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  int? _resolveResidenceId() {
    if (!Get.isRegistered<HomeController>()) return null;
    final home = Get.find<HomeController>();

    final dataId = home.residenceData.value?['id'];
    if (dataId is int) return dataId;
    final parsedDataId = int.tryParse(dataId?.toString() ?? '');
    if (parsedDataId != null) return parsedDataId;

    if (home.selectedResidence.value != null) {
      return home.selectedResidence.value!.id;
    }
    if (home.residences.isNotEmpty) return home.residences.first.id;

    final rid = home.currentUser.value?.residenceId;
    if (rid != null && rid.isNotEmpty) return int.tryParse(rid);

    return null;
  }

  String _resolveResidenceName() {
    if (!Get.isRegistered<HomeController>()) return '';
    final home = Get.find<HomeController>();
    return home.residenceData.value?['residence_name']?.toString() ??
        home.selectedResidence.value?.residenceName ??
        '';
  }

  int? _resolveAdminId() {
    if (!Get.isRegistered<HomeController>()) return null;
    final home = Get.find<HomeController>();

    final stored = home.residenceAdminId.value;
    if (stored != null && stored > 0) return stored;

    final admin = home.residenceData.value?['admin'];
    if (admin is Map) {
      final rawId = admin['id'];
      if (rawId is int && rawId > 0) return rawId;
      final parsed = int.tryParse(rawId?.toString() ?? '');
      if (parsed != null && parsed > 0) return parsed;
    }

    return null;
  }

  String _resolveAdminName() {
    if (!Get.isRegistered<HomeController>()) return 'Administrator Support';
    final home = Get.find<HomeController>();

    final stored = home.residenceAdminName.value?.trim();
    if (stored != null && stored.isNotEmpty) return stored;

    final admin = home.residenceData.value?['admin'];
    if (admin is Map) {
      final name = admin['user_name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }

    return 'Administrator Support';
  }

  void _watchAdminPresence(int adminId) {
    if (_presenceAdminId == adminId) return;
    _presenceAdminId = adminId;
    _presenceSub?.cancel();
    _presenceSub = _presenceService.streamOnlineStatus(adminId).listen(
      (online) => adminOnline.value = online,
      onError: (Object error) {
        FirebaseErrorHandler.log(
          tag: 'PresenceService',
          error: error,
          firestorePath: 'presence/${PresenceService.documentIdFor(adminId)}',
          userId: adminId.toString(),
        );
        adminOnline.value = false;
      },
      cancelOnError: false,
    );
  }

  @override
  void onClose() {
    _presenceSub?.cancel();
    super.onClose();
  }
}
