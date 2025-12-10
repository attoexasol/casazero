// data/repositories/auth_repository.dart
// UPDATED WITH FCM TOKEN AND NEW API STRUCTURE

import 'package:get/get.dart';
import '../../core/services/api_service.dart';
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

      // Get FCM token (will be empty string if not available)
      String fcmToken = '';
      try {
        final fcmService = Get.find<FcmService>();
        if (fcmService.toString().contains('FcmService')) {
          fcmToken = await fcmService.getDeviceToken() ?? '';
        }
      } catch (e) {
        print('⚠️ FCM Service not available: $e');
      }

      // Get stored device token (for trusted device verification)
      final storedToken = _storageService.getDeviceToken() ?? '';

      print('📱 Device Info:');
      print('  Device ID: ${deviceInfo['device_id']}');
      print('  Device Name: ${deviceInfo['device_name']}');
      print('  Platform: ${deviceInfo['platform']}');
      print('  Location: ${deviceInfo['lat']}, ${deviceInfo['lng']}');
      print('  IP: ${deviceInfo['ip_address']}');
      print('  FCM Token: $fcmToken');
      print('  Phone: ${phone ?? 'not provided'}');
      print('  Stored Token: $storedToken');

      final response = await _apiService.post(
        ApiConstants.LOGIN,
        data: {
          'email': email,
          'phone': phone ?? '',
          'password': password,
          'device_id': deviceInfo['device_id'],
          'device_name': deviceInfo['device_name'],
          'platform': deviceInfo['platform'],
          'ip_address': deviceInfo['ip_address'],
          'lat': deviceInfo['lat'],
          'lng': deviceInfo['lng'],
          'fcm_token': fcmToken,
          'token': storedToken,
        },
      );

      print('✅ Login Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Status: ${response.data['status']}');
      print('  Message: ${response.data['message']}');
      print('  Is Trusted: ${response.data['is_trusted']}');
      print('  Access Token (response.token): ${response.data['token']}');

      if (response.statusCode == 200 && response.data['status'] == true) {
        // Save the new token from response for next login
        if (response.data['token'] != null) {
          await _storageService.saveDeviceToken(response.data['token']);
          print('💾 Device Token Saved (for trusted login): ${response.data['token']}');
        }

        return {
          'success': true,
          'user': UserModel.fromJson(response.data['user']),
          'access_token': response.data['token'],
          'is_trusted': response.data['is_trusted'] ?? false,
          'message': response.data['message'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('❌ Login Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      await _apiService.post(ApiConstants.LOGOUT);

      // Clear device token on logout
      await _storageService.clearDeviceToken();

      // Delete FCM token
      try {
        final fcmService = Get.find<FcmService>();
        if (fcmService.toString().contains('FcmService')) {
          await fcmService.deleteToken();
        }
      } catch (e) {
        print('⚠️ FCM Service not available during logout: $e');
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Forgot Password
  Future<bool> forgotPassword(String email) async {
    try {
      await _apiService.post(
        ApiConstants.FORGOT_PASSWORD,
        data: {'email': email},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Change Password (First Login)
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final userData = _storageService.getUserData();
      final userId = userData?['id'];

      if (userId == null) {
        return {'success': false, 'error': 'User not found in local storage'};
      }

      final response = await _apiService.post(
        ApiConstants.CHANGE_PASSWORD,
        data: {
          'user_id': userId,
          'old_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        },
      );

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

      if (response.statusCode == 200 && response.data['Status'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP sent to your email',
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to send email OTP',
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

      if (response.statusCode == 200 && response.data['Status'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP sent to your phone',
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to send SMS OTP',
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
  Future<UserModel?> getUserProfile() async {
    try {
      final response = await _apiService.get(ApiConstants.GET_USER_PROFILE);
      return UserModel.fromJson(response.data);
    } catch (e) {
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
