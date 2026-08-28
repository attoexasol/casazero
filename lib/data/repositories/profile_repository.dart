// data/repositories/profile_repository.dart

import 'dart:convert' as convert;
import 'package:casazero/core/constants/api_constants.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../models/trusted_device_model.dart';
import '../models/user_model.dart';
import 'package:dio/dio.dart' as dio;
import 'package:casazero/core/logging/diagnostic_logger.dart';

class ProfileRepository {
  final ApiService _apiService = Get.find();
  final StorageService _storageService = Get.find();

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    String? userName,
    String? email,
    String? phone,
    String? language,
    String? profileImage,
    bool? isDocumentNotify,
    bool? isMaintenanceNotify,
    bool? isChatNotify,
    bool? isSupportTicketNotify,
    String? twoFaMethod,
    String? residenceName,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    DiagnosticLogger.instance.debug('🟢 [ProfileRepository] updateProfile() called for userId: $userId');
    try {
      // Token required by backend for auth (same pattern as getUserProfile, logout, etc.)
      final token = _storageService.getAccessToken();
      if (token == null || token.isEmpty) {
        DiagnosticLogger.instance.error('❌ [ProfileRepository] No access token found');
        return {'success': false, 'error': 'User token not found. Please login again.'};
      }

      // Prepare request body (include token for backend auth)
      final Map<String, dynamic> requestBody = {'token': token};

      // Add fields only if they are not null
      if (userName != null) requestBody['user_name'] = userName;
      if (email != null) requestBody['email'] = email;
      if (phone != null) requestBody['phone'] = phone;
      if (language != null) requestBody['language'] = language;
      if (profileImage != null) requestBody['profile_image'] = profileImage;
      if (isDocumentNotify != null) requestBody['is_document_notify'] = isDocumentNotify;
      if (isMaintenanceNotify != null) requestBody['is_maintenance_notify'] = isMaintenanceNotify;
      if (isChatNotify != null) requestBody['is_chat_notify'] = isChatNotify;
      if (isSupportTicketNotify != null) requestBody['is_support_ticket_notify'] = isSupportTicketNotify;
      if (twoFaMethod != null) requestBody['two_fa_method'] = twoFaMethod;
      if (residenceName != null) requestBody['residence_name'] = residenceName;
      if (address != null) requestBody['address'] = address;
      if (latitude != null) requestBody['latitude'] = latitude;
      if (longitude != null) requestBody['longitude'] = longitude;
      if (description != null) requestBody['description'] = description;

      // Print detailed request information
      final endpoint = "${ApiConstants.UPDATE_USER_PROFILE}/$userId";
      final fullUrl = '${ApiConstants.BASE_URL}$endpoint';
      
      DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');
      DiagnosticLogger.instance.debug('📤 [ProfileRepository] UPDATE PROFILE REQUEST');
      DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');
      DiagnosticLogger.instance.debug('🌐 Method: POST');
      DiagnosticLogger.instance.debug('📍 Endpoint: $endpoint');
      DiagnosticLogger.instance.debug('🔗 Full URL: $fullUrl');
      DiagnosticLogger.instance.debug('👤 User ID: $userId');
      DiagnosticLogger.instance.debug('📦 Request Body (JSON):');
      try {
        final safeBody = Map<String, dynamic>.from(requestBody);
        if (safeBody['token'] != null) safeBody['token'] = '${(safeBody['token'] as String).substring(0, 10)}...';
        DiagnosticLogger.instance.debug(convert.JsonEncoder.withIndent('   ').convert(safeBody));
      } catch (e) {
        DiagnosticLogger.instance.debug('   [request body]');
      }
      DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');

      // Make API call
      final response = await _apiService.post(
        endpoint,
        data: requestBody,
      );

      DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');
      DiagnosticLogger.instance.debug('📥 [ProfileRepository] UPDATE PROFILE RESPONSE');
      DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');
      DiagnosticLogger.instance.debug('📊 Status Code: ${response.statusCode}');
      DiagnosticLogger.instance.debug('📦 Response Data (JSON):');
      try {
        DiagnosticLogger.instance.debug(convert.JsonEncoder.withIndent('   ').convert(response.data));
      } catch (e) {
        DiagnosticLogger.instance.debug('   ${response.data.toString()}');
      }
      DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');

      // Safe response handling (response.data may be null or not a Map)
      final data = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : <String, dynamic>{};
      final status = data['status'];
      final isSuccess = (response.statusCode == 200 || response.statusCode == 201) &&
          (status == true || status == 'true' || status == 1 || status == '1');

      if (isSuccess) {
        // Update user data in storage when backend returns updated user
        final userData = data['data'];
        if (userData != null && userData is Map<String, dynamic>) {
          try {
            final updatedUser = UserModel.fromJson(userData);
            await _storageService.saveUserData(updatedUser.toJson());
          } catch (e) {
            DiagnosticLogger.instance.warning('⚠️ [ProfileRepository] Could not parse updated user: $e');
          }
        }

        return {
          'success': true,
          'message': data['message']?.toString() ?? 'Profile updated successfully!',
          'data': userData,
        };
      } else {
        final errorMsg = data['message']?.toString() ?? data['error']?.toString() ?? 'Failed to update profile';
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [ProfileRepository] updateProfile error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage({
    required int userId,
    required String filePath,
  }) async {
    try {
      // Create FormData for file upload
      dio.FormData formData = dio.FormData.fromMap({
        'profile_image': await dio.MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      // Make API call
      final response = await _apiService.post(
        '/user/profile_image/update/$userId',
        data: formData,
      );

      // Handle success response
      if (response.statusCode == 200 && response.data['status'] == true) {
        // Get the updated image URL
        final imageUrl = response.data['image_url'];

        // Update user data in storage with new profile image
        final userData = _storageService.getUserData();
        if (userData != null) {
          final user = UserModel.fromJson(userData);
          final updatedUser = user.copyWith(profileImage: imageUrl);
          await _storageService.saveUserData(updatedUser.toJson());
        }

        return {
          'success': true,
          'message': response.data['message'] ?? 'Profile image updated successfully',
          'image_url': imageUrl,
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to upload profile image',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Upload failed: ${e.toString()}',
      };
    }
  }

  /// Update profile from current user data in storage
  Future<Map<String, dynamic>> updateProfileFromStorage() async {
    try {
      // Get user data from storage
      final userData = _storageService.getUserData();

      if (userData == null) {
        return {
          'success': false,
          'error': 'No user data found in storage',
        };
      }

      final user = UserModel.fromJson(userData);

      // Call update profile with user data
      return await updateProfile(
        userId: user.id,
        userName: user.userName,
        email: user.email,
        phone: user.phone,
        language: user.language,
        profileImage: user.profileImage,
        isDocumentNotify: user.isDocumentNotify,
        isMaintenanceNotify: user.isMaintenanceNotify,
        isChatNotify: user.isChatNotify,
        isSupportTicketNotify: user.isSupportTicketNotify,
        twoFaMethod: user.twoFaMethod,
        residenceName: user.residenceId, // Using residenceId as residenceName for now
        address: null, // Not available in current UserModel
        latitude: null, // Not available in current UserModel
        longitude: null, // Not available in current UserModel
        description: null, // Not available in current UserModel
      );
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to prepare profile data: ${e.toString()}',
      };
    }
  }
  Future<Map<String, dynamic>> getAllTrustedDevices() async {
    try {
      final userData = _storageService.getUserData();
      final userId = userData?['id'];

      if (userId == null) {
        return {
          'success': false,
          'error': 'User not found in local storage',
        };
      }

      DiagnosticLogger.instance.info('📱 Fetching trusted devices for user ID: $userId');

      final response = await _apiService.get(
        '${ApiConstants.GET_ALL_TRUSTED_DEVICES}/$userId',
      );

      DiagnosticLogger.instance.info('✅ Trusted Devices Response:');
      DiagnosticLogger.instance.debug('  Status Code: ${response.statusCode}');
      DiagnosticLogger.instance.debug('  Status: ${response.data['status']}');
      DiagnosticLogger.instance.debug('  Message: ${response.data['message']}');
      DiagnosticLogger.instance.debug('  Device Count: ${(response.data['trusted_devices'] as List?)?.length ?? 0}');

      if (response.statusCode == 200 && response.data['status'] == true) {
        final devicesJson = response.data['trusted_devices'] as List<dynamic>;
        final devices = devicesJson
            .map((json) => TrustedDeviceModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'devices': devices,
          'message': response.data['message'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch trusted devices',
        };
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ Error fetching trusted devices: $e');
      return {
        'success': false,
        'error': 'Failed to fetch trusted devices. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> deleteUserDevice(String deviceId) async {
    try {
      // Get user ID from storage
      final userData = _storageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not logged in',
        };
      }

      DiagnosticLogger.instance.debug('🗑️ Deleting device: $deviceId for user: $userId');

      final response = await _apiService.post(
        ApiConstants.DELETE_SPECIFIC_USER_DEVICE,
        data: {
          'user_id': userId.toString(),
          'device_id': deviceId,
        },
      );

      DiagnosticLogger.instance.info('✅ Delete Device Response:');
      DiagnosticLogger.instance.debug('  Status Code: ${response.statusCode}');
      DiagnosticLogger.instance.debug('  Status: ${response.data['status']}');
      DiagnosticLogger.instance.debug('  Message: ${response.data['message']}');

      if (response.statusCode == 200 && response.data['status'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Device removed successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to remove device',
        };
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ Error deleting device: $e');
      return {
        'success': false,
        'error': 'Failed to remove device. Please try again.',
      };
    }
  }


  /// Change user language
  /// POST /change/language
  /// Request: { "user_id": 8, "language": "en" }
  Future<Map<String, dynamic>> changeLanguage({
    required int userId,
    required String language,
  }) async {
    try {
      DiagnosticLogger.instance.debug('🌐 Changing language for user $userId to: $language');

      final response = await _apiService.post(
        ApiConstants.CHANGE_LANGUAGE,
        data: {
          'user_id': userId,
          'language': language,
        },
      );

      DiagnosticLogger.instance.info('✅ Change Language Response:');
      DiagnosticLogger.instance.debug('  Status Code: ${response.statusCode}');
      DiagnosticLogger.instance.debug('  Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Update language in local storage
        final userData = _storageService.getUserData();
        if (userData != null) {
          final user = UserModel.fromJson(userData);
          final updatedUser = user.copyWith(language: language);
          await _storageService.saveUserData(updatedUser.toJson());
        }

        // Also save language separately
        await _storageService.saveLanguage(language);

        return {
          'success': true,
          'message': response.data['message'] ?? 'Language updated successfully',
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to update language',
        };
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ Error changing language: $e');
      return {
        'success': false,
        'error': 'Failed to update language. Please try again.',
      };
    }
  }

  /// Revoke a trusted device
  /// POST /revoke_trusted_device
  /// Request: { "device_id": 1 }
  Future<Map<String, dynamic>> revokeTrustedDevice(int deviceId) async {
    try {
      DiagnosticLogger.instance.debug('🔐 Revoking device ID: $deviceId');

      final response = await _apiService.post(
        ApiConstants.REVOKE_TRUSTED_DEVICE,
        data: {
          'device_id': deviceId,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Device revoked successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to revoke device',
        };
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ Error revoking device: $e');
      return {
        'success': false,
        'error': 'Failed to revoke device. Please try again.',
      };
    }
  }
}