import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';

/// Navigates to the login screen with a fresh [AuthController] instance.
class AuthNavigation {
  AuthNavigation._();

  static bool _navigatingToAuth = false;

  static void replaceStackWithAuth() {
    if (_navigatingToAuth || Get.currentRoute == AppRoutes.AUTH) {
      return;
    }

    _navigatingToAuth = true;
    FocusManager.instance.primaryFocus?.unfocus();
    Get.offAllNamed(AppRoutes.AUTH);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _navigatingToAuth = false;
    });
  }
}
