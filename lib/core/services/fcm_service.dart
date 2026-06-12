// core/services/fcm_service.dart
// Centralized FCM service: init, token, foreground/background/terminated handling.
// Backend token registration uses fcm_token on POST /user/login only.

import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'notification_manager.dart';
import '../../helpers/local_notification_service.dart';

class FcmService extends GetxService with WidgetsBindingObserver {
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

  /// Prevents duplicate listener registration (init runs only once)
  bool _initialized = false;

  /// Prevents stacking of onMessage / onMessageOpenedApp listeners
  bool _listenersSetup = false;

  /// Tracks permission state to detect grant-after-deny on app resume
  bool _lastNotificationPermissionGranted = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onAppResumed());
    }
  }

  /// Initialize FCM: permissions, local token cache, push listeners.
  /// Safe to call multiple times; core setup runs only once.
  Future<FcmService> init() async {
    if (Firebase.apps.isEmpty) {
      print('⚠️ [FcmService] Firebase not initialized, skipping init');
      return this;
    }

    if (_initialized) {
      print('📌 [FcmService] init skipped (already initialized)');
      await registerAfterAuth();
      return this;
    }
    _initialized = true;

    try {
      await _requestPermission();
      await _refreshToken();
      _setupTokenRefreshListener();
      _setupForegroundAndBackgroundHandlers();
      await _setIOSForegroundPresentationOptions();
      print('✅ [FcmService] Initialization complete');
    } catch (e) {
      print('❌ [FcmService] init error: $e');
    }
    return this;
  }

  /// Refresh local FCM token after auth (login, OTP, splash session restore).
  /// Backend registration happens via fcm_token on POST /user/login.
  Future<void> registerAfterAuth() async {
    if (Firebase.apps.isEmpty) {
      print('⚠️ [FcmService] registerAfterAuth skipped — Firebase not initialized');
      return;
    }

    print('🔄 [FcmService] registerAfterAuth — refreshing local token');
    await _requestPermission();
    await _refreshToken();
  }

  /// When notification permission is granted in Settings, refresh local token.
  Future<void> _onAppResumed() async {
    if (Firebase.apps.isEmpty || kIsWeb) return;

    final granted = await _isNotificationPermissionGranted();
    final permissionChanged =
        granted && !_lastNotificationPermissionGranted;

    if (permissionChanged) {
      print(
        '📱 [FcmService] Notification permission granted after resume — refreshing token',
      );
    }

    _lastNotificationPermissionGranted = granted;

    if (!permissionChanged) return;

    await _refreshToken();
  }

  Future<bool> _isNotificationPermissionGranted() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        return status.isGranted;
      }
      if (Platform.isIOS && messaging != null) {
        final settings = await messaging!.getNotificationSettings();
        final status = settings.authorizationStatus;
        return status == AuthorizationStatus.authorized ||
            status == AuthorizationStatus.provisional;
      }
    } catch (e) {
      print('❌ [FcmService] Error checking notification permission: $e');
    }
    return false;
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
        final androidStatus = await Permission.notification.request();
        print('📱 [FcmService] Android notification permission: $androidStatus');
      }

      _lastNotificationPermissionGranted =
          await _isNotificationPermissionGranted();
    } catch (e) {
      print('❌ [FcmService] Error requesting permission: $e');
    }
  }

  /// Fetch the latest FCM token from Firebase (always refreshes cached value).
  Future<String?> _refreshToken() async {
    try {
      if (kIsWeb || Firebase.apps.isEmpty || messaging == null) return null;
      _currentToken = await messaging!.getToken();
      if (_currentToken != null && _currentToken!.isNotEmpty) {
        print(
          '🔑 [FcmService] Token generated: ${_currentToken!.substring(0, 20)}...',
        );
      } else {
        print('🔑 [FcmService] Token generated: null/empty');
      }
      return _currentToken;
    } catch (e) {
      print('❌ [FcmService] Error getting token: $e');
      return null;
    }
  }

  void _setupTokenRefreshListener() {
    if (Firebase.apps.isEmpty || messaging == null) return;
    messaging!.onTokenRefresh.listen((newToken) {
      print('🔄 [FcmService] Token refresh — new local token cached');
      _currentToken = newToken;
    }).onError((e) {
      print('❌ [FcmService] Token refresh error: $e');
    });
  }

  void _setupForegroundAndBackgroundHandlers() {
    if (_listenersSetup || Firebase.apps.isEmpty || messaging == null) return;
    _listenersSetup = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      unawaited(handlePushMessage(message));
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
  Future<void> handlePushMessage(RemoteMessage message) async {
    try {
      await LocalNotificationService.showNotification(message);
    } catch (e) {
      print('❌ [FcmService] Local notification error: $e');
    }

    final data = message.data;
    final messageId = message.messageId;
    print(
      '📨 [FcmService] Foreground push – data keys: ${data.isNotEmpty ? data.keys.join(", ") : "none"}',
    );
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

  /// Public: get device token (e.g. for login payload). Retries once after short delay if empty.
  Future<String?> getDeviceToken() async {
    if (_currentToken != null && _currentToken!.isNotEmpty) {
      return _currentToken;
    }

    var token = await _refreshToken();
    if (token == null || token.isEmpty) {
      print('🔄 [FcmService] Token empty — retrying after permission/APNs settle');
      await Future.delayed(const Duration(milliseconds: 1500));
      token = await _refreshToken();
    }
    return token;
  }

  /// Delete token (e.g. on logout)
  Future<void> deleteToken() async {
    try {
      if (Firebase.apps.isEmpty || messaging == null) return;
      await messaging!.deleteToken();
      _currentToken = null;
      print('🗑️ [FcmService] Token deleted');
    } catch (e) {
      print('❌ [FcmService] Error deleting token: $e');
    }
  }
}
