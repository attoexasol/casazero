// core/services/fcm_service.dart

import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class FcmService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _currentToken;
  String? get currentToken => _currentToken;

  /// Initialize FCM and request permissions
  Future<FcmService> init() async {
    await _requestPermission();
    await _getToken();
    _setupTokenRefreshListener();
    return this;
  }

  /// Request notification permissions (iOS + Android 13+)
  Future<void> _requestPermission() async {
    try {
      if (kIsWeb) {
        print('📱 FCM: Web platform detected, skipping native permissions');
        return;
      }

      // Request FCM permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📱 FCM Permission Status: ${settings.authorizationStatus}');

      // For Android 13+ (API 33+), also request POST_NOTIFICATIONS permission
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        print('📱 Android Notification Permission: $status');
      }
    } catch (e) {
      print('❌ Error requesting FCM permission: $e');
    }
  }

  /// Get FCM device token
  Future<String?> _getToken() async {
    try {
      if (kIsWeb) {
        print('📱 FCM: Web platform - skipping token retrieval');
        return null;
      }

      _currentToken = await _messaging.getToken();
      print('🔑 FCM Token: $_currentToken');
      return _currentToken;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Setup token refresh listener
  void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh
        .listen((newToken) {
          print('🔄 FCM Token Refreshed: $newToken');
          _currentToken = newToken;
          // TODO: Send refreshed token to backend
          _sendTokenToBackend(newToken);
        })
        .onError((error) {
          print('❌ Token refresh error: $error');
        });
  }

  /// Send token to backend (implement your API call here)
  Future<void> _sendTokenToBackend(String token) async {
    try {
      // You can implement this to update token on backend
      print('📤 Sending refreshed token to backend: $token');
      // Example: await _apiService.post('/update-fcm-token', data: {'fcm_token': token});
    } catch (e) {
      print('❌ Error sending token to backend: $e');
    }
  }

  /// Public method to get device token (for login)
  Future<String?> getDeviceToken() async {
    if (_currentToken != null) {
      return _currentToken;
    }
    return await _getToken();
  }

  /// Delete token (for logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _currentToken = null;
      print('🗑️ FCM Token deleted');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }
}
