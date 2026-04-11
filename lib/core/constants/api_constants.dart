// core/constants/api_constants.dart (UPDATED WITH TRUSTED DEVICES ENDPOINTS)
class ApiConstants {
  static const String BASE_URL = 'https://smarthome.attoexasolutions.com/api';

  // Auth Endpoints
  static const String LOGIN = '/user/login';
  static const String LOGOUT = '/user/logout';
  static const String REFRESH_TOKEN = '/auth/refresh';
  static const String FORGOT_PASSWORD = '/auth/forgot-password';
  static const String RESET_PASSWORD = '/auth/reset-password';
  static const String CHANGE_PASSWORD = '/user/forget_password';

  /// Get Document Password (read-only, for display on document password screen)
  /// POST /user/get-document-password
  /// Request: { "token": "<stored_user_token>" }
  /// Response: { "status": true, "document_password": "..." }
  static const String GET_DOCUMENT_PASSWORD = '/user/get-document-password';

  /// Set Document Password
  /// POST /user/set-document-password
  /// API URL: https://smarthome.attoexasolutions.com/api/user/set-document-password
  /// Request: {
  ///   "token": "USER_API_TOKEN",
  ///   "password": "123456",
  ///   "confirm_password": "123456"
  /// }
  /// Response: {
  ///   "status": true,
  ///   "message": "Document password set successfully"
  /// }
  static const String SET_DOCUMENT_PASSWORD = '/user/set-document-password';

  // User Endpoints
  /// Get User Profile
  /// POST /user/profile
  /// API URL: https://smarthome.attoexasolutions.com/api/user/profile
  /// Request: { "token": "USER_API_TOKEN" }
  /// Response: { "status": true, "message": "...", "data": {...} }
  static const String GET_USER_PROFILE = '/user/profile';

  /// Get Firebase Custom Token (for app restart when Firebase Auth state was lost)
  /// POST /user/firebase-token
  /// Request: { "token": "USER_API_TOKEN" }
  /// Response: { "status": true, "firebase_token": "..." }
  static const String GET_FIREBASE_TOKEN = '/user/firebase-token';

  /// Register/update FCM device token for push notifications
  /// POST /user/update-fcm-token
  /// Request: { "fcm_token": "FCM_DEVICE_TOKEN" } (Bearer token in header)
  /// Called on app start, after login, and on token refresh
  static const String UPDATE_FCM_TOKEN = '/user/update-fcm-token';

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

  /// Get Single Residence by ID
  /// GET /single_residence/{id}
  /// Response: { "status": true, "data": { "id": 48, "residence_name": "POLICE PARK", ... } }
  static const String GET_SINGLE_RESIDENCE = '/single_residence';

  /// Get User Residences
  /// PUT /residences/by-token
  /// Request: { "token": "USER_AUTH_TOKEN_HERE" }
  /// Response: {
  ///   "status": true,
  ///   "user_id": 17,
  ///   "data": [
  ///     {
  ///       "id": 3,
  ///       "residence_name": "Casa Zero Residency",
  ///       "residence_address": "Block A, Road 12, Dhaka"
  ///     },
  ///     {
  ///       "id": 5,
  ///       "residence_name": "Green View Apartments",
  ///       "residence_address": "Sector 10, Uttara, Dhaka"
  ///     }
  ///   ]
  /// }
  static const String GET_USER_RESIDENCES = '/residences/by-token';

  /// Get residence status with phases (construction progress)
  /// POST /residence/status-with-phases
  /// Request: { "api_token": "<TOKEN>", "residence_id": <ID> }
  static const String GET_RESIDENCE_STATUS_WITH_PHASES =
      '/residence/status-with-phases';

  static const String GET_FEED_ITEMS = '/feed';
  static const String GET_CONSTRUCTION_PHASES =
      '/residences/{residenceId}/construction';

  /// Get User Notifications
  /// POST /get_user/notifications
  /// Request: { "api_token": "<CURRENT_USER_API_TOKEN>" }
  /// Response: {
  ///   "status": true,
  ///   "data": [
  ///     {
  ///       "id": 2,
  ///       "title": "New Document Uploaded 📄",
  ///       "content": "Your document has been uploaded successfully.",
  ///       "url": "https://...",
  ///       "notification_type": "document",
  ///       "is_read": 0,
  ///       "created_at": "2026-01-14T16:21:33.000000Z",
  ///       "updated_at": "2026-01-14T16:21:33.000000Z"
  ///     }
  ///   ]
  /// }
  static const String GET_USER_NOTIFICATIONS = '/get_user/notifications';

  /// Mark Notification as Read
  /// POST /get_user/mark_as_read
  /// Request: {
  ///   "api_token": "<CURRENT_USER_API_TOKEN>",
  ///   "notification_id": <NOTIFICATION_ID>
  /// }
  /// Response: {
  ///   "status": true,
  ///   "message": "Notification marked as read"
  /// }
  static const String MARK_NOTIFICATION_AS_READ = '/get_user/mark_as_read';

  /// Get Unread Notification Count
  /// POST /get_user/unread_count
  /// Request: {
  ///   "api_token": "<CURRENT_USER_API_TOKEN>"
  /// }
  /// Response: {
  ///   "status": true,
  ///   "unread_count": 1
  /// }
  static const String GET_UNREAD_NOTIFICATION_COUNT = '/get_user/unread_count';

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

  /// Get Documents by Unit
  /// POST /documents/by_unit
  /// Request: { "token": "user_access_token" }
  /// Response: {
  ///   "status": true,
  ///   "message": "Documents retrieved successfully",
  ///   "data": [ ... ]
  /// }
  static const String GET_DOCUMENTS_BY_UNIT = '/documents/by_unit';

  /// Upload User Document
  /// POST /user_document_upload
  /// Request: {
  ///   "token": "user_token",
  ///   "document_file": "file",
  ///   "document_title": "Passport Copy",
  ///   "document_category": 2,
  ///   "document_description": "User passport front page"
  /// }
  /// Response: {
  ///   "status": true,
  ///   "message": "Document uploaded successfully",
  ///   "data": { ... }
  /// }
  static const String UPLOAD_USER_DOCUMENT = '/user_document_upload';

  /// Download Document
  /// POST /download_document
  /// Request: {
  ///   "token": "<CURRENT_USER_API_TOKEN>",
  ///   "document_id": <DOCUMENT_ID>
  /// }
  /// Response: File bytes (binary data)
  static const String DOWNLOAD_DOCUMENT = '/download_document';

  // Ticket / Issue Type Endpoints
  /// Get Issue Types (ticket categories)
  /// POST /issue-type/list
  /// Request: { "api_token": "<CURRENT_USER_API_TOKEN>" }
  /// Response: { "success": true, "total": 3, "data": [ { "id": 4, "issue_type_en": "...", "issue_type_it": "..." } ] }
  static const String GET_ISSUE_TYPES = '/issue-type/list';

  /// Create Issue Type
  /// POST /issue-type/create
  /// Request: { "api_token": "<CURRENT_USER_API_TOKEN>", "issue_type_en": "...", "issue_type_it": "..." }
  /// Response: { "success": true, "message": "Issue type created successfully", "data": { "id": 4, ... } }
  static const String CREATE_ISSUE_TYPE = '/issue-type/create';

  /// Get My Support Tickets
  /// POST /my-support-tickets
  /// Request: { "api_token": "<TOKEN>" }
  /// Response: { "status": true, "data": [ { "id": 12, "title": "...", ... } ] }
  static const String GET_MY_SUPPORT_TICKETS = '/my-support-tickets';

  /// Create Support Ticket
  /// POST /support-ticket/create
  /// Request: {
  ///   "api_token": "<TOKEN>",
  ///   "title": "...",
  ///   "description": "...",
  ///   "issue_type_id": 4,
  ///   "priority": "high",
  ///   "image": "data:image/jpeg;base64,..."  (optional)
  /// }
  /// Response: { "status": true, "message": "Support ticket created successfully.", "data": { ... } }
  static const String CREATE_SUPPORT_TICKET = '/support-ticket/create';

  // Maintenance Endpoints
  /// Get Maintenance Tasks
  /// GET /maintenance/list - Fetch maintenance tasks
  /// Headers: Authorization: Bearer {token} (automatically added by ApiService)
  static const String GET_MAINTENANCE_TASKS = '/maintenance/list';

  /// Residence-wise maintenance list
  /// POST /residence_wise/maintenance
  /// Request: { "residence_id": <int> }
  static const String POST_RESIDENCE_WISE_MAINTENANCE =
      '/residence_wise/maintenance';

  /// GET /maintenance_categories/list
  /// Response: {
  ///   "status": true,
  ///   "message": "Maintenance categories retrieved successfully",
  ///   "data": [
  ///     {
  ///       "id": 1,
  ///       "name": "Electrical",
  ///       "description": "All electrical maintenance related work",
  ///       "created_at": "2025-12-15T01:40:08.000000Z",
  ///       "updated_at": "2025-12-15T01:40:08.000000Z"
  ///     }
  ///   ]
  /// }
  static const String GET_MAINTENANCE_CATEGORIES = '/maintenance_categories/list';

  /// Create Maintenance Task
  /// POST /maintenance/store
  /// Request: {
  ///   "maintenance_title": "Fridge Monthly Service",
  ///   "maintenance_frequency": "Monthly",
  ///   "maintenance_note": "Check filters and gas level",
  ///   "maintenance_status": "pending",
  ///   "due_date": "2025-01-20",
  ///   "last_maintenance_date": "2024-12-20",
  ///   "maintenance_category_id": 1,
  ///   "maintenance_item_id": 1,
  ///   "residence_id": 48
  /// }
  /// Response: {
  ///   "status": true,
  ///   "message": "Maintenance created successfully",
  ///   "data": { ... }
  /// }
  static const String CREATE_MAINTENANCE_TASK = '/maintenance/store';

  /// Delete Maintenance Task
  /// DELETE /maintenance/delete/{id}
  /// Response: {
  ///   "status": true,
  ///   "message": "Maintenance deleted successfully"
  /// }
  static const String DELETE_MAINTENANCE_TASK = '/maintenance/delete';

  // ============================================================================
  // AI CHAT ENDPOINTS
  // ============================================================================

  /// Send AI Message
  /// POST /casazero-ai/send-message
  /// Request: {
  ///   "token": "<USER_API_TOKEN>",
  ///   "message": "<USER_MESSAGE>"
  /// }
  /// Response: {
  ///   "success": true,
  ///   "chat_id": 10,
  ///   "reply": "<AI_REPLY>",
  ///   "image": null
  /// }
  static const String AI_SEND_MESSAGE = '/casazero-ai/send-message';

  /// Get AI Message History
  /// POST /casazero-ai/get-message
  /// Request: {
  ///   "token": "<USER_API_TOKEN>"
  /// }
  /// Response: {
  ///   "success": true,
  ///   "data": {
  ///     "data": [
  ///       {
  ///         "id": 10,
  ///         "user_message": "...",
  ///         "ai_message": "...",
  ///         "image": null,
  ///         "created_at": "..."
  ///       }
  ///     ]
  ///   }
  /// }
  static const String AI_GET_MESSAGE_HISTORY = '/casazero-ai/get-message';

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
