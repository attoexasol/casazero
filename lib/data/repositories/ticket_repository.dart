import 'dart:convert';

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

      print('📋 [TicketRepository] Issue types response status: ${response.statusCode}');

      final dynamic rawData = response.data;
      final Map<String, dynamic> body =
          rawData is String ? json.decode(rawData) : Map<String, dynamic>.from(rawData);

      print('📋 [TicketRepository] Issue types body: $body');

      final bool isSuccess = body['success'] == true || body['status'] == true;

      if (isSuccess) {
        final List<dynamic> data = body['data'] ?? [];
        print('📋 [TicketRepository] Parsed ${data.length} issue types');
        return data.map((e) => IssueTypeModel.fromJson(e)).toList();
      }

      print('⚠️ [TicketRepository] API returned success=false');
      return [];
    } catch (e) {
      print('❌ [TicketRepository] Error fetching issue types: $e');
      return [];
    }
  }

  /// Creates a new issue type via the API.
  /// Returns the created [IssueTypeModel] on success, or null on failure.
  Future<IssueTypeModel?> createIssueType({
    required String issueTypeEn,
    required String issueTypeIt,
  }) async {
    try {
      final apiToken = _storageService.getAccessToken();

      if (apiToken == null || apiToken.isEmpty) {
        print('❌ [TicketRepository] API token not found');
        return null;
      }

      final response = await _apiService.post(
        ApiConstants.CREATE_ISSUE_TYPE,
        data: {
          'api_token': apiToken,
          'issue_type_en': issueTypeEn,
          'issue_type_it': issueTypeIt,
        },
      );

      print('📋 [TicketRepository] Create issue type status: ${response.statusCode}');

      final dynamic rawData = response.data;
      final Map<String, dynamic> body =
          rawData is String ? json.decode(rawData) : Map<String, dynamic>.from(rawData);

      print('📋 [TicketRepository] Create issue type body: $body');

      final bool isSuccess = body['success'] == true || body['status'] == true;

      if (isSuccess && body['data'] != null) {
        final data = Map<String, dynamic>.from(body['data']);
        final rawId = data['id'];
        final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

        return IssueTypeModel(
          id: id,
          issueTypeEn: data['issue_type_en']?.toString() ?? issueTypeEn,
          issueTypeIt: data['issue_type_it']?.toString() ?? issueTypeIt,
        );
      }

      print('⚠️ [TicketRepository] Create issue type failed: ${body['message'] ?? 'unknown error'}');
      return null;
    } catch (e) {
      print('❌ [TicketRepository] Error creating issue type: $e');
      return null;
    }
  }
}
