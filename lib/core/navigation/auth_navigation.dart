import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/localization/locale_controller.dart';

/// Navigates to the login screen with a fresh [AuthController] instance.
class AuthNavigation {
  AuthNavigation._();

  static void replaceStackWithAuth() {
    FocusManager.instance.primaryFocus?.unfocus();
    // Navigate first so the AUTH route binding can replace the controller
    // before any widgets bind to it. Deleting the controller here (before
    // navigation) disposes TextEditingControllers while locale reloads can
    // still trigger rebuilds that reference them.
    Get.offAllNamed(AppRoutes.AUTH);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<LocaleController>()) {
        Get.find<LocaleController>().reloadFromStorage();
      }
    });
  }
}
