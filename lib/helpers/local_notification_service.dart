import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../core/services/notification_manager.dart';
import '../core/utils/notification_content_localizer.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'casazero_alerts';
  static const String channelName = 'CasaZero Alerts';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: 'Push and in-app notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        ),
      );
    }

    _initialized = true;

    // Terminated → local notification tap launch (same navigation path as FCM).
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
      rawTitle = _firstNonEmpty(data, const [
            'title',
            'notification_title',
            'subject',
            'headline',
            'title_en',
            'title_it',
          ]) ??
          '';
      rawBody = _firstNonEmpty(data, const [
            'body',
            'message',
            'content',
            'subtitle',
            'notification_body',
            'text',
            'description',
            'content_en',
            'content_it',
          ]) ??
          '';
    }

    final type = _firstNonEmpty(data, const [
      'notification_type',
      'type',
      'push_type',
      'category',
    ]);

    if (rawTitle.isEmpty && rawBody.isEmpty) {
      final fallback = NotificationContentLocalizer.localize(
        type: type,
        title: 'CasaZero',
        body: NotificationContentLocalizer.isItalian
            ? 'Hai una nuova notifica'
            : 'You have a new notification',
      );
      return fallback;
    }

    return NotificationContentLocalizer.localize(
      type: type,
      title: rawTitle.isNotEmpty ? rawTitle : 'CasaZero',
      body: rawBody,
    );
  }

  static String? _firstNonEmpty(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
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
      print('❌ [LocalNotificationService] encodePayload error: $e');
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
      print('❌ [LocalNotificationService] decodePayload error: $e');
    }
    return {};
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print(
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
    try {
      if (!Get.isRegistered<NotificationManager>()) {
        print(
          '⚠️ [LocalNotificationService] NotificationManager not registered',
        );
        return;
      }
      Get.find<NotificationManager>().handleNotificationNavigation(payload);
    } catch (e) {
      print('❌ [LocalNotificationService] Navigation dispatch error: $e');
    }
  }

  /// Cold start from a local notification tap (data-only / foreground-shown).
  static Future<void> _handleAppLaunchDetails() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return;

      final payload = details.notificationResponse?.payload;
      if (payload == null || payload.trim().isEmpty) return;

      print(
        '📬 [LocalNotificationService] Launched from local notification',
      );

      // Defer until after the first frame so GetX / routes can settle.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _forwardPayloadToNavigation(payload);
      });
    } catch (e) {
      print('❌ [LocalNotificationService] Launch details error: $e');
    }
  }

  /// Show a heads-up / banner notification (required when app is in foreground).
  static Future<void> showNotification(RemoteMessage message) async {
    await initialize();

    final content = resolveContent(message);
    final title = content.title;
    final body = content.body.isNotEmpty ? content.body : content.title;
    final payload = encodePayload(message.data);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Push and in-app notifications',
      importance: Importance.max,
      priority: Priority.max,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.message,
      ticker: title,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      _notificationId(message),
      title,
      body,
      details,
      payload: payload,
    );
  }
}
