import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/document_category_model.dart';

class DocumentRepository {
  final ApiService _apiService = Get.find();

  /// Get Document Categories
  /// GET /document_categories
  /// Response: {
  ///   "status": true,
  ///   "data": [
  ///     {
  ///       "id": 1,
  ///       "category_name": "maintenance",
  ///       "category_description": "User maintenance documents",
  ///       "created_at": "2025-11-16T22:37:28.000000Z",
  ///       "updated_at": "2025-11-16T22:37:28.000000Z"
  ///     }
  ///   ]
  /// }
  Future<Map<String, dynamic>> getDocumentCategories() async {
    try {
      final response = await _apiService.get(
        ApiConstants.GET_DOCUMENT_CATEGORIES,
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> categoriesData = response.data['data'] ?? [];
        final categories = categoriesData
            .map((item) => DocumentCategoryModel.fromJson(item))
            .toList();

        return {'success': true, 'data': categories};
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch categories',
        };
      }
    } catch (e) {
      print('Error fetching document categories: $e');
      return {
        'success': false,
        'error': 'Failed to fetch categories. Please try again.',
      };
    }
  }
}
