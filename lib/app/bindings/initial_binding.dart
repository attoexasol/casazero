import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/services/device_info_service.dart';
import '../../core/services/download_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/services/storage_service.dart';
import '../../data/repositories/auth_repository.dart';
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

    Get.put<LocaleController>(LocaleController(), permanent: true);

    // StorageService must be initialized before controllers
    Get.put<StorageService>(StorageService()..init(), permanent: true);

    // DownloadService for document downloads
    Get.put<DownloadService>(DownloadService(), permanent: true);

    // FCM Service for push notifications
    Get.putAsync(() => FcmService().init(), permanent: true);

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
