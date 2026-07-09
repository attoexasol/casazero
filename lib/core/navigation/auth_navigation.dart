import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/localization/locale_controller.dart';
import '../../presentation/auth/controllers/auth_controller.dart';

/// Navigates to the login screen with a fresh [AuthController] instance.
class AuthNavigation {
  AuthNavigation._();

  static void replaceStackWithAuth() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (Get.isRegistered<AuthController>()) {
      Get.delete<AuthController>(force: true);
    }
    if (Get.isRegistered<LocaleController>()) {
      Get.find<LocaleController>().reloadFromStorage();
    }
    Get.offAllNamed(AppRoutes.AUTH);
  }
}
