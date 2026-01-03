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
  /// GET /residences/by-token?token=USER_TOKEN
  /// Returns residence data with photo and status
  Future<Map<String, dynamic>> getResidenceByToken() async {
    try {
      print('🏠 [HomeRepository] Starting getResidenceByToken()...');
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
      print('📡 [HomeRepository] Making POST request to: $endpoint');
      print('📦 [HomeRepository] Token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');

      // Use POST with request body for token (as per API specification)
      final response = await _apiService.post(
        endpoint,
        data: {'token': token},
      );

      print('✅ [HomeRepository] API Response received');
      print('📊 [HomeRepository] Status Code: ${response.statusCode}');
      print('📊 [HomeRepository] Response Data: ${response.data}');

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

      if (response.statusCode == 200) {
        dynamic responseData = response.data;
        
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
