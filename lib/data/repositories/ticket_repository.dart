import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../presentation/tickets/models/issue_type_model.dart';
import '../../presentation/tickets/models/ticket_model.dart';

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

  /// Creates a support ticket via the API.
  /// Returns a success map with ticket data, or an error message string.
  Future<Map<String, dynamic>?> createSupportTicket({
    required String title,
    required String description,
    required int issueTypeId,
    String priority = 'medium',
    File? image,
    String? residenceName,
    String? residenceUnit,
  }) async {
    try {
      final apiToken = _storageService.getAccessToken();

      if (apiToken == null || apiToken.isEmpty) {
        print('❌ [TicketRepository] API token not found');
        return null;
      }

      // Backend requires residence_unit. Prefer caller value; fall back to
      // stored profile unit_name so the field is never silently omitted.
      var resolvedUnit = residenceUnit?.trim() ?? '';
      if (resolvedUnit.isEmpty) {
        resolvedUnit =
            _storageService.getUserData()?['unit_name']?.toString().trim() ??
                '';
      }

      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'title': title,
        'description': description,
        'issue_type_id': issueTypeId,
        'priority': priority,
        if (residenceName != null && residenceName.isNotEmpty)
          'residence_name': residenceName,
        'residence_unit': resolvedUnit,
      };

      if (image != null && image.existsSync()) {
        final bytes = await image.readAsBytes();
        final base64Str = base64Encode(bytes);
        final ext = image.path.split('.').last.toLowerCase();
        final mimeType = (ext == 'png') ? 'image/png' : 'image/jpeg';
        requestData['image'] = 'data:$mimeType;base64,$base64Str';
      }

      print('🎫 [TicketRepository] Creating support ticket...');

      final response = await _apiService.post(
        ApiConstants.CREATE_SUPPORT_TICKET,
        data: requestData,
      );

      print('🎫 [TicketRepository] Create ticket status: ${response.statusCode}');

      final dynamic rawData = response.data;
      final Map<String, dynamic> body =
          rawData is String ? json.decode(rawData) : Map<String, dynamic>.from(rawData);

      print('🎫 [TicketRepository] Create ticket body: $body');

      final bool isSuccess = body['success'] == true || body['status'] == true;

      if (isSuccess) {
        return body;
      }

      print('⚠️ [TicketRepository] Create ticket failed: ${body['message'] ?? 'unknown error'}');
      return null;
    } catch (e) {
      print('❌ [TicketRepository] Error creating support ticket: $e');
      return null;
    }
  }

  /// Fetches the current user's support tickets from the API.
  Future<List<TicketModel>> fetchMyTickets() async {
    try {
      final apiToken = _storageService.getAccessToken();

      if (apiToken == null || apiToken.isEmpty) {
        print('❌ [TicketRepository] API token not found');
        return [];
      }

      final response = await _apiService.post(
        ApiConstants.GET_MY_SUPPORT_TICKETS,
        data: {'api_token': apiToken},
      );

      print('🎫 [TicketRepository] My tickets response status: ${response.statusCode}');

      final dynamic rawData = response.data;
      final Map<String, dynamic> body =
          rawData is String ? json.decode(rawData) : Map<String, dynamic>.from(rawData);

      final bool isSuccess = body['success'] == true || body['status'] == true;

      if (isSuccess) {
        final List<dynamic> data = body['data'] ?? [];
        print('🎫 [TicketRepository] Parsed ${data.length} tickets');
        return data.map((e) => TicketModel.fromJson(e)).toList();
      }

      print('⚠️ [TicketRepository] fetchMyTickets API returned success=false');
      return [];
    } catch (e) {
      print('❌ [TicketRepository] Error fetching my tickets: $e');
      return [];
    }
  }
}
