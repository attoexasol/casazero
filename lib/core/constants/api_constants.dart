// core/constants/api_constants.dart (UPDATED WITH TRUSTED DEVICES ENDPOINTS)
class ApiConstants {
  static const String BASE_URL = 'https://smarthome.attoexasolutions.com/api';

  // Auth Endpoints
  static const String LOGIN = '/user/login';
  static const String LOGOUT = '/auth/logout';
  static const String REFRESH_TOKEN = '/auth/refresh';
  static const String FORGOT_PASSWORD = '/auth/forgot-password';
  static const String RESET_PASSWORD = '/auth/reset-password';
  static const String CHANGE_PASSWORD = '/user/forget_password';

  // User Endpoints
  static const String GET_USER_PROFILE = '/users/profile';

  /// Update User Profile
  /// POST /user/profile_data/update/{user_id}
  /// Request: Full user profile data including notifications, residence, etc.
  /// Response: { "status": true, "message": "Profile updated successfully!", "data": {...} }
  static const String UPDATE_USER_PROFILE = '/user/profile_data/update';

  // ============================================================================
  // 2FA SETUP ENDPOINTS (First Login / Settings)
  // ============================================================================

  /// Setup Authenticator 2FA - Generate QR code and secret
  /// GET /setup_2FA/{user_id}
  /// Response: {
  ///   "status": true,
  ///   "message": "2FA setup generated successfully",
  ///   "data": {
  ///     "user_id": 3,
  ///     "email": "user@example.com",
  ///     "secret_key": "BASE32_SECRET",
  ///     "otpauth_url": "otpauth://totp/...",
  ///     "qr_base64": "data:image/svg+xml;base64,..."
  ///   }
  /// }
  static const String SETUP_AUTHENTICATOR_2FA = '/setup_2FA';

  /// Verify TOTP/QR Code - Verify authenticator code during setup
  /// POST /verify_QR
  /// Request: { "user_id": 1, "code": "123456" }
  /// Response: { "message": "2FA Verified Successfully" }
  static const String VERIFY_QR_CODE = '/verify_QR';

  /// Enable 2FA during first login or in settings (DEPRECATED - use VERIFY_QR_CODE)
  static const String ENABLE_2FA = '/auth/2fa/enable';

  /// Verify 2FA setup with code (DEPRECATED - use VERIFY_QR_CODE)
  static const String VERIFY_2FA = '/auth/2fa/verify';

  static const String UPDATE_2FA_STATUS = '/update/2fa_status';

  /// Disable 2FA in settings
  /// POST /2fa/disable/{user_id}
  /// Response: {
  ///   "status": true,
  ///   "message": "Two-factor authentication disabled successfully.",
  ///   "data": {
  ///     "user_id": 6,
  ///     "user_name": "Nahid Hasan",
  ///     "email": "nahid@abc.com",
  ///     "two_fa_method": "none",
  ///     "is_two_fa_status": 0
  ///   }
  /// }
  static const String DISABLE_2FA = '/2fa/disable';

  // ============================================================================
  // EMAIL OTP ENDPOINTS (Actual API - First Login & Regular Login)
  // ============================================================================

  /// Send Email OTP - Used for both first login setup and regular login
  /// POST /2fa/email/otp_send
  /// Request: { "user_id": 1 }
  /// Response: { "Status": true, "message": "OTP Sent to your email" }
  static const String SEND_EMAIL_OTP = '/2fa/email/otp_send';

  /// Verify Email OTP - For both first login and regular login
  /// POST /2fa/email/otp_verify
  /// Request: {
  ///   "user_id": 1,
  ///   "otp": "123456",
  ///   "device_id": "abcd-12346-unique-mobile-id",
  ///   "device_name": "Samsung S24",
  ///   "platform": "android",
  ///   "ip_address": "102.22.44.5",
  ///   "lat": 23.8103,
  ///   "lng": 90.4125
  /// }
  /// Response: { "status": true, "message": "Email 2FA verified successfully" }
  static const String VERIFY_EMAIL_OTP = '/2fa/email/otp_verify';

  // ============================================================================
  // SMS OTP ENDPOINTS (If available)
  // ============================================================================

  /// Send SMS OTP
  static const String SEND_SMS_OTP = '/2fa/sms/otp_send';

  /// Verify SMS OTP
  static const String VERIFY_SMS_OTP = '/2fa/sms/otp_verify';

  // ============================================================================
  // TRUSTED DEVICES ENDPOINTS
  // ============================================================================

  /// Get All Trusted Devices for a user
  /// GET /get_all_trusted_device/{user_id}
  /// Response: {
  ///   "status": true,
  ///   "message": "Trusted devices retrieved successfully.",
  ///   "trusted_devices": [
  ///     {
  ///       "id": 1,
  ///       "user_id": 8,
  ///       "device_id": "abcd-12346-unique-mobile-id",
  ///       "device_name": "Samsung S24",
  ///       "platform": "android",
  ///       "last_ip": "102.22.44.5",
  ///       "user_agent": null,
  ///       "last_login_at": "2025-11-28T19:46:41.000000Z",
  ///       "trusted_until": "2025-12-28T19:46:34.000000Z",
  ///       "lat": "23.8103000",
  ///       "lng": "90.4125000",
  ///       "is_revoked": false,
  ///       "created_at": "2025-11-28T19:46:34.000000Z",
  ///       "updated_at": "2025-11-28T19:46:41.000000Z"
  ///     }
  ///   ]
  /// }
  static const String GET_ALL_TRUSTED_DEVICES = '/get_all_trusted_device';

  static const String CHANGE_LANGUAGE = '/change/language';

  /// Revoke a Trusted Device
  /// POST /revoke_trusted_device
  /// Request: { "device_id": 1 }
  /// Response: {
  ///   "status": true,
  ///   "message": "Device revoked successfully"
  /// }
  static const String REVOKE_TRUSTED_DEVICE = '/revoke_trusted_device';

  // Home Endpoints
  static const String GET_RESIDENCE_INFO = '/residences/{residenceId}';

  /// Get User Residences
  /// GET /residences/{user_id}
  /// Response: {
  ///   "status": true,
  ///   "user_id": "1",
  ///   "data": [
  ///     {
  ///       "id": 1,
  ///       "residence_name": "Skyline Tower",
  ///       "residence_address": "Sector 9, Dhaka",
  ///       "residence_type": "Condominium",
  ///       "residence_admin": 1,
  ///       "created_at": "2025-11-17T00:30:03.000000Z",
  ///       "updated_at": "2025-11-17T00:55:44.000000Z"
  ///     }
  ///   ]
  /// }
  static const String GET_USER_RESIDENCES = '/residences';

  static const String GET_FEED_ITEMS = '/feed';
  static const String GET_CONSTRUCTION_PHASES =
      '/residences/{residenceId}/construction';

  // Buildings Endpoints
  static const String GET_BUILDINGS = '/buildings';
  static const String GET_BUILDING_DETAILS = '/buildings/{buildingId}';

  static const String DELETE_SPECIFIC_USER_DEVICE =
      '/delete_specific_user_device';

  static const String GET_DOCUMENT_CATEGORIES = '/document_categories';

  /// Get All Documents
  /// GET /documents/
  /// Response: {
  ///   "status": true,
  ///   "data": [
  ///     {
  ///       "id": 12,
  ///       "document_name": "National ID Card",
  ///       "document_description": "Front side of NID",
  ///       "file_url": "https://...",
  ///       "file_type": "jpg",
  ///       "file_size": "0.01 MB",
  ///       "uploaded_date": "12-04-2025",
  ///       "category": { "id": 2, "category_name": "My Documents" },
  ///       "type": { "id": 2, "type_name": "Guarantees" },
  ///       "unit": { "id": 1, "unit_name": "Updated Unit A1" } or null
  ///     }
  ///   ]
  /// }
  static const String GET_DOCUMENTS = '/documents/';

  /// Get Unit Wise Documents
  /// POST /get_unit_wise_documents
  /// Request: { "token": "user token" }
  /// Response: Unit-wise document list with nested category/type/unit info
  static const String GET_UNIT_WISE_DOCUMENTS = '/get_unit_wise_documents';

  /// Get Residence Documents
  /// POST /get_residence_wise_documents
  /// Request: { "residence_id": 23 }
  /// Response: {
  ///   "status": true,
  ///   "message": "Residence documents retrieved successfully",
  ///   "residence": {
  ///     "id": 23,
  ///     "residence_name": "POLICE PARK1",
  ///     "documents": [ ... ]
  ///   }
  /// }
  static const String GET_RESIDENCE_DOCUMENTS = '/get_residence_wise_documents';

  // ============================================================================
  // ENDPOINT HELPER METHODS
  // ============================================================================

  /// Replace path parameters in endpoint
  static String replaceParam(String endpoint, String param, String value) {
    return endpoint.replaceAll('{$param}', value);
  }

  /// Build full URL
  static String buildUrl(String endpoint) {
    return '$BASE_URL$endpoint';
  }
}
