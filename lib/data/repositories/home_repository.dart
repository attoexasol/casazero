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
}
