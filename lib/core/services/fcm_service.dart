// core/services/fcm_service.dart
// Centralized FCM service: init, token, foreground/background/terminated handling.
// Single instance (singleton); init runs once. Push processing delegated to NotificationManager.

import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'notification_manager.dart';
import '../../helpers/local_notification_service.dart';

class FcmService extends GetxService {
  FirebaseMessaging? _messaging;

  FirebaseMessaging? get messaging {
    try {
      if (_messaging == null && Firebase.apps.isNotEmpty) {
        _messaging = FirebaseMessaging.instance;
      }
      return _messaging;
    } catch (e) {
      print('❌ [FcmService] Error accessing FirebaseMessaging: $e');
      return null;
    }
  }

  String? _currentToken;
  String? get currentToken => _currentToken;

  /// Last token we sent to backend (avoid duplicate submissions)
  String? _lastSentToken;

  /// True when last sendTokenToBackend failed; triggers retry on next init or send.
  bool _pendingTokenSend = false;

  /// Prevents duplicate listener registration (init runs only once)
  bool _initialized = false;

  /// Prevents stacking of onMessage / onMessageOpenedApp listeners
  bool _listenersSetup = false;

  /// Initialize FCM: permissions, token, send to backend, setup all listeners.
  /// Safe to call multiple times; runs only once.
  Future<FcmService> init() async {
    if (_initialized) {
      print('📌 [FcmService] init skipped (already initialized)');
      return this;
    }
    _initialized = true;

    try {
      if (Firebase.apps.isEmpty) {
        print('⚠️ [FcmService] Firebase not initialized, skipping');
        return this;
      }

      await _requestPermission();
      await _getToken();
      await sendTokenToBackend();
      if (_pendingTokenSend) {
        print('🔄 [FcmService] Retrying pending token send');
        await sendTokenToBackend();
      }
      _setupTokenRefreshListener();
      _setupForegroundAndBackgroundHandlers();
      await _setIOSForegroundPresentationOptions();
    } catch (e) {
      print('❌ [FcmService] init error: $e');
    }
    return this;
  }

  /// iOS: show alert, badge, sound when app is in foreground
  Future<void> _setIOSForegroundPresentationOptions() async {
    try {
      if (!Platform.isIOS || messaging == null) return;
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('📱 [FcmService] iOS foreground presentation options set');
    } catch (e) {
      print('❌ [FcmService] iOS foreground options error: $e');
    }
  }

  /// Request notification permissions (iOS + Android 13+)
  Future<void> _requestPermission() async {
    try {
      if (kIsWeb) return;
      if (Firebase.apps.isEmpty || messaging == null) return;

      final settings = await messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      print('📱 [FcmService] Permission: ${settings.authorizationStatus}');

      if (Platform.isAndroid) {
        await Permission.notification.request();
      }
    } catch (e) {
      print('❌ [FcmService] Error requesting permission: $e');
    }
  }

  Future<String?> _getToken() async {
    try {
      if (kIsWeb || Firebase.apps.isEmpty || messaging == null) return null;
      _currentToken = await messaging!.getToken();
      print('🔑 [FcmService] Token: ${_currentToken != null ? "${_currentToken!.substring(0, 20)}..." : "null"}');
      return _currentToken;
    } catch (e) {
      print('❌ [FcmService] Error getting token: $e');
      return null;
    }
  }

  void _setupTokenRefreshListener() {
    if (Firebase.apps.isEmpty || messaging == null) return;
    messaging!.onTokenRefresh.listen((newToken) {
      print('🔄 [FcmService] Token refresh – sending to backend');
      _currentToken = newToken;
      sendTokenToBackend();
    }).onError((e) {
      print('❌ [FcmService] Token refresh error: $e');
    });
  }

  /// Send FCM token to backend. Idempotent: skips if token unchanged.
  /// Call from: app start (init), after login, onTokenRefresh.
  Future<void> sendTokenToBackend() async {
    try {
      if (Firebase.apps.isEmpty || messaging == null) return;

      final token = _currentToken ?? await _getToken();
      if (token == null || token.isEmpty) return;
      if (token == _lastSentToken) {
        print('📤 [FcmService] Token unchanged, skip send');
        return;
      }

      if (!Get.isRegistered<StorageService>()) {
        print('📤 [FcmService] StorageService not registered, skip send');
        return;
      }
      final storage = Get.find<StorageService>();
      final accessToken = storage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('📤 [FcmService] No auth token, skip sending FCM token');
        return;
      }

      if (!Get.isRegistered<ApiService>()) return;
      final api = Get.find<ApiService>();

      await api.post(ApiConstants.UPDATE_FCM_TOKEN, data: {'fcm_token': token});
      _lastSentToken = token;
      _pendingTokenSend = false;
      print('✅ [FcmService] Token sent to backend');
    } catch (e) {
      _pendingTokenSend = true;
      final err = e.toString();
      if (err.contains('404')) {
        print(
          '❌ [FcmService] POST ${ApiConstants.UPDATE_FCM_TOKEN} returned 404 — '
          'add this route on Laravel or disable FCM registration until backend is ready',
        );
      }
      print('❌ [FcmService] Error sending token to backend: $e');
    }
  }

  void _setupForegroundAndBackgroundHandlers() {
    if (_listenersSetup || Firebase.apps.isEmpty || messaging == null) return;
    _listenersSetup = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handlePushMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 [FcmService] Notification opened app');
      _onNotificationOpenedApp(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📬 [FcmService] Launched from notification (terminated)');
        _onNotificationOpenedApp(message);
      }
    });
  }

  /// Handle incoming push (foreground). Show local notification and delegate to NotificationManager.
  void handlePushMessage(RemoteMessage message) {
    try {
      LocalNotificationService.showNotification(message);
    } catch (e) {
      print('❌ [FcmService] Local notification error: $e');
    }

    final data = message.data;
    final messageId = message.messageId;
    print('📨 [FcmService] Foreground push – data keys: ${data.isNotEmpty ? data.keys.join(", ") : "none"}');
    _dispatchToNotificationManager(data, messageId: messageId);
  }

  void _onNotificationOpenedApp(RemoteMessage message) {
    final data = message.data;
    final messageId = message.messageId;
    _dispatchToNotificationManager(data, messageId: messageId);
    if (data.isNotEmpty && Get.isRegistered<NotificationManager>()) {
      Get.find<NotificationManager>().handleNotificationNavigation(data);
    }
  }

  /// Safely pass payload and optional messageId to NotificationManager (never call controllers from here).
  void _dispatchToNotificationManager(Map<String, dynamic>? data, {String? messageId}) {
    try {
      if (!Get.isRegistered<NotificationManager>()) {
        print('⚠️ [FcmService] NotificationManager not registered');
        return;
      }
      Get.find<NotificationManager>().handlePushPayload(data, messageId: messageId);
    } catch (e) {
      print('❌ [FcmService] Dispatch to NotificationManager error: $e');
    }
  }

  /// Request notification permissions (can be called again if needed)
  Future<void> requestNotificationPermission() async {
    await _requestPermission();
  }

  /// Public: get device token (e.g. for login payload)
  Future<String?> getDeviceToken() async {
    if (_currentToken != null) return _currentToken;
    return await _getToken();
  }

  /// Delete token (e.g. on logout)
  Future<void> deleteToken() async {
    try {
      if (Firebase.apps.isEmpty || messaging == null) return;
      await messaging!.deleteToken();
      _currentToken = null;
      _lastSentToken = null;
      print('🗑️ [FcmService] Token deleted');
    } catch (e) {
      print('❌ [FcmService] Error deleting token: $e');
    }
  }
}
