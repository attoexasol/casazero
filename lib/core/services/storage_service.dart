import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../auth/auth_phase.dart';
import '../constants/storage_keys.dart';
import 'package:casazero/core/logging/diagnostic_logger.dart';

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
    DiagnosticLogger.instance.debug(
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

  // Authentication Phase (2FA pending state — survives process death)
  Future<void> saveAuthPhase(AuthPhase phase) async {
    if (phase == AuthPhase.none) {
      await _box.remove(StorageKeys.AUTH_PHASE);
      return;
    }
    await _box.write(StorageKeys.AUTH_PHASE, phase.storageValue);
  }

  /// Missing key returns [AuthPhase.none] (logged out or legacy session).
  AuthPhase getAuthPhase() {
    return AuthPhase.fromStorage(
      _box.read(StorageKeys.AUTH_PHASE)?.toString(),
    );
  }

  /// True only while a password login is awaiting OTP completion.
  bool get isPending2FA => getAuthPhase() == AuthPhase.pending2FA;

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
  /// Clears session/auth data. [preserveLanguage] keeps the user's UI language
  /// choice so logout or session expiry does not reset it to the app default.
  /// Also preserves a pending notification deep-link so login can resume it.
  Future<void> clearAll({bool preserveLanguage = true}) async {
    final savedLanguage =
        preserveLanguage ? _box.read<String>(StorageKeys.LANGUAGE) : null;
    final pendingNav = _box.read(StorageKeys.PENDING_NOTIFICATION_NAV);
    await _box.erase();
    if (savedLanguage != null && savedLanguage.isNotEmpty) {
      await _box.write(StorageKeys.LANGUAGE, savedLanguage);
    }
    if (pendingNav != null) {
      await _box.write(StorageKeys.PENDING_NOTIFICATION_NAV, pendingNav);
    }
  }

  Future<void> savePendingNotificationNav(Map<String, dynamic> payload) async {
    await _box.write(StorageKeys.PENDING_NOTIFICATION_NAV, payload);
  }

  Map<String, dynamic>? getPendingNotificationNav() {
    final raw = _box.read(StorageKeys.PENDING_NOTIFICATION_NAV);
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  Future<void> clearPendingNotificationNav() async {
    await _box.remove(StorageKeys.PENDING_NOTIFICATION_NAV);
  }
}
