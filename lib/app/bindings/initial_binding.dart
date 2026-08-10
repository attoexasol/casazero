import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import '../../core/services/api_service.dart';
import '../../core/services/device_info_service.dart';
import '../../core/services/download_service.dart';
import '../../core/services/zip_download_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/notification_manager.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/app_status_service.dart';
import '../../core/services/private_chat_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/private_chat_notification_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/private_chat_repository.dart';
import '../../presentation/chat/providers/message_provider.dart';
import '../../presentation/chat/providers/private_chat_provider.dart';
import '../../data/repositories/home_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../presentation/profile/controllers/profile_controller.dart';
import '../../presentation/profile/controllers/two_fa_management_controller.dart';
import '../../presentation/trusted_device/controllers/trusted_devices_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // -----------------------------
    // CORE SERVICES (splash-safe)
    // -----------------------------
    Get.put<ApiService>(ApiService(), permanent: true);

    Get.put<DeviceInfoService>(DeviceInfoService(), permanent: true);

    Get.lazyPut<NotificationRepository>(
      () => NotificationRepository(),
      fenix: true,
    );
    Get.put<AppStatusService>(AppStatusService(), permanent: true);
    Get.put<PrivateChatNotificationService>(
      PrivateChatNotificationService(),
      permanent: true,
    );

    // Reuse StorageService from main.dart — never register a second instance.
    if (!Get.isRegistered<StorageService>()) {
      Get.put<StorageService>(StorageService()..init(), permanent: true);
    }

    // LocaleController depends on StorageService, so register it after
    if (!Get.isRegistered<LocaleController>()) {
      Get.put<LocaleController>(LocaleController(), permanent: true);
    }

    // DownloadService for document downloads
    Get.put<DownloadService>(DownloadService(), permanent: true);

    // ZipDownloadService for encrypted ZIP download + open (OS prompts for password)
    Get.put<ZipDownloadService>(ZipDownloadService(), permanent: true);

    // Reuse NotificationManager / FcmService from main.dart critical path when
    // already registered (Phase 2: await FcmService.init before runApp).
    if (!Get.isRegistered<NotificationManager>()) {
      Get.put<NotificationManager>(NotificationManager(), permanent: true);
    }

    if (!Get.isRegistered<FcmService>()) {
      Get.put<FcmService>(FcmService(), permanent: true);
    }

    Get.find<PrivateChatNotificationService>().registerHandlers();

    // -----------------------------
    // REPOSITORIES
    // -----------------------------
    Get.lazyPut<AuthRepository>(() => AuthRepository(), fenix: true);
    Get.lazyPut<HomeRepository>(() => HomeRepository(), fenix: true);
    Get.lazyPut<ProfileRepository>(() => ProfileRepository(), fenix: true);

    // -----------------------------
    // CONTROLLERS
    // -----------------------------
    // AuthController is created only by the AUTH route binding so login
    // TextEditingControllers are not fenix-resurrected after dispose.
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
    Get.lazyPut<TwoFAManagementController>(() => TwoFAManagementController());
    Get.lazyPut<TrustedDevicesController>(() => TrustedDevicesController());
  }

  /// Registers services that touch Firebase APIs. Call after [Firebase.initializeApp].
  static void registerFirebaseDependentServices() {
    if (Firebase.apps.isEmpty) {
      print(
        '⚠️ [InitialBinding] Skipping Firebase-dependent services — Firebase not initialized',
      );
      return;
    }

    if (!Get.isRegistered<PrivateChatService>()) {
      Get.put<PrivateChatService>(PrivateChatService(), permanent: true);
    }

    if (!Get.isRegistered<PresenceService>()) {
      Get.put<PresenceService>(PresenceService(), permanent: true);
    }

    if (!Get.isRegistered<FirebaseAuthService>()) {
      Get.put<FirebaseAuthService>(FirebaseAuthService(), permanent: true);
    }

    if (!Get.isRegistered<PrivateChatRepository>()) {
      Get.lazyPut<PrivateChatRepository>(
        () => PrivateChatRepository(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<MessageProvider>()) {
      Get.put<MessageProvider>(MessageProvider(), permanent: true);
    }

    if (!Get.isRegistered<PrivateChatProvider>()) {
      Get.put<PrivateChatProvider>(PrivateChatProvider(), permanent: true);
    }

    // Idempotent safety net: critical path already awaited init before runApp.
    // If somehow skipped (Firebase late / critical failure), init runs here.
    if (Get.isRegistered<FcmService>()) {
      unawaited(Get.find<FcmService>().init());
    }
  }
}
