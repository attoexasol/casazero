import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../constants/storage_keys.dart';

class StorageService extends GetxService {
  late GetStorage _box;

  Future<StorageService> init() async {
    _box = GetStorage();
    return this;
  }

  // Token Management
  Future<void> saveAccessToken(String token) async {
    await _box.write(StorageKeys.ACCESS_TOKEN, token);
  }

  String? getAccessToken() {
    return _box.read(StorageKeys.ACCESS_TOKEN);
  }

  Future<void> clearAccessToken() async {
    await _box.remove(StorageKeys.ACCESS_TOKEN);
  }

  Future<void> saveRefreshToken(String token) async {
    await _box.write(StorageKeys.REFRESH_TOKEN, token);
  }

  String? getRefreshToken() {
    return _box.read(StorageKeys.REFRESH_TOKEN);
  }

  Future<void> clearRefreshToken() async {
    await _box.remove(StorageKeys.REFRESH_TOKEN);
  }

  // Device Token (for trusted device verification)
  Future<void> saveDeviceToken(String token) async {
    await _box.write(StorageKeys.DEVICE_TOKEN, token);
  }

  String? getDeviceToken() {
    return _box.read(StorageKeys.DEVICE_TOKEN);
  }

  Future<void> clearDeviceToken() async {
    await _box.remove(StorageKeys.DEVICE_TOKEN);
  }

  // User Data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _box.write(StorageKeys.USER_DATA, userData);
  }

  Map<String, dynamic>? getUserData() {
    return _box.read(StorageKeys.USER_DATA);
  }

  // Language
  Future<void> saveLanguage(String language) async {
    await _box.write(StorageKeys.LANGUAGE, language);
  }

  String getLanguage() {
    return _box.read(StorageKeys.LANGUAGE) ?? 'en';
  }

  // First Login Flag
  Future<void> setFirstLogin(bool isFirstLogin) async {
    await _box.write(StorageKeys.IS_FIRST_LOGIN, isFirstLogin);
  }

  bool isFirstLogin() {
    return _box.read(StorageKeys.IS_FIRST_LOGIN) ?? false;
  }

  // Clear All Data
  Future<void> clearAll() async {
    await _box.erase();
  }
}
