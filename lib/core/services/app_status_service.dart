import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/repositories/notification_repository.dart';

/// Reports foreground/background lifecycle to Laravel so push delivery can be gated.
class AppStatusService extends GetxService with WidgetsBindingObserver {
  static const String _foreground = 'foreground';
  static const String _background = 'background';

  NotificationRepository? _repository;
  String? _lastReportedStatus;
  bool _observerAttached = false;

  @override
  void onInit() {
    super.onInit();
    _attachObserver();
    unawaited(_reportStatus(_foreground));
  }

  @override
  void onClose() {
    _detachObserver();
    super.onClose();
  }

  void _attachObserver() {
    if (_observerAttached) return;
    WidgetsBinding.instance.addObserver(this);
    _observerAttached = true;
  }

  void _detachObserver() {
    if (!_observerAttached) return;
    WidgetsBinding.instance.removeObserver(this);
    _observerAttached = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_reportStatus(_foreground));
        break;
      case AppLifecycleState.paused:
        unawaited(_reportStatus(_background));
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _reportStatus(String status) async {
    if (_lastReportedStatus == status) return;

    try {
      _repository ??= Get.find<NotificationRepository>();
      await _repository!.updateAppStatus(appStatus: status);
      _lastReportedStatus = status;
    } catch (e) {
      debugPrint('[AppStatusService] Failed to update app status: $e');
    }
  }
}
