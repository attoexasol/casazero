import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

    await _plugin.initialize(settings);

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
  }

  /// Resolve title/body from FCM notification block or data payload.
  static ({String title, String body}) resolveContent(RemoteMessage message) {
    final pushNotification = message.notification;
    if (pushNotification?.title != null &&
        pushNotification!.title!.trim().isNotEmpty) {
      return (
        title: pushNotification.title!.trim(),
        body: pushNotification.body?.trim() ?? '',
      );
    }

    final data = message.data;
    final title = _firstNonEmpty(data, const [
      'title',
      'notification_title',
      'subject',
      'headline',
    ]);
    final body = _firstNonEmpty(data, const [
      'body',
      'message',
      'content',
      'subtitle',
      'notification_body',
      'text',
      'description',
    ]);

    if (title != null && body != null) {
      return (title: title, body: body);
    }
    if (body != null) {
      return (title: 'CasaZero', body: body);
    }
    if (title != null) {
      return (title: title, body: '');
    }

    return (title: 'CasaZero', body: 'You have a new notification');
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

  /// Show a heads-up / banner notification (required when app is in foreground).
  static Future<void> showNotification(RemoteMessage message) async {
    await initialize();

    final content = resolveContent(message);
    final title = content.title;
    final body = content.body.isNotEmpty ? content.body : content.title;

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
    );
  }
}
