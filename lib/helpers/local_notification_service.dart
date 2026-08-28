import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/constants/storage_keys.dart';
import '../core/services/notification_manager.dart';
import '../core/services/push_launch_handler.dart';
import '../core/services/storage_service.dart';
import '../core/utils/notification_content_localizer.dart';
import 'package:casazero/core/logging/diagnostic_logger.dart';

/// Runs in a background isolate when a local notification is tapped while the
/// app process is not in the foreground. Persist payload so main isolate can flush.
@pragma('vm:entry-point')
void localNotificationTapBackground(NotificationResponse response) {
  final raw = response.payload;
  if (raw == null || raw.trim().isEmpty) return;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return;
    final map = decoded.map((key, value) => MapEntry(key.toString(), value));
    // Best-effort — GetStorage may need init in this isolate.
    // ignore: unawaited_futures
    GetStorage.init().then((_) {
      GetStorage().write(StorageKeys.PENDING_NOTIFICATION_NAV, map);
    });
  } catch (_) {}
}

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// v2: fresh high-importance channel. Android will not raise importance of an
  /// already-created channel, so popups can stay silent on the old id.
  static const String channelId = 'casazero_alerts_v2';
  static const String channelName = 'CasaZero Alerts';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    // FCM owns permission prompts on iOS. On Android 13+ we still request
    // POST_NOTIFICATIONS via the plugin so banners/popups are allowed.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: localNotificationTapBackground,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // Android 13+: without this, notifications never appear.
      try {
        final granted = await androidPlugin.requestNotificationsPermission();
        DiagnosticLogger.instance.warning(
          '📱 [LocalNotificationService] Android notification permission: $granted',
        );
      } catch (e) {
        DiagnosticLogger.instance.warning(
          '⚠️ [LocalNotificationService] Permission request skipped: $e',
        );
      }

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: 'Push and in-app alerts (heads-up enabled)',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        ),
      );
      DiagnosticLogger.instance.info('✅ [LocalNotificationService] Channel $channelId created (max)');
    }

    _initialized = true;

    // Terminated → local notification tap launch (same navigation path as FCM).
    // Must run AFTER PushLaunchHandler.getInitialMessage (see main.dart order).
    await _handleAppLaunchDetails();
  }

  /// Resolve title/body from FCM notification block or data payload,
  /// then localize ticket/support content for the active app language.
  static ({String title, String body}) resolveContent(RemoteMessage message) {
    final data = message.data;
    final pushNotification = message.notification;

    String rawTitle = '';
    String rawBody = '';

    if (pushNotification?.title != null &&
        pushNotification!.title!.trim().isNotEmpty) {
      rawTitle = pushNotification.title!.trim();
      rawBody = pushNotification.body?.trim() ?? '';
    } else {
      rawTitle = _localizedTitleFromData(data) ?? '';
      rawBody = _localizedBodyFromData(data) ?? '';
    }

    final type = _firstNonEmpty(data, const [
      'notification_type',
      'type',
      'push_type',
      'category',
    ]);

    if (rawTitle.isEmpty && rawBody.isEmpty) {
      return NotificationContentLocalizer.localize(
        type: type,
        title: NotificationContentLocalizer.translate('app_name'),
        body: NotificationContentLocalizer.translate(
          'notification_generic_description',
        ),
      );
    }

    return NotificationContentLocalizer.localize(
      type: type,
      title: rawTitle.isNotEmpty
          ? rawTitle
          : NotificationContentLocalizer.translate('app_name'),
      body: rawBody,
    );
  }

  static String? _localizedTitleFromData(Map<String, dynamic> data) {
    if (NotificationContentLocalizer.isItalian) {
      return _firstNonEmpty(data, const [
        'title_it',
        'title',
        'notification_title',
        'subject',
        'headline',
        'title_en',
      ]);
    }
    return _firstNonEmpty(data, const [
      'title_en',
      'title',
      'notification_title',
      'subject',
      'headline',
      'title_it',
    ]);
  }

  static String? _localizedBodyFromData(Map<String, dynamic> data) {
    if (NotificationContentLocalizer.isItalian) {
      return _firstNonEmpty(data, const [
        'content_it',
        'body',
        'message',
        'content',
        'subtitle',
        'notification_body',
        'text',
        'description',
        'content_en',
      ]);
    }
    return _firstNonEmpty(data, const [
      'content_en',
      'body',
      'message',
      'content',
      'subtitle',
      'notification_body',
      'text',
      'description',
      'content_it',
    ]);
  }

  static String? _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static int _notificationId(RemoteMessage message) {
    final messageId = message.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      return messageId.hashCode;
    }
    return message.hashCode;
  }

  /// Encode FCM data map for local-notification payload (tap → navigation).
  static String encodePayload(Map<String, dynamic> data) {
    try {
      final normalized = <String, dynamic>{};
      data.forEach((key, value) {
        if (value != null) normalized[key] = value.toString();
      });
      return jsonEncode(normalized);
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [LocalNotificationService] encodePayload error: $e');
      return '{}';
    }
  }

  /// Deserialize local-notification payload into a map for NotificationManager.
  static Map<String, dynamic> decodePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [LocalNotificationService] decodePayload error: $e');
    }
    return {};
  }

  static void _onNotificationTapped(NotificationResponse response) {
    DiagnosticLogger.instance.debug(
      '📬 [LocalNotificationService] Notification tapped '
      '(action=${response.actionId}, id=${response.id})',
    );
    _forwardPayloadToNavigation(response.payload);
  }

  /// Forward deserialized payload into the same navigation handler used by FCM.
  static void _forwardPayloadToNavigation(String? rawPayload) {
    final payload = decodePayload(rawPayload);
    _dispatchNavigation(payload);
  }

  static void _dispatchNavigation(Map<String, dynamic> payload) {
    if (payload.isEmpty) {
      DiagnosticLogger.instance.warning('⚠️ [LocalNotificationService] Empty tap payload — skipping');
      return;
    }

    try {
      // Persist first so login / late HOME can still deep-link.
      if (Get.isRegistered<StorageService>()) {
        unawaited(
          Get.find<StorageService>().savePendingNotificationNav(payload),
        );
      }

      if (!Get.isRegistered<NotificationManager>()) {
        DiagnosticLogger.instance.warning(
          '⚠️ [LocalNotificationService] NotificationManager not ready — '
          'payload persisted for flush',
        );
        return;
      }
      Get.find<NotificationManager>().handleNotificationNavigation(payload);
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (Get.isRegistered<NotificationManager>()) {
          Get.find<NotificationManager>().flushPendingNavigation();
        }
      });
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [LocalNotificationService] Navigation dispatch error: $e');
    }
  }

  /// Cold start from a local notification tap (data-only / foreground-shown).
  static Future<void> _handleAppLaunchDetails() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return;

      final payload = details.notificationResponse?.payload;
      if (payload == null || payload.trim().isEmpty) return;

      DiagnosticLogger.instance.debug(
        '📬 [LocalNotificationService] Launched from local notification '
        'payloadLen=${payload.length}',
      );

      final decoded = decodePayload(payload);
      if (decoded.isNotEmpty) {
        if (Get.isRegistered<StorageService>()) {
          unawaited(
            Get.find<StorageService>().savePendingNotificationNav(decoded),
          );
        } else {
          unawaited(
            GetStorage().write(StorageKeys.PENDING_NOTIFICATION_NAV, decoded),
          );
        }
      }

      // Defer until after the first frame so GetX / routes can settle.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _forwardPayloadToNavigation(payload);
      });
      for (final ms in [800, 2000, 4000]) {
        Future<void>.delayed(Duration(milliseconds: ms), () {
          if (Get.isRegistered<NotificationManager>()) {
            Get.find<NotificationManager>().flushPendingNavigation();
          }
        });
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [LocalNotificationService] Launch details error: $e');
    }
  }

  /// Show a heads-up / banner notification (required when app is in foreground).
  static Future<void> showNotification(RemoteMessage message) async {
    await initialize();

    final content = resolveContent(message);
    final title = content.title;
    final body = content.body.isNotEmpty ? content.body : content.title;
    final data = PushLaunchHandler.dataFromRemoteMessage(message);
    final payload = encodePayload(data);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Push and in-app alerts (heads-up enabled)',
      importance: Importance.max,
      priority: Priority.max,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.message,
      ticker: title,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      autoCancel: true,
      onlyAlertOnce: false,
      channelShowBadge: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: NotificationContentLocalizer.translate('app_name'),
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = _notificationId(message);
    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
    DiagnosticLogger.instance.debug(
      '📣 [LocalNotificationService] Shown id=$id title="$title" '
      'channel=$channelId',
    );
  }
}
