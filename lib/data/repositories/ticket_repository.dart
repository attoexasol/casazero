import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../presentation/tickets/models/issue_type_model.dart';

class TicketRepository {
  final ApiService _apiService = Get.find();
  final StorageService _storageService = Get.find();

  Future<List<IssueTypeModel>> fetchIssueTypes() async {
    try {
      final apiToken = _storageService.getAccessToken();

      if (apiToken == null || apiToken.isEmpty) {
        print('❌ [TicketRepository] API token not found');
        return [];
      }

      final response = await _apiService.post(
        ApiConstants.GET_ISSUE_TYPES,
        data: {'api_token': apiToken},
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((e) => IssueTypeModel.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      print('❌ [TicketRepository] Error fetching issue types: $e');
      return [];
    }
  }
}
