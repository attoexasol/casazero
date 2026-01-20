import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/storage_service.dart';
import '../models/feed_item_model.dart';
import '../models/construction_phase_model.dart';
import '../models/residence_model.dart';

class HomeRepository {
  final ApiService _apiService = Get.find();
  final StorageService _storageService = Get.find();

  // Get User Residences
  /// PUT /residences/by-token
  /// Request: { "token": "USER_AUTH_TOKEN_HERE" }
  /// Returns list of residences for the user
  Future<Map<String, dynamic>> getUserResidences() async {
    try {
      print('🏠 [HomeRepository] Starting getUserResidences()...');
      final token = _storageService.getAccessToken();
      print(
        '🔑 [HomeRepository] Token retrieved: ${token != null && token.isNotEmpty ? "Token exists (${token.length} chars)" : "NO TOKEN"}',
      );

      if (token == null || token.isEmpty) {
        print('❌ [HomeRepository] Token is null or empty');
        return {
          'success': false,
          'error': 'User token not found in local storage',
        };
      }

      final endpoint = ApiConstants.GET_USER_RESIDENCES;
      final fullUrl = '${ApiConstants.BASE_URL}$endpoint';
      print('📡 [HomeRepository] Making PUT request to: $endpoint');
      print('🌐 [HomeRepository] Full URL: $fullUrl');
      print(
        '📦 [HomeRepository] Request data: {"token": "${token.substring(0, token.length > 20 ? 20 : token.length)}..."}',
      );

      final response = await _apiService.post(endpoint, data: {'token': token});
      print(response);
      print('✅ [HomeRepository] API Response received');
      print('📊 [HomeRepository] Status Code: ${response.statusCode}');
      print('📊 [HomeRepository] Response Data: ${response.data}');

      // Response structure:
      // {
      //   "status": true,
      //   "user_id": 17,
      //   "data": [
      //     {
      //       "id": 3,
      //       "residence_name": "Casa Zero Residency",
      //       "residence_address": "Block A, Road 12, Dhaka"
      //     }
      //   ]
      // }
      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> residencesData = response.data['data'] ?? [];
        print(
          '🏘️ [HomeRepository] Parsing ${residencesData.length} residences',
        );
        final residences = residencesData
            .map((item) => ResidenceModel.fromJson(item))
            .toList();

        print(
          '✅ [HomeRepository] Successfully parsed ${residences.length} residences',
        );
        return {
          'success': true,
          'data': residences,
          'user_id': response.data['user_id'],
        };
      } else {
        final errorMessage =
            response.data['message'] ??
            response.data['error'] ??
            'Failed to fetch residences';
        print('❌ [HomeRepository] API returned error: $errorMessage');
        return {'success': false, 'error': errorMessage};
      }
    } on DioException catch (e, stackTrace) {
      print('❌ [HomeRepository] DioException in getUserResidences: $e');
      print('📚 [HomeRepository] Stack trace: $stackTrace');

      // Try to extract error message from response
      String errorMessage = 'Failed to fetch residences. Please try again.';
      if (e.response != null && e.response!.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          errorMessage =
              responseData['message'] ?? responseData['error'] ?? errorMessage;
        }
        print('📊 [HomeRepository] Error response data: $responseData');
      }

      return {'success': false, 'error': errorMessage};
    } catch (e, stackTrace) {
      print('❌ [HomeRepository] Exception in getUserResidences: $e');
      print('📚 [HomeRepository] Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'Failed to fetch residences. Please try again.',
      };
    }
  }

  // Get Feed Items
  Future<List<FeedItemModel>> getFeedItems({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.GET_FEED_ITEMS,
        queryParams: {'page': page, 'limit': limit},
      );

      final List<dynamic> feedData = response.data['items'] ?? [];
      return feedData.map((item) => FeedItemModel.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get User Notifications
  /// POST /get_user/notifications
  /// Request: { "api_token": "<CURRENT_USER_API_TOKEN>" }
  /// Returns list of notifications for the current user
  Future<Map<String, dynamic>> getUserNotifications() async {
    try {
      print('🔔 [HomeRepository] Starting getUserNotifications()...');
      
      // Get access token (api_token) from storage
      final apiToken = _storageService.getAccessToken();
      print('Notification API token: ${apiToken != null && apiToken.isNotEmpty ? "${apiToken.substring(0, 10)}..." : "NO TOKEN"}');
      
      if (apiToken == null || apiToken.isEmpty) {
        print('❌ [HomeRepository] API token is null or empty');
        return {
          'success': false,
          'error': 'User API token not found in local storage',
        };
      }

      final endpoint = ApiConstants.GET_USER_NOTIFICATIONS;
      print('📡 [HomeRepository] Making POST request to: $endpoint');

      // Call API with api_token in request body
      final response = await _apiService.post(
        endpoint,
        data: {'api_token': apiToken},
      );

      print('✅ [HomeRepository] API Response received');
      print('📊 [HomeRepository] Status Code: ${response.statusCode}');

      // Response structure:
      // {
      //   "status": true,
      //   "data": [
      //     {
      //       "id": 2,
      //       "title": "New Document Uploaded 📄",
      //       "content": "Your document has been uploaded successfully.",
      //       "url": "https://...",
      //       "notification_type": "document",
      //       "is_read": 0,
      //       "created_at": "2026-01-14T16:21:33.000000Z"
      //     }
      //   ]
      // }
      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> notificationsData = response.data['data'] ?? [];
        print('Fetched notifications: ${notificationsData.length}');
        
        final notifications = notificationsData
            .map((item) => FeedItemModel.fromJson(item as Map<String, dynamic>))
            .toList();

        print('✅ [HomeRepository] Successfully parsed ${notifications.length} notifications');
        return {
          'success': true,
          'data': notifications,
        };
      } else {
        final errorMessage =
            response.data['message'] ??
            response.data['error'] ??
            'Failed to fetch notifications';
        print('❌ [HomeRepository] API returned error: $errorMessage');
        return {'success': false, 'error': errorMessage};
      }
    } on DioException catch (e, stackTrace) {
      print('❌ [HomeRepository] DioException in getUserNotifications: $e');
      print('📚 [HomeRepository] Stack trace: $stackTrace');

      String errorMessage = 'Failed to fetch notifications. Please try again.';
      if (e.response != null && e.response!.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          errorMessage =
              responseData['message'] ?? responseData['error'] ?? errorMessage;
        }
        print('📊 [HomeRepository] Error response data: $responseData');
      }

      return {'success': false, 'error': errorMessage};
    } catch (e, stackTrace) {
      print('❌ [HomeRepository] Exception in getUserNotifications: $e');
      print('❌ [HomeRepository] Exception type: ${e.runtimeType}');
      print('📚 [HomeRepository] Stack trace: $stackTrace');
      
      String errorMessage = 'Failed to fetch notifications. Please try again.';
      
      // Handle String exceptions (from ApiService._handleError)
      if (e is String) {
        // Check if it's HTML (403 Forbidden page)
        if (e.trim().startsWith('<!DOCTYPE') || e.trim().startsWith('<html')) {
          errorMessage = 'Access forbidden. Please check your permissions.';
        } else {
          // Use the error message from ApiService
          errorMessage = e;
        }
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        errorMessage = 'Access forbidden. Please check your permissions.';
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorMessage = 'Unauthorized. Please log in again.';
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

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
  Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    try {
      print('✅ [HomeRepository] Marking notification as read: $notificationId');
      
      // Get access token (api_token) from storage
      final apiToken = _storageService.getAccessToken();
      print('User api_token: ${apiToken != null && apiToken.isNotEmpty ? "${apiToken.substring(0, 10)}..." : "NO TOKEN"}');
      
      if (apiToken == null || apiToken.isEmpty) {
        print('❌ [HomeRepository] API token is null or empty');
        return {
          'success': false,
          'error': 'User API token not found in local storage',
        };
      }

      final endpoint = ApiConstants.MARK_NOTIFICATION_AS_READ;
      print('📡 [HomeRepository] Making POST request to: $endpoint');

      // Call API with api_token and notification_id in request body
      final response = await _apiService.post(
        endpoint,
        data: {
          'api_token': apiToken,
          'notification_id': notificationId,
        },
      );

      print('✅ [HomeRepository] Mark as read response received');
      print('📊 [HomeRepository] Status Code: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['status'] == true) {
        print('✅ [HomeRepository] Notification marked as read successfully');
        return {
          'success': true,
          'message': response.data['message'] ?? 'Notification marked as read',
        };
      } else {
        final errorMessage =
            response.data['message'] ??
            response.data['error'] ??
            'Failed to mark notification as read';
        print('❌ [HomeRepository] API returned error: $errorMessage');
        return {'success': false, 'error': errorMessage};
      }
    } on DioException catch (e, stackTrace) {
      print('❌ [HomeRepository] DioException in markNotificationAsRead: $e');
      print('📚 [HomeRepository] Stack trace: $stackTrace');

      String errorMessage = 'Failed to mark notification as read. Please try again.';
      if (e.response != null && e.response!.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          errorMessage =
              responseData['message'] ?? responseData['error'] ?? errorMessage;
        }
        print('📊 [HomeRepository] Error response data: $responseData');
      }

      return {'success': false, 'error': errorMessage};
    } catch (e, stackTrace) {
      print('❌ [HomeRepository] Exception in markNotificationAsRead: $e');
      print('📚 [HomeRepository] Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'Failed to mark notification as read. Please try again.',
      };
    }
  }

  /// Get Unread Notification Count
  /// POST /get_user/unread_count
  /// Request: {
  ///   "api_token": "<CURRENT_USER_API_TOKEN>"
  /// }
  /// Response: {
  ///   "status": true,
  ///   "unread_count": 1
  /// }
  Future<Map<String, dynamic>> getUnreadNotificationCount() async {
    try {
      print('🔔 [HomeRepository] Fetching unread notification count...');
      
      // Get access token (api_token) from storage
      final apiToken = _storageService.getAccessToken();
      print('User api_token: ${apiToken != null && apiToken.isNotEmpty ? "${apiToken.substring(0, 10)}..." : "NO TOKEN"}');
      
      if (apiToken == null || apiToken.isEmpty) {
        print('❌ [HomeRepository] API token is null or empty');
        return {
          'success': false,
          'error': 'User API token not found in local storage',
          'unread_count': 0,
        };
      }

      final endpoint = ApiConstants.GET_UNREAD_NOTIFICATION_COUNT;
      print('📡 [HomeRepository] Making POST request to: $endpoint');

      // Call API with api_token in request body
      final response = await _apiService.post(
        endpoint,
        data: {'api_token': apiToken},
      );

      print('✅ [HomeRepository] Unread count response received');
      print('📊 [HomeRepository] Status Code: ${response.statusCode}');

      print('📊 [HomeRepository] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['status'] == true) {
        final unreadCount = response.data['unread_count'] ?? 0;
        print('✅ [HomeRepository] Unread count: $unreadCount');
        return {
          'success': true,
          'unread_count': unreadCount,
        };
      } else {
        final errorMessage =
            response.data['message'] ??
            response.data['error'] ??
            'Failed to fetch unread count';
        print('❌ [HomeRepository] API returned error: $errorMessage');
        print('📊 [HomeRepository] Response status: ${response.statusCode}');
        print('📊 [HomeRepository] Response data: ${response.data}');
        return {
          'success': false,
          'error': errorMessage,
          'unread_count': 0,
        };
      }
    } on DioException catch (e, stackTrace) {
      print('❌ [HomeRepository] DioException in getUnreadNotificationCount');
      print('❌ [HomeRepository] Error type: ${e.type}');
      print('❌ [HomeRepository] Error message: ${e.message}');
      print('📊 [HomeRepository] Status code: ${e.response?.statusCode}');
      print('📊 [HomeRepository] Response data: ${e.response?.data}');
      print('📚 [HomeRepository] Stack trace: $stackTrace');

      String errorMessage = 'Failed to fetch unread count. Please try again.';
      
      // Handle different DioException types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.badResponse) {
        if (e.response != null && e.response!.data != null) {
          final responseData = e.response!.data;
          if (responseData is Map) {
            errorMessage =
                responseData['message'] ?? responseData['error'] ?? errorMessage;
          } else if (responseData is String) {
            errorMessage = responseData;
          }
        }
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      return {
        'success': false,
        'error': errorMessage,
        'unread_count': 0,
      };
    } catch (e, stackTrace) {
      print('❌ [HomeRepository] Exception in getUnreadNotificationCount: $e');
      print('❌ [HomeRepository] Exception type: ${e.runtimeType}');
      print('📚 [HomeRepository] Stack trace: $stackTrace');
      
      String errorMessage = 'Failed to fetch unread count. Please try again.';
      
      // Handle String exceptions (from ApiService._handleError)
      if (e is String) {
        // Check if it's HTML (403 Forbidden page)
        if (e.trim().startsWith('<!DOCTYPE') || e.trim().startsWith('<html')) {
          errorMessage = 'Access forbidden. Please check your permissions.';
        } else {
          // Use the error message from ApiService
          errorMessage = e;
        }
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        errorMessage = 'Access forbidden. Please check your permissions.';
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorMessage = 'Unauthorized. Please log in again.';
      } else if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.toString().contains('network') || e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      
      return {
        'success': false,
        'error': errorMessage,
        'unread_count': 0,
      };
    }
  }

  // Get Construction Phases
  Future<List<ConstructionPhaseModel>> getConstructionPhases(
    String residenceId,
  ) async {
    try {
      final endpoint = ApiConstants.GET_CONSTRUCTION_PHASES.replaceAll(
        '{residenceId}',
        residenceId,
      );

      final response = await _apiService.get(endpoint);

      final List<dynamic> phasesData = response.data['phases'] ?? [];
      return phasesData
          .map((phase) => ConstructionPhaseModel.fromJson(phase))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get Residence Info
  Future<Map<String, dynamic>?> getResidenceInfo(String residenceId) async {
    try {
      final endpoint = ApiConstants.GET_RESIDENCE_INFO.replaceAll(
        '{residenceId}',
        residenceId,
      );

      final response = await _apiService.get(endpoint);
      return response.data;
    } catch (e) {
      return null;
    }
  }

  // Get Residence Data by Token (for Home Screen)
  /// POST /residences/by-token
  /// Request: { "token": "<TOKEN_FROM_LOCAL_STORAGE>" }
  /// Returns residence data with photo and status
  Future<Map<String, dynamic>> getResidenceByToken() async {
    try {
      print('🏠 [HomeRepository] Starting getResidenceByToken()...');
      
      // Fetch token dynamically from local storage
      final token = _storageService.getAccessToken();
      print('Residence token from storage: $token');
      
      if (token == null || token.isEmpty) {
        print('❌ [HomeRepository] Token is null or empty');
        return {
          'success': false,
          'error': 'User token not found in local storage',
        };
      }

      print('🔑 [HomeRepository] Using token from storage (${token.length} chars)');

      final endpoint = ApiConstants.GET_USER_RESIDENCES;
      print('📡 [HomeRepository] Making POST request to: $endpoint');
      print('📦 [HomeRepository] Request body: {"token": "${token.substring(0, token.length > 20 ? 20 : token.length)}..."}');

      // Use POST with request body for token (as per API specification)
      final response = await _apiService.post(
        endpoint,
        data: {'token': token},
      );

      print('✅ [HomeRepository] API Response received');
      print('📊 [HomeRepository] Status Code: ${response.statusCode}');
      print('📊 [HomeRepository] Response Data: ${response.data}');
      
      // Temp log as requested
      print('Home residence data: ${response.data}');

      // Response structure:
      // {
      //   "residence_name": "POLICE PARK",
      //   "residence_address": "POLICE PARK DESC",
      //   "residence_status": "Under Construction",
      //   "residence_photo": "https://smarthome.attoexasolutions.com/residence_images/..."
      // }
      // OR if it's an array:
      // {
      //   "data": [
      //     {
      //       "residence_name": "POLICE PARK",
      //       "residence_address": "POLICE PARK DESC",
      //       "residence_status": "Under Construction",
      //       "residence_photo": "https://..."
      //     }
      //   ]
      // }

      // Verify response status code and API status field
      if (response.statusCode == 200) {
        dynamic responseData = response.data;
        
        // Check API status field if present
        if (responseData is Map && responseData.containsKey('status')) {
          final apiStatus = responseData['status'];
          if (apiStatus != true) {
            final errorMessage = responseData['message'] ?? 
                               responseData['error'] ?? 
                               'API returned status: false';
            print('❌ [HomeRepository] API status is false: $errorMessage');
            return {'success': false, 'error': errorMessage};
          }
        }
        
        // Handle both array and object responses
        Map<String, dynamic> residenceData;
        if (responseData is List && responseData.isNotEmpty) {
          residenceData = responseData[0] as Map<String, dynamic>;
        } else if (responseData is Map) {
          if (responseData.containsKey('data') && responseData['data'] is List) {
            final dataList = responseData['data'] as List;
            if (dataList.isNotEmpty) {
              residenceData = dataList[0] as Map<String, dynamic>;
            } else {
              return {'success': false, 'error': 'No residence data found'};
            }
          } else {
            residenceData = Map<String, dynamic>.from(responseData);
          }
        } else {
          return {'success': false, 'error': 'Invalid response format'};
        }

        print('✅ [HomeRepository] Successfully extracted residence data');
        print('📋 [HomeRepository] Residence name: ${residenceData['residence_name']}');
        print('📋 [HomeRepository] Residence address: ${residenceData['residence_address']}');
        print('📋 [HomeRepository] Residence status: ${residenceData['residence_status']}');
        // Temporary log: Residence image URL
        final residencePhoto = residenceData['residence_photo'];
        print('🏠 [HomeRepository] Residence image URL: $residencePhoto');
        return {
          'success': true,
          'data': residenceData,
        };
      } else {
        final errorMessage =
            response.data['message'] ??
            response.data['error'] ??
            'Failed to fetch residence data';
        print('❌ [HomeRepository] API returned error: $errorMessage');
        return {'success': false, 'error': errorMessage};
      }
    } on DioException catch (e, stackTrace) {
      print('❌ [HomeRepository] DioException in getResidenceByToken: $e');
      print('📚 [HomeRepository] Stack trace: $stackTrace');

      String errorMessage = 'Failed to fetch residence data. Please try again.';
      if (e.response != null && e.response!.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          errorMessage =
              responseData['message'] ?? responseData['error'] ?? errorMessage;
        }
        print('📊 [HomeRepository] Error response data: $responseData');
      }

      return {'success': false, 'error': errorMessage};
    } catch (e, stackTrace) {
      print('❌ [HomeRepository] Exception in getResidenceByToken: $e');
      print('📚 [HomeRepository] Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'Failed to fetch residence data. Please try again.',
      };
    }
  }
}
