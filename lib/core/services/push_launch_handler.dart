import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../constants/storage_keys.dart';
import 'notification_manager.dart';
import 'storage_service.dart';
import 'package:casazero/core/logging/diagnostic_logger.dart';

/// Captures FCM notification-open events as early as possible (Android + iOS).
///
/// Cold starts from the tray/lock screen require [getInitialMessage] soon after
/// Firebase init — and **before** [flutter_local_notifications] launch-details
/// on iOS (otherwise FCM can lose the launch notification).
///
/// Platform open paths:
/// - **Android OS FCM banner** → getInitialMessage / onMessageOpenedApp
/// - **iOS APNs/FCM banner** → same (via FlutterAppDelegate)
/// - **Local banner** (Android foreground / data-only) → LocalNotificationService
class PushLaunchHandler {
  PushLaunchHandler._();

  static bool _installed = false;

  /// Install once, immediately after [Firebase.initializeApp].
  static Future<void> install() async {
    if (_installed) return;
    if (Firebase.apps.isEmpty) return;
    _installed = true;

    final platform = defaultTargetPlatform.name;
    DiagnosticLogger.instance.debug('📬 [PushLaunchHandler] Installing on $platform');

    // Terminated → tray/lock-screen tap (must run early; before local launch details).
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        DiagnosticLogger.instance.debug(
          '📬 [PushLaunchHandler] getInitialMessage '
          'keys=${initial.data.keys.join(",")} '
          'hasNotification=${initial.notification != null}',
        );
        _handleOpened(initial, source: 'getInitialMessage');
      } else {
        DiagnosticLogger.instance.error('📬 [PushLaunchHandler] getInitialMessage: null');
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [PushLaunchHandler] getInitialMessage error: $e');
    }

    // Background → tray tap (both Android and iOS).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      DiagnosticLogger.instance.debug(
        '📬 [PushLaunchHandler] onMessageOpenedApp '
        'keys=${message.data.keys.join(",")}',
      );
      _handleOpened(message, source: 'onMessageOpenedApp');
    });
  }

  static Map<String, dynamic> dataFromRemoteMessage(RemoteMessage message) {
    final data = <String, dynamic>{};

    void merge(Map input) {
      input.forEach((key, value) {
        if (value == null) return;
        data[key.toString()] = value;
      });
    }

    merge(message.data);

    // Nested JSON "data" string (some Laravel FCM builders).
    final nested = message.data['data'];
    if (nested is String && nested.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(nested);
        if (decoded is Map) merge(decoded);
      } catch (_) {}
    } else if (nested is Map) {
      merge(nested);
    }

    if (message.notification != null) {
      final notif = message.notification!;
      if (notif.title != null && notif.title!.isNotEmpty) {
        data['title'] ??= notif.title;
        data['notification_title'] ??= notif.title;
      }
      if (notif.body != null && notif.body!.isNotEmpty) {
        data['body'] ??= notif.body;
        data['description'] ??= notif.body;
        data['content'] ??= notif.body;
      }
    }

    return data;
  }

  static void _handleOpened(
    RemoteMessage message, {
    required String source,
  }) {
    final data = dataFromRemoteMessage(message);
    DiagnosticLogger.instance.debug(
      '🧭 [PushLaunchHandler] opened via $source '
      'type=${data['type'] ?? data['notification_type'] ?? "none"} '
      'reference_id=${data['reference_id'] ?? "none"} '
      'keys=${data.keys.join(",")}',
    );

    if (data.isEmpty) {
      DiagnosticLogger.instance.warning(
        '⚠️ [PushLaunchHandler] Opened notification has empty data — '
        'will rely on local-notification payload / feed enrichment if available',
      );
      _dispatchOrRetry(<String, dynamic>{}, messageId: message.messageId);
      return;
    }

    _persist(data);
    _dispatchOrRetry(data, messageId: message.messageId);
  }

  static void _dispatchOrRetry(
    Map<String, dynamic> data, {
    String? messageId,
  }) {
    void attempt() {
      if (!Get.isRegistered<NotificationManager>()) return;
      final manager = Get.find<NotificationManager>();
      if (data.isNotEmpty) {
        // Refresh feed/unread the same way a foreground push would.
        manager.handlePushPayload(data, messageId: messageId);
        manager.handleNotificationNavigation(data);
      }
      manager.flushPendingNavigation();
    }

    attempt();
    // Splash / InitialBinding / HOME may not be ready yet (both platforms).
    Future<void>.delayed(const Duration(milliseconds: 800), attempt);
    Future<void>.delayed(const Duration(milliseconds: 2500), attempt);
    Future<void>.delayed(const Duration(milliseconds: 4500), attempt);
    Future<void>.delayed(const Duration(milliseconds: 7000), attempt);
  }

  static void _persist(Map<String, dynamic> data) {
    try {
      if (Get.isRegistered<StorageService>()) {
        unawaited(
          Get.find<StorageService>().savePendingNotificationNav(data),
        );
        return;
      }
      final box = GetStorage();
      unawaited(box.write(StorageKeys.PENDING_NOTIFICATION_NAV, data));
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [PushLaunchHandler] persist error: $e');
    }
  }
}
