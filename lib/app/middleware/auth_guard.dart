import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/storage_service.dart';
import '../routes/app_routes.dart';

/// Route middleware for authenticated pages.
///
/// While a login-time 2FA challenge is pending ([StorageService.isPending2FA]),
/// every guarded route redirects to OTP verification. This closes the
/// "deep link / notification navigation into HOME while OTP is unfinished"
/// hole; splash handles the cold-start case.
///
/// Deliberately NOT applied to: SPLASH, AUTH, OTP_VERIFICATION, FIRST_LOGIN,
/// FORGOT_PASSWORD, FORGOT_CHANGE_PASSWORD — those must stay reachable while
/// unauthenticated or mid-challenge.
class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<StorageService>()) return null;

    if (Get.find<StorageService>().isPending2FA) {
      return const RouteSettings(name: AppRoutes.OTP_VERIFICATION);
    }
    return null;
  }
}
