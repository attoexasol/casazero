import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';

/// Navigates to the login screen with a fresh [AuthController] instance.
class AuthNavigation {
  AuthNavigation._();

  static bool _navigatingToAuth = false;

  static void replaceStackWithAuth() {
    final alreadyOnAuth = Get.currentRoute == AppRoutes.AUTH;
    if (_navigatingToAuth || alreadyOnAuth) {
      return;
    }

    _navigatingToAuth = true;
    FocusManager.instance.primaryFocus?.unfocus();
    Get.offAllNamed(AppRoutes.AUTH);
    // Keep the guard for more than one frame — splash + session-expiry can
    // both request AUTH in the same event loop turn after async gaps.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _navigatingToAuth = false;
      });
    });
  }
}
