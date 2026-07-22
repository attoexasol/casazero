class StorageKeys {
  static const String ACCESS_TOKEN = 'access_token';
  static const String REFRESH_TOKEN = 'refresh_token';
  static const String DEVICE_TOKEN = 'device_token';
  static const String USER_DATA = 'user_data';
  static const String LANGUAGE = 'language';
  static const String IS_FIRST_LOGIN = 'is_first_login';
  static const String THEME_MODE = 'theme_mode';

  /// Laravel login top-level `firebase_token` (local only — never from API).
  static const String FIREBASE_TOKEN = 'firebase_token';

  /// Laravel login top-level `firebase_project_id`.
  static const String FIREBASE_PROJECT_ID = 'firebase_project_id';

  /// Pending deep-link from notification tap (survives session expiry / login).
  static const String PENDING_NOTIFICATION_NAV = 'pending_notification_nav';
}
