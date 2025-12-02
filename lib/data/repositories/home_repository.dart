import 'package:get/get.dart';
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
  /// GET /residences/{user_id}
  /// Returns list of residences for the user
  Future<Map<String, dynamic>> getUserResidences() async {
    try {
      final userData = _storageService.getUserData();
      final userId = userData?['id'];

      if (userId == null) {
        return {
          'success': false,
          'error': 'User not found in local storage',
        };
      }

      final response = await _apiService.get(
        '${ApiConstants.GET_USER_RESIDENCES}/$userId',
      );

      // Response structure:
      // {
      //   "status": true,
      //   "user_id": "1",
      //   "data": [ {...}, {...} ]
      // }
      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> residencesData = response.data['data'] ?? [];
        final residences = residencesData
            .map((item) => ResidenceModel.fromJson(item))
            .toList();

        return {
          'success': true,
          'data': residences,
          'user_id': response.data['user_id'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch residences',
        };
      }
    } catch (e) {
      print('Error fetching user residences: $e');
      return {
        'success': false,
        'error': 'Failed to fetch residences. Please try again.',
      };
    }
  }

  // Get Feed Items
  Future<List<FeedItemModel>> getFeedItems({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.get(
        ApiConstants.GET_FEED_ITEMS,
        queryParams: {
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> feedData = response.data['items'] ?? [];
      return feedData.map((item) => FeedItemModel.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get Construction Phases
  Future<List<ConstructionPhaseModel>> getConstructionPhases(String residenceId) async {
    try {
      final endpoint = ApiConstants.GET_CONSTRUCTION_PHASES
          .replaceAll('{residenceId}', residenceId);

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
      final endpoint = ApiConstants.GET_RESIDENCE_INFO
          .replaceAll('{residenceId}', residenceId);

      final response = await _apiService.get(endpoint);
      return response.data;
    } catch (e) {
      return null;
    }
  }
}