// data/repositories/auth_repository.dart
// UPDATED WITH FCM TOKEN AND NEW API STRUCTURE

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/utils/firebase_jwt_debug.dart';
import '../../core/utils/firebase_response_parser.dart';
import '../../core/utils/login_api_debug.dart';
import '../../core/services/api_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/device_info_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';
import '../../core/services/fcm_service.dart';

class AuthRepository {
  final ApiService _apiService = Get.find();
  final StorageService _storageService = Get.find();
  final DeviceInfoService _deviceInfoService = Get.find();

  // ============================================================================
  // LOGIN WITH TRUSTED DEVICE TRACKING + FCM TOKEN
  // ============================================================================

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      // Get device information
      final deviceInfo = await _deviceInfoService.getDeviceInfoForLogin();

      // Get FCM token. getDeviceToken waits for APNs on iOS and retries with
      // backoff; it returns null (never an empty string) when unavailable, and
      // the fcm_token key is omitted from the payload in that case.
      String? fcmToken;
      try {
        if (Get.isRegistered<FcmService>()) {
          fcmToken = await Get.find<FcmService>().getDeviceToken();
        }
      } catch (e) {
        print('⚠️ FCM Service not available: $e');
      }
      final hasFcmToken = fcmToken != null && fcmToken.trim().isNotEmpty;

      // Get stored device token (for trusted device verification)
      final storedToken = _storageService.getDeviceToken() ?? '';

      print('📱 Device Info:');
      print('  Device ID: ${deviceInfo['device_id']}');
      print('  Device Name: ${deviceInfo['device_name']}');
      print('  Platform: ${deviceInfo['platform']}');
      print('  Location: ${deviceInfo['lat']}, ${deviceInfo['lng']}');
      print('  IP: ${deviceInfo['ip_address']}');
      print(
        '  FCM Token: ${hasFcmToken ? fcmToken : 'unavailable (omitted from payload)'}',
      );
      print('  Phone: ${phone ?? 'not provided'}');
      print('  Stored Token: $storedToken');

      final loginUrl = ApiConstants.buildUrl(ApiConstants.LOGIN);
      final loginPayload = <String, dynamic>{
        'email': email,
        'phone': phone ?? '',
        'password': password,
        'device_id': deviceInfo['device_id'],
        'device_name': deviceInfo['device_name'],
        'platform': deviceInfo['platform'],
        'ip_address': deviceInfo['ip_address'],
        'lat': deviceInfo['lat'],
        'lng': deviceInfo['lng'],
        'token': storedToken,
      };

      if (hasFcmToken) {
        loginPayload['fcm_token'] = fcmToken;
      } else {
        print(
          '⚠️ [Login] fcm_token omitted — device produced no FCM token in time',
        );
      }

      LoginApiDebug.logRequest(
        method: 'POST',
        fullUrl: loginUrl,
        body: loginPayload,
      );

      final response = await _apiService.post(
        ApiConstants.LOGIN,
        data: loginPayload,
      );

      final body = FirebaseResponseParser.normalizeBody(response.data);

      LoginApiDebug.logResponse(
        fullUrl: loginUrl,
        statusCode: response.statusCode,
        rawData: response.data,
        normalizedBody: body,
      );

      if (body == null) {
        debugPrint('[LOGIN] ERROR — response body is not a Map');
        return {'success': false, 'error': 'Invalid login response format'};
      }
      final statusOk = _isSuccessStatus(body['status']);

      if (response.statusCode == 200 && statusOk) {
        if (body['token'] != null) {
          await _storageService.saveDeviceToken(body['token'].toString());
        }

        if (body['user'] is Map) {
          final user = UserModel.fromJson(
            Map<String, dynamic>.from(body['user'] as Map),
          );
          await _storageService.saveUserData(user.toJson());
        }
        if (body['token'] != null) {
          await _storageService.saveAccessToken(body['token'].toString());
        }

        final firebaseSignedIn =
            await _persistAndSignInFirebaseFromLoginBody(body);

        final firebaseToken = _storageService.getStoredFirebaseToken();
        final firebaseProjectId = _storageService.getFirebaseProjectId();

        return {
          'success': true,
          'user': UserModel.fromJson(
            Map<String, dynamic>.from(body['user'] as Map),
          ),
          'access_token': body['token']?.toString(),
          'firebase_token': firebaseToken,
          'firebase_project_id': firebaseProjectId,
          'firebase_signed_in': firebaseSignedIn,
          'is_trusted': body['is_trusted'] ?? false,
          'message': body['message'],
        };
      } else {
        final msg = body?['message'] ?? response.data?['message'];
        return {
          'success': false,
          'error': msg?.toString() ?? 'Login failed',
        };
      }
    } catch (e) {
      print('❌ Login Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Top-level parse → local storage → immediate Firebase sign-in (creates Auth user).
  Future<bool> _persistAndSignInFirebaseFromLoginBody(
    Map<String, dynamic> body,
  ) async {
    // Laravel may send snake_case (firebase_token) or camelCase (firebaseToken) at top level.
    final firebaseToken = FirebaseResponseParser.extractFirebaseToken(body);
    final projectId = FirebaseResponseParser.extractFirebaseProjectId(body);

    print(
      '[LOGIN] parsed token from key: '
      '${body['firebase_token'] != null ? "firebase_token" : (body['firebaseToken'] != null ? "firebaseToken" : "none")}',
    );

    if (firebaseToken == null) {
      await _storageService.clearFirebaseToken();
      print('[LOGIN] ERROR — no top-level firebase_token or firebaseToken');
      return false;
    }

    await _storageService.saveFirebaseToken(firebaseToken);
    if (projectId != null && projectId.isNotEmpty) {
      await _storageService.saveFirebaseProjectId(projectId);
    }
    print('[LOGIN] stored firebase_token successfully');
    _storageService.debugPrintStorageKeys();

    final payload = FirebaseJwtDebug.decodePayload(firebaseToken);
    print('[LOGIN] JWT ${FirebaseJwtDebug.describeClaims(payload)}');

    return _signInWithStoredFirebaseToken(
      firebaseToken,
      source: 'login',
    );
  }

  /// Signs in with custom token — Firebase Auth user is created on first success.
  Future<bool> _signInWithStoredFirebaseToken(
    String token, {
    required String source,
  }) async {
    if (Firebase.apps.isEmpty) {
      print('[FirebaseAuth] ABORT — Firebase not initialized');
      return false;
    }

    print('[FirebaseAuth] signInWithCustomToken START ($source)');
    print('[FirebaseAuth] token length=${token.length}');
    try {
      print(
        '[FirebaseAuth] client projectId=${Firebase.app().options.projectId}',
      );
    } catch (_) {}

    try {
      final fb = Get.find<FirebaseAuthService>();
      final expectedUid = _storageService.getUserData()?['id']?.toString();
      final ok = await fb.signInWithCustomToken(
        token,
        expectedLaravelUserId: expectedUid,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;
      print('[FirebaseAuth] SUCCESS uid=$uid');
      print('[FirebaseAuth] currentUser=${FirebaseAuth.instance.currentUser?.uid}');
      return ok && uid != null;
    } catch (e, st) {
      print('[FirebaseAuth] FAILED');
      print('[FirebaseAuth] error=$e');
      print('[FirebaseAuth] stackTrace:\n$st');
      try {
        print('[FirebaseAuth] projectId=${Firebase.app().options.projectId}');
      } catch (_) {}
      print('[FirebaseAuth] currentUser=${FirebaseAuth.instance.currentUser?.uid}');
      return false;
    }
  }

  bool _isSuccessStatus(dynamic status) {
    if (status == true || status == 1) return true;
    if (status is String) {
      final s = status.toLowerCase();
      return s == 'true' || s == '1';
    }
    return false;
  }

  // Logout
  /// POST /user/logout
  /// API URL: https://backend.casazero.site/api/user/logout
  /// Request: { "token": "USER_API_TOKEN" }
  /// Response: { "status": true, "message": "Logout successful" }
  /// 
  /// Gets the logged-in user's saved API token from storage and sends it in the request body
  Future<Map<String, dynamic>> logout() async {
    try {
      // Get the logged-in user's saved API token (access token) from storage
      // This is the USER_API_TOKEN that was saved during login
      final token = _storageService.getAccessToken();

      if (token == null || token.isEmpty) {
        print('⚠️  No access token found for logout API call');
        // Still proceed with clearing storage
        return {
          'success': true,
          'message': 'Logout completed (no token to send)',
        };
      }

      print('🚪 Calling logout API with token: ${token.substring(0, 10)}...');
      print('📍 Endpoint: ${ApiConstants.LOGOUT}');
      print('📦 Request Body: { "token": "${token.substring(0, 10)}..." }');

      // Call logout API with token in request body
      // API URL: https://backend.casazero.site/api/user/logout
      final response = await _apiService.post(
        ApiConstants.LOGOUT,
        data: {'token': token},
      );

      print('✅ Logout API Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Status: ${response.data['status']}');
      print('  Message: ${response.data['message']}');

      if (response.statusCode == 200 && response.data['status'] == true) {
        // Clear device token on logout
        await _storageService.clearDeviceToken();
        await _storageService.clearFirebaseToken();
        await _storageService.clearFirebaseProjectId();

        // Sign out from Firebase (use FirebaseAuthService to clear _lastSignedInUid)
        try {
          await Get.find<FirebaseAuthService>().signOut();
          print('✅ Firebase Auth: Signed out');
        } catch (e) {
          print('⚠️ Firebase Auth: Sign out error (ignored): $e');
        }

        // Delete FCM token
        try {
          if (Get.isRegistered<FcmService>()) {
            await Get.find<FcmService>().deleteToken();
          }
        } catch (e) {
          print('⚠️ FCM Service not available during logout: $e');
        }

        return {
          'success': true,
          'message': response.data['message'] ?? 'Logout successful',
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Logout failed',
        };
      }
    } catch (e) {
      print('❌ Error during logout API call: $e');
      // Even if API fails, we should still clear local storage
      return {'success': false, 'error': 'Failed to logout. Please try again.'};
    }
  }

  /// Signs into Firebase using locally stored login `firebase_token` only.
  /// Never calls any backend Firebase token endpoint.
  /// App restart / splash / OTP — read stored login token only (no API).
  Future<bool> syncFirebaseAuthAfterLogin() async {
    final storedToken = _storageService.getStoredFirebaseToken();

    print('storedToken exists=${storedToken != null}');
    print('storedToken length=${storedToken?.length ?? 0}');
    print(
      'firebase_project_id=${_storageService.getFirebaseProjectId() ?? "null"}',
    );

    if (storedToken == null || storedToken.isEmpty) {
      print('[AuthRepository] No stored Firebase token — login required');
      _storageService.debugPrintStorageKeys();
      return false;
    }

    if (FirebaseAuth.instance.currentUser != null) {
      print(
        '[AuthRepository] Firebase already signed in uid=${FirebaseAuth.instance.currentUser!.uid}',
      );
      return true;
    }

    return _signInWithStoredFirebaseToken(storedToken, source: 'sync');
  }

  // Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _apiService.post(
        ApiConstants.FORGOT_PASSWORD,
        data: {'email': email},
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return {
          'success': true,
          'message':
              response.data['message'] ??
              'Password reset email sent successfully!',
          'user_id':
              response.data['data']?['user_id'] ?? response.data['user_id'],
        };
      } else {
        return {
          'success': false,
          'error':
              response.data['message'] ?? 'Failed to send password reset email',
        };
      }
    } catch (e) {
      print('❌ Error sending forgot password request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Reset Password (Forgot Password Flow)
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.RESET_PASSWORD,
        data: {
          'email': email,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Password reset successfully!',
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Change Password
  /// POST /user/forget_password
  /// API URL: https://backend.casazero.site/api/user/forget_password
  /// Request: {
  ///   "user_id": 19,
  ///   "old_password": "password123",
  ///   "new_password": "CasaZero@024017",
  ///   "new_password_confirmation": "CasaZero@024017"
  /// }
  /// Response: {
  ///   "status": true,
  ///   "message": "Password changed successfully!"
  /// }
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Get user data from storage
      final userData = _storageService.getUserData();
      final userId = userData?['id'];

      if (userId == null) {
        print('❌ [AuthRepository] User ID not found in local storage');
        return {'success': false, 'error': 'User not found in local storage'};
      }

      // Ensure user_id is an integer (API expects int)
      final userIdInt = userId is int ? userId : int.tryParse(userId.toString());
      
      if (userIdInt == null) {
        print('❌ [AuthRepository] Invalid user ID format: $userId');
        return {'success': false, 'error': 'Invalid user ID format'};
      }

      print('🔄 [AuthRepository] Changing password...');
      print('📍 Endpoint: ${ApiConstants.CHANGE_PASSWORD}');
      print('👤 User ID: $userIdInt');
      print('📦 Request Body: {');
      print('   "user_id": $userIdInt,');
      print('   "old_password": "***",');
      print('   "new_password": "***",');
      print('   "new_password_confirmation": "***"');
      print(' }');

      // Call API with POST method
      final response = await _apiService.post(
        ApiConstants.CHANGE_PASSWORD,
        data: {
          'user_id': userIdInt,
          'old_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        },
      );

      print('✅ [AuthRepository] Change Password API Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Status: ${response.data['status']}');
      print('  Message: ${response.data['message']}');

      // Check if response is successful
      if (response.statusCode == 200 && response.data['status'] == true) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Password changed successfully!',
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      print('❌ [AuthRepository] Error changing password: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get Document Password (read-only; for display on document password screen)
  /// POST /user/get-document-password
  /// Request: { "token": "<stored_user_token>" }
  /// Response: { "status": true, "document_password": "..." }
  /// On failure or missing token, returns success: false; do not log or persist password.
  Future<Map<String, dynamic>> getDocumentPassword() async {
    try {
      final accessToken = _storageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return {'success': false};
      }
      final response = await _apiService.post(
        ApiConstants.GET_DOCUMENT_PASSWORD,
        data: {'token': accessToken},
      );
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['status'] == true) {
        final documentPassword = response.data['document_password']?.toString();
        if (documentPassword != null && documentPassword.isNotEmpty) {
          return {'success': true, 'document_password': documentPassword};
        }
      }
      return {'success': false};
    } catch (_) {
      return {'success': false};
    }
  }

  // Set Document Password
  /// POST /user/set-document-password
  /// API URL: https://backend.casazero.site/api/user/set-document-password
  /// Request: {
  ///   "token": "USER_API_TOKEN",
  ///   "password": "123456",
  ///   "confirm_password": "123456"
  /// }
  /// Response: {
  ///   "status": true,
  ///   "message": "Document password set successfully"
  /// }
  Future<Map<String, dynamic>> setDocumentPassword({
    required String password,
    required String confirmPassword,
  }) async {
    try {
      // Get user token from storage
      final accessToken = _storageService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        print('❌ [AuthRepository] Access token not found in storage');
        return {'success': false, 'error': 'User not authenticated'};
      }

      print('🔄 [AuthRepository] Setting document password...');
      print('📍 Endpoint: ${ApiConstants.SET_DOCUMENT_PASSWORD}');
      print('📦 Request Body: {');
      print('   "token": "${accessToken.substring(0, 20)}...",');
      print('   "password": "***",');
      print('   "confirm_password": "***"');
      print(' }');

      // Call API with POST method
      final response = await _apiService.post(
        ApiConstants.SET_DOCUMENT_PASSWORD,
        data: {
          'token': accessToken,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );

      print('✅ [AuthRepository] Set Document Password API Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Status: ${response.data['status']}');
      print('  Message: ${response.data['message']}');

      // Check if response is successful
      if (response.statusCode == 200 && response.data['status'] == true) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Document password set successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to set document password',
        };
      }
    } catch (e) {
      print('❌ [AuthRepository] Error setting document password: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================================================
  // 2FA SETUP METHODS
  // ============================================================================

  Future<Map<String, dynamic>> setupAuthenticator2FA() async {
    try {
      final userData = _storageService.getUserData();
      final userId = userData?['id'];

      if (userId == null) {
        return {'success': false, 'error': 'User not found in local storage'};
      }

      final response = await _apiService.get(
        '${ApiConstants.SETUP_AUTHENTICATOR_2FA}/$userId',
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final data = response.data['data'];
        return {
          'success': true,
          'secret': data['secret_key'],
          'qr_base64': data['qr_base64'],
          'otpauth_url': data['otpauth_url'],
          'email': data['email'],
          'message': response.data['message'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to setup authenticator',
        };
      }
    } catch (e) {
      print('Error setting up authenticator 2FA: $e');
      return {
        'success': false,
        'error': 'Failed to setup authenticator. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> verifyAuthenticatorQRCode(String code) async {
    try {
      final userData = _storageService.getUserData();
      final userId = userData?['id'];

      if (userId == null) {
        return {'success': false, 'error': 'User not found in local storage'};
      }

      int codeNumber;
      try {
        codeNumber = int.parse(code);
      } catch (e) {
        return {'success': false, 'error': 'Invalid code format'};
      }

      // Get device information for verification
      final deviceInfo = await _deviceInfoService.getDeviceInfoForLogin();

      print('🔐 Verifying Authenticator QR Code with Device Info:');
      print('  User ID: $userId');
      print('  Code: $code');
      print('  Device ID: ${deviceInfo['device_id']}');
      print('  Device Name: ${deviceInfo['device_name']}');
      print('  Platform: ${deviceInfo['platform']}');
      print('  Location: ${deviceInfo['lat']}, ${deviceInfo['lng']}');
      print('  IP: ${deviceInfo['ip_address']}');

      final response = await _apiService.post(
        ApiConstants.VERIFY_QR_CODE,
        data: {
          'user_id': userId,
          'code': codeNumber.toString(),
          'device_id': deviceInfo['device_id'],
          'device_name': deviceInfo['device_name'],
          'platform': deviceInfo['platform'],
          'ip_address': deviceInfo['ip_address'],
          'lat': deviceInfo['lat'],
          'lng': deviceInfo['lng'],
        },
      );

      print('✅ Authenticator Verification Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Response: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? '2FA Verified Successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Verification failed',
        };
      }
    } catch (e) {
      print('❌ Error verifying authenticator QR code: $e');
      return {
        'success': false,
        'error': 'Failed to verify code. Please try again.',
      };
    }
  }

  // ============================================================================
  // EMAIL OTP METHODS (WITH DEVICE INFO)
  // ============================================================================

  Future<Map<String, dynamic>> sendEmailOTP() async {
    try {
      final userData = _storageService.getUserData();
      final userId = userData?['id'];

      if (userId == null) {
        return {'success': false, 'error': 'User not found in local storage'};
      }

      final response = await _apiService.post(
        ApiConstants.SEND_EMAIL_OTP,
        data: {'user_id': userId},
      );

      // Check for both 'Status' (capital) and 'status' (lowercase) to handle API variations
      final status = response.data['Status'] ?? response.data['status'];
      final isSuccess = response.statusCode == 200 && status == true;

      if (isSuccess) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP sent to your email',
        };
      } else {
        // Only return error if it's actually an error, not a success message
        final errorMessage = response.data['message'] ?? 'Failed to send email OTP';
        // If message contains "OTP sent" or "sent to", it's actually a success, not an error
        if (errorMessage.toLowerCase().contains('otp sent') || 
            errorMessage.toLowerCase().contains('sent to')) {
          // Treat as success even if status check failed
          return {
            'success': true,
            'message': errorMessage,
          };
        }
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      print('Error sending email OTP: $e');
      return {
        'success': false,
        'error': 'Failed to send email OTP. Please try again.',
      };
    }
  }

  /// Verify Email OTP WITH DEVICE INFO
  Future<Map<String, dynamic>> verifyEmailOTP(String otp) async {
    try {
      final userData = _storageService.getUserData();
      final userId = userData?['id'];

      if (userId == null) {
        return {'success': false, 'error': 'User not found in local storage'};
      }

      // Convert OTP to string
      String otpString = otp.trim();

      // Get device information for verification
      final deviceInfo = await _deviceInfoService.getDeviceInfoForLogin();

      print('📱 Verifying Email OTP with Device Info:');
      print('  User ID: $userId');
      print('  OTP: $otpString');
      print('  Device Info: ${deviceInfo['device_name']}');

      final response = await _apiService.post(
        ApiConstants.VERIFY_EMAIL_OTP,
        data: {
          'user_id': userId,
          'otp': otpString,
          'device_id': deviceInfo['device_id'],
          'device_name': deviceInfo['device_name'],
          'platform': deviceInfo['platform'],
          'ip_address': deviceInfo['ip_address'],
          'lat': deviceInfo['lat'],
          'lng': deviceInfo['lng'],
        },
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Email OTP verified successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Invalid OTP code',
        };
      }
    } catch (e) {
      print('❌ Error verifying email OTP: $e');
      return {
        'success': false,
        'error': 'Failed to verify OTP. Please try again.',
      };
    }
  }

  // ============================================================================
  // SMS OTP METHODS (WITH DEVICE INFO - SIMILAR TO EMAIL)
  // ============================================================================

  Future<Map<String, dynamic>> sendSMSOTP() async {
    try {
      final userData = _storageService.getUserData();
      final userId = userData?['id'];

      if (userId == null) {
        return {'success': false, 'error': 'User not found in local storage'};
      }

      final response = await _apiService.post(
        ApiConstants.SEND_SMS_OTP,
        data: {'user_id': userId},
      );

      // Check for both 'Status' (capital) and 'status' (lowercase) to handle API variations
      final status = response.data['Status'] ?? response.data['status'];
      final isSuccess = response.statusCode == 200 && status == true;

      if (isSuccess) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP sent to your phone',
        };
      } else {
        // Only return error if it's actually an error, not a success message
        final errorMessage = response.data['message'] ?? 'Failed to send SMS OTP';
        // If message contains "OTP sent" or "sent to", it's actually a success, not an error
        if (errorMessage.toLowerCase().contains('otp sent') || 
            errorMessage.toLowerCase().contains('sent to')) {
          // Treat as success even if status check failed
          return {
            'success': true,
            'message': errorMessage,
          };
        }
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      print('Error sending SMS OTP: $e');
      return {
        'success': false,
        'error': 'Failed to send SMS OTP. Please try again.',
      };
    }
  }

  /// Verify SMS OTP WITH DEVICE INFO
  /// Similar to email OTP verification
  Future<Map<String, dynamic>> verifySMSOTP(String otp) async {
    try {
      final userData = _storageService.getUserData();
      final userId = userData?['id'];

      if (userId == null) {
        return {'success': false, 'error': 'User not found in local storage'};
      }

      // Convert OTP to string
      String otpString = otp.trim();

      // Get device information for verification
      final deviceInfo = await _deviceInfoService.getDeviceInfoForLogin();

      print('📱 Verifying SMS OTP with Device Info:');
      print('  User ID: $userId');
      print('  OTP: $otpString');
      print('  Device Info: ${deviceInfo['device_name']}');

      final response = await _apiService.post(
        ApiConstants.VERIFY_SMS_OTP,
        data: {
          'user_id': userId,
          'otp': otpString,
          'device_id': deviceInfo['device_id'],
          'device_name': deviceInfo['device_name'],
          'platform': deviceInfo['platform'],
          'ip_address': deviceInfo['ip_address'],
          'lat': deviceInfo['lat'],
          'lng': deviceInfo['lng'],
        },
      );

      if (response.statusCode == 200 && response.data['Status'] == true) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'SMS OTP verified successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Invalid SMS OTP',
        };
      }
    } catch (e) {
      print('Error verifying SMS OTP: $e');
      return {
        'success': false,
        'error': 'Failed to verify SMS OTP. Please try again.',
      };
    }
  }

  // ============================================================================
  // UNIFIED OTP METHODS
  // ============================================================================

  Future<Map<String, dynamic>> sendOTP({required String method}) async {
    switch (method.toLowerCase()) {
      case 'email':
        return await sendEmailOTP();
      case 'sms':
        return await sendSMSOTP();
      case 'authenticator':
        return {
          'success': true,
          'message': 'Use your authenticator app to generate code',
        };
      default:
        return {'success': false, 'error': 'Invalid 2FA method'};
    }
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String code,
    required String method,
  }) async {
    switch (method.toLowerCase()) {
      case 'email':
        return await verifyEmailOTP(code);
      case 'sms':
        return await verifySMSOTP(code);
      case 'authenticator':
        return await verifyAuthenticatorQRCode(code);
      default:
        return {'success': false, 'error': 'Invalid 2FA method'};
    }
  }

  // ============================================================================
  // DISABLE 2FA
  // ============================================================================

  Future<Map<String, dynamic>> disable2FA() async {
    try {
      final userData = _storageService.getUserData();
      final userId = userData?['id'];

      if (userId == null) {
        return {'success': false, 'error': 'User not found in local storage'};
      }

      final response = await _apiService.get(
        '${ApiConstants.DISABLE_2FA}/$userId',
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final data = response.data['data'];

        final updatedUserData = {
          ...?userData,
          'id': data['user_id'],
          'name': data['user_name'],
          'email': data['email'],
          'two_fa_method': data['two_fa_method'],
          'is_two_fa_status': data['is_two_fa_status'],
        };

        await _storageService.saveUserData(updatedUserData);

        return {
          'success': true,
          'message':
              response.data['message'] ??
              'Two-factor authentication disabled successfully.',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to disable 2FA',
        };
      }
    } catch (e) {
      print('Error disabling 2FA: $e');
      return {
        'success': false,
        'error': 'Failed to disable 2FA. Please try again.',
      };
    }
  }

  // Get User Profile
  /// POST /user/profile
  /// API URL: https://backend.casazero.site/api/user/profile
  /// Request: { "token": "USER_API_TOKEN" }
  /// Response: { "status": true, "message": "...", "data": {...} }
  /// 
  /// Gets the logged-in user's saved API token from storage and sends it in the request body
  Future<UserModel?> getUserProfile() async {
    try {
      // Get the logged-in user's saved API token (access token) from storage
      final token = _storageService.getAccessToken();

      if (token == null || token.isEmpty) {
        print('⚠️ [AuthRepository] No access token found for getUserProfile API call');
        return null;
      }

      print('📥 [AuthRepository] Fetching user profile...');
      print('📍 Endpoint: ${ApiConstants.GET_USER_PROFILE}');
      print('📦 Request Body: { "token": "${token.substring(0, 10)}..." }');

      // Call API with POST method and token in request body
      final response = await _apiService.post(
        ApiConstants.GET_USER_PROFILE,
        data: {'token': token},
      );

      print('✅ [AuthRepository] User Profile API Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Status: ${response.data['status']}');
      print('  Message: ${response.data['message']}');

      // Check if response is successful and has data
      if (response.statusCode == 200 && 
          response.data['status'] == true && 
          response.data['data'] != null) {
        // Parse user data from response.data['data']
        final userData = response.data['data'] as Map<String, dynamic>;
        return UserModel.fromJson(userData);
      } else {
        print('⚠️ [AuthRepository] Invalid response format or missing data');
        return null;
      }
    } catch (e) {
      print('❌ [AuthRepository] Error fetching user profile: $e');
      return null;
    }
  }

  /// Update 2FA Status - Called after successful OTP verification
  /// POST /update/2fa_status
  /// Request: { "user_id": 8, "is_two_fa_status": 1 }
  /// Pass 1 for activation, 0 for deactivation
  Future<Map<String, dynamic>> update2FAStatus({
    required int userId,
    required int status, // 1 for active, 0 for inactive
  }) async {
    try {
      print('📡 Updating 2FA Status:');
      print('  User ID: $userId');
      print('  Status: $status (${status == 1 ? "ACTIVATE" : "DEACTIVATE"})');

      final response = await _apiService.post(
        ApiConstants.UPDATE_2FA_STATUS,
        data: {'user_id': userId, 'is_two_fa_status': status},
      );

      print('✅ 2FA Status Update Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'message':
              response.data['message'] ??
              'Two-factor authentication status updated successfully',
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to update 2FA status',
        };
      }
    } catch (e) {
      print('❌ Error updating 2FA status: $e');
      return {
        'success': false,
        'error': 'Failed to update 2FA status. Please try again.',
      };
    }
  }
}
