// data/repositories/profile_repository.dart

import 'package:casazero/core/constants/api_constants.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../models/trusted_device_model.dart';
import '../models/user_model.dart';
import 'package:dio/dio.dart' as dio;

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
    // try {
      // Prepare request body
      final Map<String, dynamic> requestBody = {};

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

      print(requestBody.toString());
      // Make API call
      final response = await _apiService.post(
        "${ApiConstants.UPDATE_USER_PROFILE}/$userId",
        data: requestBody,
      );

      print(response.toString());
      // Handle success response
      if (response.statusCode == 200 && response.data['status'] == true) {
        // Update user data in storage
        if (response.data['data'] != null) {
          final updatedUser = UserModel.fromJson(response.data['data']);
          await _storageService.saveUserData(updatedUser.toJson());
        }

        return {
          'success': true,
          'message': response.data['message'] ?? 'Profile updated successfully!',
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to update profile',
        };
      }
    // } catch (e) {
    //
    //   return {
    //
    //     'success': false,
    //     'error': e.toString(),
    //   };
    // }
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

      print('📱 Fetching trusted devices for user ID: $userId');

      final response = await _apiService.get(
        '${ApiConstants.GET_ALL_TRUSTED_DEVICES}/$userId',
      );

      print('✅ Trusted Devices Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Status: ${response.data['status']}');
      print('  Message: ${response.data['message']}');
      print('  Device Count: ${(response.data['trusted_devices'] as List?)?.length ?? 0}');

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
      print('❌ Error fetching trusted devices: $e');
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

      print('🗑️ Deleting device: $deviceId for user: $userId');

      final response = await _apiService.post(
        ApiConstants.DELETE_SPECIFIC_USER_DEVICE,
        data: {
          'user_id': userId.toString(),
          'device_id': deviceId,
        },
      );

      print('✅ Delete Device Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Status: ${response.data['status']}');
      print('  Message: ${response.data['message']}');

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
      print('❌ Error deleting device: $e');
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
      print('🌐 Changing language for user $userId to: $language');

      final response = await _apiService.post(
        ApiConstants.CHANGE_LANGUAGE,
        data: {
          'user_id': userId,
          'language': language,
        },
      );

      print('✅ Change Language Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Response: ${response.data}');

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
      print('❌ Error changing language: $e');
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
      print('🔐 Revoking device ID: $deviceId');

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
      print('❌ Error revoking device: $e');
      return {
        'success': false,
        'error': 'Failed to revoke device. Please try again.',
      };
    }
  }
}