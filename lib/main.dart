import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/routes/app_routes.dart';
import 'app/bindings/initial_binding.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/app_colors.dart';
import 'core/services/storage_service.dart';
import 'core/localization/app_translations.dart';
import 'core/localization/locale_controller.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/utils/firebase_config_audit.dart';
import 'helpers/local_notification_service.dart';
import 'core/services/push_launch_handler.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_manager.dart';
import 'core/logging/diagnostic_logger.dart';
import 'dart:async';

const Color _splashBackgroundColor = Color(0xFFFAF7F4);

/// Top-level background handler for FCM. Must not use GetX or controllers (isolate).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  try {
    await GetStorage.init();
  } catch (_) {}
  try {
    await DiagnosticLogger.instance.init();
    DiagnosticLogger.instance.info(
      'FCM background message received',
      metadata: <String, Object?>{
        'has_notification_payload': message.notification != null,
        'data_key_count': message.data.length,
      },
    );
  } catch (_) {}

  final messageId = message.messageId ?? 'no-id';
  final data = message.data;
  print(
    '📩 [FCM Background] messageId: $messageId, title: ${message.notification?.title}, data keys: ${data.isNotEmpty ? data.keys.join(", ") : "none"}',
  );

  // Data-only pushes: show localized local notification with tap payload.
  // Notification-payload pushes are rendered by the OS; taps use PushLaunchHandler.
  if (message.notification == null) {
    try {
      await LocalNotificationService.showNotification(message);
    } catch (e) {
      print('❌ [FCM Background] Local notification error: $e');
      DiagnosticLogger.instance.error(
        'FCM background local notification error',
        error: e,
      );
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DiagnosticLogger.instance.init().timeout(const Duration(seconds: 2));
  } catch (_) {}
  DiagnosticLogger.instance.installErrorHandlers();
  DiagnosticLogger.instance.info('App started');
  unawaited(DiagnosticLogger.instance.logEnvironment());

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surfaceWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await _initializeCriticalServices();

  runApp(const CasaZeroApp());

  unawaited(_initializeDeferredServices());
}

/// Fast startup work required before the splash screen can run.
///
/// Critical push order (must complete before [runApp]):
/// Firebase.initializeApp → PushLaunchHandler.install →
/// LocalNotificationService.initialize → await FcmService.init
Future<void> _initializeCriticalServices() async {
  try {
    await GetStorage.init().timeout(const Duration(seconds: 3));
  } on TimeoutException {
    print('⏱️  GetStorage initialization timed out');
  } catch (e) {
    print('❌ GetStorage initialization failed: $e');
  }

  try {
    await Get.putAsync(() => StorageService().init()).timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        print('⏱️  StorageService initialization timed out');
        return StorageService();
      },
    );
  } catch (e) {
    print('❌ StorageService initialization failed: $e');
    Get.put(StorageService());
  }

  try {
    if (!Get.isRegistered<LocaleController>()) {
      Get.put(LocaleController());
    }
  } catch (e) {
    print('❌ LocaleController initialization failed: $e');
    Get.put(LocaleController());
  }

  // 1) Firebase + 2) PushLaunchHandler (getInitialMessage before local details).
  await _initializeFirebase();

  // 3) Local notification channel + launch-details (Android FG / data-only taps).
  try {
    await LocalNotificationService.initialize();
    print('✅ Local notifications initialized (critical path)');
    DiagnosticLogger.instance.info('Local notifications initialized');
  } catch (e) {
    print('❌ Local notifications initialization failed: $e');
    DiagnosticLogger.instance.error(
      'Local notifications initialization failed',
      error: e,
    );
  }

  // 4) FCM permission, onMessage, iOS foreground presentation — before UI.
  await _initializeFcmServiceCritical();
}

/// Heavy services that must not block the first splash frame.
Future<void> _initializeDeferredServices() async {
  InitialBinding.registerFirebaseDependentServices();

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    print('❌ Orientation lock failed: $e');
  }
}

Future<void> _initializeFirebase() async {
  DiagnosticLogger.instance.info('Firebase initialization started');
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    print('🔍 iOS: Checking Firebase init...');
  }
  print('🔍 Checking Firebase initialization status...');
  print('🔍 Firebase.apps.length: ${Firebase.apps.length}');

  if (Firebase.apps.isEmpty) {
    try {
      print('🔄 Initializing Firebase from Flutter...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️  Firebase initialization timed out after 10 seconds');
          throw TimeoutException(
            'Firebase initialization timeout',
            const Duration(seconds: 10),
          );
        },
      );
      print('✅ Firebase initialized successfully from Flutter');
      print('✅ Firebase.apps.length after init: ${Firebase.apps.length}');
      DiagnosticLogger.instance.info('Firebase initialization completed');
      FirebaseConfigAudit.logStartupState();
    } catch (e, stackTrace) {
      print('❌ Firebase initialization failed: $e');
      print('❌ Stack trace: $stackTrace');
      print('⚠️  App will continue without Firebase features');
      DiagnosticLogger.instance.error(
        'Firebase initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  } else {
    print('✅ Firebase already initialized (likely by AppDelegate)');
    print('✅ Firebase.apps.length: ${Firebase.apps.length}');
    DiagnosticLogger.instance.info(
      'Firebase initialization completed',
      metadata: <String, Object?>{'already_initialized': true},
    );
    FirebaseConfigAudit.logStartupState();
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    print('✅ iOS Firebase apps: ${Firebase.apps.length}');
  }

  if (Firebase.apps.isNotEmpty) {
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      print('✅ Background message handler registered');
      DiagnosticLogger.instance.info('FCM background handler registered');
    } catch (e) {
      print('❌ Failed to register background message handler: $e');
      DiagnosticLogger.instance.error(
        'FCM background handler registration failed',
        error: e,
      );
    }

    // Capture tray/lock-screen launch ASAP (before FcmService.init / runApp).
    try {
      await PushLaunchHandler.install();
      print('✅ Push launch handler installed');
    } catch (e) {
      print('❌ Push launch handler failed: $e');
      DiagnosticLogger.instance.error('Push launch handler failed', error: e);
    }
  }
}

/// Registers [NotificationManager] + [FcmService] via GetX and awaits init so
/// foreground listeners / iOS presentation options are ready before [runApp].
/// InitialBinding reuses these singletons (does not create a second instance).
Future<void> _initializeFcmServiceCritical() async {
  if (Firebase.apps.isEmpty) {
    print(
      '⚠️ [main] Skipping critical FcmService.init — Firebase not initialized',
    );
    DiagnosticLogger.instance.warning(
      'FCM initialization skipped — Firebase not initialized',
    );
    return;
  }

  DiagnosticLogger.instance.info('FCM initialization started');
  try {
    if (!Get.isRegistered<NotificationManager>()) {
      Get.put<NotificationManager>(NotificationManager(), permanent: true);
      print('✅ NotificationManager registered (critical path)');
    }

    if (!Get.isRegistered<FcmService>()) {
      Get.put<FcmService>(FcmService(), permanent: true);
      print('✅ FcmService registered (critical path)');
    }

    await Get.find<FcmService>().init();
    print('✅ FcmService.init awaited (critical path, before runApp)');
    DiagnosticLogger.instance.info('FCM initialization completed');
  } catch (e, stackTrace) {
    print('❌ Critical FcmService.init failed: $e');
    print('⚠️  App will continue; deferred path may retry via InitialBinding');
    DiagnosticLogger.instance.error(
      'FCM initialization failed',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

class CasaZeroApp extends StatelessWidget {
  const CasaZeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final LocaleController localeController = Get.find();

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final splashTheme = AppTheme.lightTheme.copyWith(
          scaffoldBackgroundColor: _splashBackgroundColor,
        );

        return Obx(
          () => GetMaterialApp(
            title: 'CasaZero',
            debugShowCheckedModeBanner: false,

            theme: splashTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,

            translations: AppTranslations(),
            locale: localeController.locale,
            fallbackLocale: const Locale('en', 'US'),

            initialBinding: InitialBinding(),
            initialRoute: AppRoutes.SPLASH,
            getPages: AppRoutes.routes,

            defaultTransition: Transition.fade,
            transitionDuration: const Duration(milliseconds: 300),

            builder: (context, widget) {
              final textScaler = MediaQuery.textScalerOf(context).clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.3,
              );
              return ColoredBox(
                color: _splashBackgroundColor,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: widget!,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
