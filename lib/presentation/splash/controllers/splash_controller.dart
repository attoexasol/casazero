// lib/presentation/splash/controllers/splash_controller.dart
// UPDATED VERSION with auto-login functionality

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/storage_service.dart';

class SplashController extends GetxController {
  final StorageService _storageService = Get.find();
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    print('🟢 SplashController: onInit called');
    _startSplashTimer();
  }

  void _startSplashTimer() {
    print('🟢 SplashController: Starting 3.5 second timer');

    // Auto-transition after 3.5 seconds
    _timer = Timer(const Duration(milliseconds: 3500), () {
      print('🟢 SplashController: Timer completed, checking authentication');
      _checkAuthenticationAndNavigate();
    });
  }

  /// Check if user is already authenticated and navigate accordingly
  void _checkAuthenticationAndNavigate() {
    print('🔐 SplashController: Checking authentication status...');

    // Check for stored access token
    final accessToken = _storageService.getAccessToken();
    final userData = _storageService.getUserData();

    print('  - Access Token: ${accessToken != null ? "Found" : "Not found"}');
    print('  - User Data: ${userData != null ? "Found" : "Not found"}');

    if (accessToken != null && accessToken.isNotEmpty && userData != null) {
      // User is authenticated - navigate to HOME
      print('  ✅ User authenticated - navigating to HOME');
      _navigateToHome();
    } else {
      // No authentication data - navigate to AUTH
      print('  ❌ No authentication found - navigating to AUTH');
      _navigateToAuth();
    }
  }

  void _navigateToHome() {
    print('🟢 SplashController: Attempting navigation to: ${AppRoutes.HOME}');

    try {
      // Use Get.offAllNamed to clear splash from navigation stack
      Get.offAllNamed(AppRoutes.HOME);
      print('✅ SplashController: Navigation to HOME successful');
    } catch (e) {
      print('❌ SplashController: Navigation to HOME failed: $e');
      // Fallback - navigate to AUTH if HOME navigation fails
      _navigateToAuth();
    }
  }

  void _navigateToAuth() {
    print('🟢 SplashController: Attempting navigation to: ${AppRoutes.AUTH}');

    try {
      // Use Get.offAllNamed to clear splash from navigation stack
      Get.offAllNamed(AppRoutes.AUTH);
      print('✅ SplashController: Navigation to AUTH successful');
    } catch (e) {
      print('❌ SplashController: Navigation to AUTH failed: $e');
      // Fallback navigation
      Get.offAll(() => const SizedBox(),
        routeName: AppRoutes.AUTH,
      );
    }
  }

  @override
  void onClose() {
    print('🟢 SplashController: onClose called, cancelling timer');
    _timer?.cancel();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    print('🟢 SplashController: onReady called');
  }
}