import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/services/device_info_service.dart';
import '../../core/services/download_service.dart';
import '../../core/services/zip_download_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/notification_manager.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/private_chat_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/private_chat_notification_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/private_chat_repository.dart';
import '../../presentation/chat/providers/message_provider.dart';
import '../../presentation/chat/providers/private_chat_provider.dart';
import '../../data/repositories/home_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../presentation/auth/controllers/auth_controller.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../presentation/profile/controllers/profile_controller.dart';
import '../../presentation/profile/controllers/two_fa_management_controller.dart';
import '../../presentation/trusted_device/controllers/trusted_devices_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // -----------------------------
    // CORE SERVICES
    // -----------------------------
    Get.put<ApiService>(ApiService(), permanent: true);

    Get.put<DeviceInfoService>(DeviceInfoService(), permanent: true);

    Get.put<FirebaseAuthService>(FirebaseAuthService(), permanent: true);

    Get.put<PrivateChatService>(PrivateChatService(), permanent: true);
    Get.put<PresenceService>(PresenceService(), permanent: true);
    Get.put<PrivateChatNotificationService>(
      PrivateChatNotificationService(),
      permanent: true,
    );
    Get.lazyPut<PrivateChatRepository>(
      () => PrivateChatRepository(),
      fenix: true,
    );
    Get.put<MessageProvider>(MessageProvider(), permanent: true);
    Get.put<PrivateChatProvider>(PrivateChatProvider(), permanent: true);

    // Reuse StorageService from main.dart — never register a second instance.
    if (!Get.isRegistered<StorageService>()) {
      Get.put<StorageService>(StorageService()..init(), permanent: true);
    }

    // LocaleController depends on StorageService, so register it after
    Get.put<LocaleController>(LocaleController(), permanent: true);

    // DownloadService for document downloads
    Get.put<DownloadService>(DownloadService(), permanent: true);

    // ZipDownloadService for encrypted ZIP download + open (OS prompts for password)
    Get.put<ZipDownloadService>(ZipDownloadService(), permanent: true);

    // NotificationManager: processes push payloads (must be registered before FcmService)
    Get.put<NotificationManager>(NotificationManager(), permanent: true);

    // FCM Service: singleton, never destroyed; init runs once (guarded inside FcmService)
    final fcmService = FcmService();
    Get.put<FcmService>(fcmService, permanent: true);
    fcmService.init(); // fire-and-forget; listeners and token send run async

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
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
    Get.lazyPut<TwoFAManagementController>(() => TwoFAManagementController());
    Get.lazyPut<TrustedDevicesController>(() => TrustedDevicesController());
  }
}
