import 'package:flutter/foundation.dart';
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

  /// Persists Laravel login top-level `firebase_token`.
  Future<void> saveFirebaseToken(String token) async {
    await _box.write(StorageKeys.FIREBASE_TOKEN, token);
    await _box.remove('firebase_custom_token');
    final verify = getStoredFirebaseToken();
    debugPrint(
      'VERIFY STORED TOKEN=${verify != null} VERIFY TOKEN LENGTH=${verify?.length ?? 0}',
    );
  }

  void debugPrintStorageKeys() {
    // ignore: avoid_print
    print(
      '[Storage] keys in box: access=${getAccessToken() != null} '
      'firebase_token=${getStoredFirebaseToken() != null} '
      'project_id=${getFirebaseProjectId() != null}',
    );
  }

  /// Reads locally stored login `firebase_token` only.
  String? getStoredFirebaseToken() {
    final t = _box.read(StorageKeys.FIREBASE_TOKEN)?.toString().trim();
    if (t != null && t.isNotEmpty && t.toLowerCase() != 'null') return t;
    // One-time read from legacy key
    final legacy = _box.read('firebase_custom_token')?.toString().trim();
    if (legacy != null && legacy.isNotEmpty && legacy.toLowerCase() != 'null') {
      return legacy;
    }
    return null;
  }

  Future<void> clearFirebaseToken() async {
    await _box.remove(StorageKeys.FIREBASE_TOKEN);
    await _box.remove('firebase_custom_token');
  }

  Future<void> saveFirebaseProjectId(String projectId) async {
    await _box.write(StorageKeys.FIREBASE_PROJECT_ID, projectId);
  }

  String? getFirebaseProjectId() {
    return _box.read(StorageKeys.FIREBASE_PROJECT_ID)?.toString();
  }

  Future<void> clearFirebaseProjectId() async {
    await _box.remove(StorageKeys.FIREBASE_PROJECT_ID);
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
    return _box.read(StorageKeys.LANGUAGE) ?? 'it';
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
