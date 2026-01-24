import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
//import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'app/routes/app_routes.dart';
import 'app/bindings/initial_binding.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/app_colors.dart';
import 'core/services/storage_service.dart';
import 'core/localization/app_translations.dart';
import 'core/localization/locale_controller.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'helpers/local_notification_service.dart';
import 'dart:async';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background Message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase with timeout and error handling
  // Check if Firebase is already initialized (e.g., by AppDelegate on iOS)
  print("🔍 Checking Firebase initialization status...");
  print("🔍 Firebase.apps.length: ${Firebase.apps.length}");

  if (Firebase.apps.isEmpty) {
    try {
      print("🔄 Initializing Firebase from Flutter...");
      await Firebase.initializeApp().timeout(
        const Duration(seconds: 10), // Increased timeout
        onTimeout: () {
          print("⏱️  Firebase initialization timed out after 10 seconds");
          throw TimeoutException(
            "Firebase initialization timeout",
            const Duration(seconds: 10),
          );
        },
      );
      print("✅ Firebase initialized successfully from Flutter");
      print("✅ Firebase.apps.length after init: ${Firebase.apps.length}");
    } catch (e, stackTrace) {
      print("❌ Firebase initialization failed: $e");
      print("❌ Stack trace: $stackTrace");
      print("⚠️  App will continue without Firebase features");
    }
  } else {
    print("✅ Firebase already initialized (likely by AppDelegate)");
    print("✅ Firebase.apps.length: ${Firebase.apps.length}");
    for (var app in Firebase.apps) {
      print("✅ Firebase app name: ${app.name}");
    }
  }

  // Set background message handler only if Firebase is initialized
  if (Firebase.apps.isNotEmpty) {
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      print("✅ Background message handler registered");
    } catch (e) {
      print("❌ Failed to register background message handler: $e");
    }
  }

  // 🔥 Initialize Local Notifications
  try {
    LocalNotificationService.initialize();
  } catch (e) {
    print("❌ Local notifications initialization failed: $e");
  }

  // Initialize GetStorage with timeout
  try {
    await GetStorage.init().timeout(const Duration(seconds: 3));
  } on TimeoutException {
    print("⏱️  GetStorage initialization timed out");
  } catch (e) {
    print("❌ GetStorage initialization failed: $e");
  }

  // Initialize Storage Service with timeout
  try {
    await Get.putAsync(() => StorageService().init()).timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        print("⏱️  StorageService initialization timed out");
        return StorageService();
      },
    );
  } catch (e) {
    print("❌ StorageService initialization failed: $e");
    Get.put(StorageService());
  }

  // Initialize Locale Controller (will be re-initialized in InitialBinding, but needed here for GetMaterialApp)
  try {
    if (!Get.isRegistered<LocaleController>()) {
      Get.put(LocaleController());
    }
  } catch (e) {
    print("❌ LocaleController initialization failed: $e");
    // Create a fallback locale controller
    Get.put(LocaleController());
  }

  // System UI Styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surfaceWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Orientation Lock
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 🔥 Initialize FCM foreground listeners (non-blocking, only if Firebase is initialized)
  // Don't await - let it run in background so app can start
  if (Firebase.apps.isNotEmpty) {
    // Fire and forget - errors are handled inside setupFCMListeners
    setupFCMListeners();
  }

  // Start the app immediately - don't wait for FCM
  runApp(const CasaZeroApp());
}

void setupFCMListeners() async {
  try {
    // Check if Firebase is initialized
    if (Firebase.apps.isEmpty) {
      print("⚠️  Firebase not initialized, skipping FCM setup");
      print("💡 Check if GoogleService-Info.plist is properly configured");
      return;
    }

    print("🔥 Starting FCM setup...");
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 🔥 Request permissions (iOS specific)
    print("📱 Requesting notification permissions...");
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print("📱 Permission Status: ${settings.authorizationStatus}");
    print("📱 Alert: ${settings.alert}");
    print("📱 Badge: ${settings.badge}");
    print("📱 Sound: ${settings.sound}");

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print("❌ Notification permission denied by user");
      print("💡 User needs to enable notifications in Settings");
      return;
    }

    // Wait for APNs token to be registered (can take a few seconds)
    print("⏳ Waiting for APNs token registration...");
    int maxWaitTime = 10; // Maximum 10 seconds
    int waited = 0;
    bool apnsTokenReceived = false;

    while (waited < maxWaitTime && !apnsTokenReceived) {
      await Future.delayed(const Duration(seconds: 1));
      waited++;
      // Check if APNs token is set (indirectly by trying to get FCM token)
      try {
        // Try to get token - if APNs token is set, this might work
        String? testToken = await messaging.getToken();
        if (testToken != null && testToken.isNotEmpty) {
          apnsTokenReceived = true;
          print("✅ APNs token appears to be registered");
        }
      } catch (e) {
        // Continue waiting
        if (waited % 2 == 0) {
          print("⏳ Still waiting for APNs token... (${waited}s)");
        }
      }
    }

    if (!apnsTokenReceived) {
      print("⚠️  APNs token may not be registered yet, but continuing...");
    }

    // 🔥 Get the FCM token with retry logic
    String? token;
    int retries = 5; // Increased retries
    for (int i = 0; i < retries; i++) {
      try {
        print("🔄 Attempting to get FCM token (${i + 1}/$retries)...");
        token = await messaging.getToken();
        if (token != null && token.isNotEmpty) {
          print("✅ FCM Token retrieved successfully: $token");
          break;
        } else {
          print(
            "⚠️  FCM Token is null or empty, retrying... (${i + 1}/$retries)",
          );
          await Future.delayed(const Duration(seconds: 3));
        }
      } catch (e) {
        print("❌ Error getting FCM token (attempt ${i + 1}/$retries): $e");
        if (i < retries - 1) {
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    }

    if (token == null || token.isEmpty) {
      print("❌ Failed to get FCM token after $retries attempts");
      print("");
      print("🔍 Troubleshooting steps:");
      print(
        "   1. Verify GoogleService-Info.plist has CLIENT_ID and REVERSED_CLIENT_ID",
      );
      print("   2. Check if APNs is configured in Firebase Console");
      print("   3. Ensure Push Notifications capability is enabled in Xcode");
      print(
        "   4. Make sure you're testing on a physical device (not simulator)",
      );
      print("   5. Check Xcode console for APNs token registration messages");
    }

    // TODO: Send token to Laravel API

    // 🔥 Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📨 Foreground Message: ${message.notification?.title}");
      LocalNotificationService.showNotification(message);
    });

    // 🔥 App opened from terminated / background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📬 Notification Opened App: ${message.data}");
    });

    // 🔥 Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) {
      print("🔄 FCM Token refreshed: $newToken");
      // TODO: Send refreshed token to Laravel API
    });
  } catch (e, stackTrace) {
    print("❌ Error setting up FCM listeners: $e");
    print("Stack trace: $stackTrace");
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
        return Obx(
          () => GetMaterialApp(
            title: 'CasaZero',
            debugShowCheckedModeBanner: false,

            // THEME
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,

            // LOCALIZATION
            translations: AppTranslations(),
            locale: localeController.locale,
            fallbackLocale: const Locale('en', 'US'),

            // ROUTING
            initialBinding: InitialBinding(),
            initialRoute: AppRoutes.SPLASH,
            getPages: AppRoutes.routes,

            // PAGE TRANSITIONS
            defaultTransition: Transition.fade,
            transitionDuration: const Duration(milliseconds: 300),

            // PLATFORM-SPECIFIC TEXT SCALER FIX
            // Note: SafeArea removed from builder to allow GetX popups to display properly
            // SafeArea should be applied at individual screen/widget level if needed
            builder: (context, widget) {
              // Ensure GetX has proper context for overlays
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: widget!,
              );
            },
          ),
        );
      },
    );
  }
}