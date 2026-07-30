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
import 'push_launch_handler.dart';
import 'storage_service.dart';
import '../../data/repositories/notification_repository.dart';
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

  /// De-duplicates concurrent token acquisitions (init warm-up vs login).
  Future<String?>? _tokenFetchInFlight;

  /// Exponential backoff steps shared by APNs and FCM token retries.
  static const List<Duration> _retryBackoff = <Duration>[
    Duration(milliseconds: 250),
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 3),
  ];

  /// Max time spent waiting for the iOS APNs token before giving up.
  static const Duration _apnsWaitBudget = Duration(seconds: 10);

  /// Max time [getDeviceToken] blocks a caller (e.g. the login request).
  static const Duration _tokenWaitBudget = Duration(seconds: 10);

  /// Max time the non-blocking post-auth warm-up keeps retrying.
  static const Duration _authWarmUpBudget = Duration(seconds: 15);

  static String _mask(String token) => token.length <= 12
      ? '***(${token.length})'
      : '${token.substring(0, 12)}…(${token.length})';

  static Duration _backoffFor(int attempt) {
    final index = attempt - 1;
    if (index < 0) return _retryBackoff.first;
    if (index >= _retryBackoff.length) return _retryBackoff.last;
    return _retryBackoff[index];
  }

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
      // Token acquisition can wait on the iOS APNs handshake; run it in the
      // background so listener/presentation setup below is never delayed.
      unawaited(_warmUpToken(budget: _authWarmUpBudget, reason: 'init'));
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
  /// When a non-empty token is available and the user has an API token,
  /// also syncs it to Laravel via POST /update-fcm-token (non-blocking).
  ///
  /// Non-blocking by default: permission is awaited (fast) while token
  /// acquisition is warmed in the background, so splash/OTP navigation timing
  /// is unchanged even when iOS is still waiting on APNs. Pass
  /// [waitForToken] when the caller genuinely needs the value.
  Future<String?> registerAfterAuth({
    bool waitForToken = false,
    Duration budget = _authWarmUpBudget,
  }) async {
    if (Firebase.apps.isEmpty) {
      print('⚠️ [FcmService] registerAfterAuth skipped — Firebase not initialized');
      return null;
    }

    print(
      '🔄 [FcmService] registerAfterAuth — permission + token '
      '(waitForToken=$waitForToken, budget=${budget.inSeconds}s)',
    );
    await _requestPermission();

    if (waitForToken) {
      final token = await getDeviceToken(budget: budget);
      if (token != null && token.isNotEmpty) {
        unawaited(_syncFcmTokenWithBackend(token));
      }
      return token;
    }

    final cached = _currentToken;
    if (cached != null && cached.isNotEmpty) {
      print('✅ [FcmService] registerAfterAuth — cached token ${_mask(cached)}');
      unawaited(_syncFcmTokenWithBackend(cached));
      // Warm local cache; skip second sync for the same cached value.
      unawaited(
        _warmUpToken(
          budget: budget,
          reason: 'registerAfterAuth',
          syncWithBackend: false,
        ),
      );
    } else {
      unawaited(
        _warmUpToken(
          budget: budget,
          reason: 'registerAfterAuth',
          syncWithBackend: true,
        ),
      );
    }
    return (cached != null && cached.isNotEmpty) ? cached : null;
  }

  /// Background token acquisition. Never blocks navigation or login.
  Future<void> _warmUpToken({
    required Duration budget,
    required String reason,
    bool syncWithBackend = false,
  }) async {
    final token = await getDeviceToken(budget: budget);
    if (token == null) {
      print(
        '⚠️ [FcmService] Token warm-up ($reason) finished without a token — '
        'will retry on next auth event / permission grant',
      );
    } else {
      print('✅ [FcmService] Token warm-up ($reason) ready: ${_mask(token)}');
      if (syncWithBackend) {
        unawaited(_syncFcmTokenWithBackend(token));
      }
    }
  }

  /// Fire-and-forget Laravel FCM registration. Keeps local cache on failure.
  Future<void> _syncFcmTokenWithBackend(String fcmToken) async {
    final trimmed = fcmToken.trim();
    if (trimmed.isEmpty) return;

    try {
      if (!Get.isRegistered<StorageService>()) return;
      final apiToken = Get.find<StorageService>().getAccessToken();
      if (apiToken == null || apiToken.isEmpty) {
        print(
          '⚠️ [FcmService] Skip backend FCM sync — user not authenticated',
        );
        return;
      }

      if (!Get.isRegistered<NotificationRepository>()) {
        print(
          '⚠️ [FcmService] Skip backend FCM sync — NotificationRepository missing',
        );
        return;
      }

      await Get.find<NotificationRepository>().updateFcmToken(trimmed);
    } catch (e) {
      // Local token is intentionally kept; next registerAfterAuth / refresh retries.
      print('❌ [FcmService] Backend FCM sync error (local token kept): $e');
    }
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

    await _warmUpToken(budget: _authWarmUpBudget, reason: 'permission-granted');
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

  /// iOS: show system alert/badge/sound in foreground when FCM includes a
  /// `notification` block. Local banners are skipped in that case (Phase 7).
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

  /// iOS only: poll for the APNs device token with exponential backoff.
  ///
  /// `FirebaseMessaging.getToken()` throws `apns-token-not-set` when APNs has
  /// not completed its handshake, so it must never be called before this
  /// resolves. Returns null when the budget expires.
  Future<String?> _waitForApnsToken({required Duration budget}) async {
    if (kIsWeb || !Platform.isIOS || messaging == null) return null;

    final deadline = DateTime.now().add(budget);
    var attempt = 0;

    while (true) {
      attempt++;
      String? apnsToken;
      try {
        apnsToken = await messaging!.getAPNSToken();
      } catch (e) {
        print('❌ [FcmService][APNs] attempt $attempt — getAPNSToken error: $e');
      }

      if (apnsToken != null && apnsToken.isNotEmpty) {
        print(
          '✅ [FcmService][APNs] token available after $attempt attempt(s): '
          '${_mask(apnsToken)}',
        );
        return apnsToken;
      }

      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        print(
          '⏱️ [FcmService][APNs] no token after $attempt attempt(s) / '
          '${budget.inSeconds}s — skipping getToken() to avoid '
          'apns-token-not-set. Check Push Notifications capability, '
          'aps-environment entitlement, and APNs key in Firebase.',
        );
        return null;
      }

      final backoff = _backoffFor(attempt);
      final wait = backoff > remaining ? remaining : backoff;
      print(
        '🔄 [FcmService][APNs] attempt $attempt — not ready, retrying in '
        '${wait.inMilliseconds}ms (remaining ${remaining.inMilliseconds}ms)',
      );
      await Future<void>.delayed(wait);
    }
  }

  /// Fetch the latest FCM token from Firebase.
  ///
  /// iOS gates on the APNs token first. The cached value is only replaced by a
  /// non-empty token, so a transient failure never clears a working token.
  /// Concurrent callers share a single in-flight request.
  Future<String?> _refreshToken({Duration? apnsBudget}) {
    final inFlight = _tokenFetchInFlight;
    if (inFlight != null) {
      print('⏳ [FcmService] Token fetch already in flight — joining');
      return inFlight;
    }

    final future = _refreshTokenInternal(apnsBudget: apnsBudget);
    _tokenFetchInFlight = future;
    return future.whenComplete(() {
      _tokenFetchInFlight = null;
    });
  }

  Future<String?> _refreshTokenInternal({Duration? apnsBudget}) async {
    if (kIsWeb || Firebase.apps.isEmpty || messaging == null) return null;

    if (Platform.isIOS) {
      final apnsToken = await _waitForApnsToken(
        budget: apnsBudget ?? _apnsWaitBudget,
      );
      if (apnsToken == null || apnsToken.isEmpty) {
        print(
          '⚠️ [FcmService] iOS — APNs token unavailable; not requesting FCM token',
        );
        return null;
      }
    }

    try {
      final token = await messaging!.getToken();
      if (token == null || token.trim().isEmpty) {
        print(
          '🔑 [FcmService] getToken() returned null/empty — keeping cached '
          'token (${_currentToken == null ? "none" : "present"})',
        );
        return null;
      }

      final changed = _currentToken != token;
      _currentToken = token;
      print(
        '🔑 [FcmService] FCM token ${changed ? "updated" : "unchanged"}: '
        '${_mask(token)}',
      );
      return token;
    } catch (e) {
      print('❌ [FcmService] Error getting token: $e');
      return null;
    }
  }

  void _setupTokenRefreshListener() {
    if (Firebase.apps.isEmpty || messaging == null) return;
    messaging!.onTokenRefresh.listen((newToken) {
      if (newToken.trim().isEmpty) {
        print('⚠️ [FcmService] Token refresh delivered an empty token — ignored');
        return;
      }
      print('🔄 [FcmService] Token refresh — cached ${_mask(newToken)}');
      _currentToken = newToken;
      // Fire-and-forget — never block UI; local cache already updated.
      unawaited(_syncFcmTokenWithBackend(newToken));
    }).onError((e) {
      print('❌ [FcmService] Token refresh error: $e');
    });
  }

  void _setupForegroundAndBackgroundHandlers() {
    if (_listenersSetup || Firebase.apps.isEmpty || messaging == null) return;
    _listenersSetup = true;

    // Foreground only — tray/lock-screen opens are handled by PushLaunchHandler
    // (installed early in main) so getInitialMessage is not missed.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      unawaited(handlePushMessage(message));
    });
  }

  /// Handle incoming push (foreground). Show local notification and delegate to NotificationManager.
  /// iOS: skip local banner when FCM already has a `notification` block (system presents it).
  /// Android: always show local (OS does not show FCM banners while foreground).
  Future<void> handlePushMessage(RemoteMessage message) async {
    try {
      final skipLocalOnIos =
          !kIsWeb && Platform.isIOS && message.notification != null;
      if (skipLocalOnIos) {
        print(
          '📨 [FcmService] iOS foreground — using system presentation '
          '(skipping local duplicate)',
        );
      } else {
        await LocalNotificationService.showNotification(message);
      }
    } catch (e) {
      print('❌ [FcmService] Local notification error: $e');
    }

    final data = PushLaunchHandler.dataFromRemoteMessage(message);
    final messageId = message.messageId;
    print(
      '📨 [FcmService] Foreground push – data keys: ${data.isNotEmpty ? data.keys.join(", ") : "none"}',
    );
    _dispatchToNotificationManager(data, messageId: messageId);
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

  /// Public: get device token (e.g. for the login payload).
  ///
  /// Retries with exponential backoff until [budget] expires. On iOS each
  /// attempt first waits for the APNs token. Returns a non-empty token or
  /// null — never an empty string.
  Future<String?> getDeviceToken({Duration budget = _tokenWaitBudget}) async {
    final cached = _currentToken;
    if (cached != null && cached.isNotEmpty) {
      print('🔑 [FcmService] Device token served from cache: ${_mask(cached)}');
      return cached;
    }

    final deadline = DateTime.now().add(budget);
    var attempt = 0;

    while (DateTime.now().isBefore(deadline)) {
      attempt++;
      final remaining = deadline.difference(DateTime.now());
      final token = await _refreshToken(apnsBudget: remaining);
      if (token != null && token.isNotEmpty) {
        print(
          '✅ [FcmService] Device token resolved on attempt $attempt: '
          '${_mask(token)}',
        );
        return token;
      }

      final left = deadline.difference(DateTime.now());
      if (left <= Duration.zero) break;

      final backoff = _backoffFor(attempt);
      final wait = backoff > left ? left : backoff;
      print(
        '🔄 [FcmService] Device token not ready (attempt $attempt) — '
        'retrying in ${wait.inMilliseconds}ms (remaining ${left.inMilliseconds}ms)',
      );
      await Future<void>.delayed(wait);
    }

    print(
      '⚠️ [FcmService] Device token unavailable after ${budget.inSeconds}s '
      '($attempt attempt(s)) — returning null (never an empty token)',
    );
    return null;
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
