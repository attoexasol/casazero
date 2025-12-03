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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize Storage Service
  await Get.putAsync(() => StorageService().init());

  // Initialize Locale Controller
  Get.put(LocaleController());

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

  runApp(const CasaZeroApp());
}

class CasaZeroApp extends StatelessWidget {
  const CasaZeroApp({Key? key}) : super(key: key);

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

            // PLATFORM-SPECIFIC SAFE AREA + TEXT SCALER FIX
            builder: (context, widget) {
              // Check if platform is Android
              final isAndroid =
                  !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

              Widget child = MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: widget!,
              );

              // Apply SafeArea ONLY for Android
              if (isAndroid) {
                return SafeArea(
                  top: true,
                  bottom: true,
                  left: false,
                  right: false,
                  child: child,
                );
              }

              // iOS - No SafeArea wrapper
              return child;
            },

            home: child,
          ),
        );
      },
    );
  }
}
