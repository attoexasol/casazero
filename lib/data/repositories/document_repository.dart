import 'dart:io';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/document_category_model.dart';
import '../models/document_model.dart';

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

  /// Get Residence Documents
  /// POST /get_residence_wise_documents
  /// Request: { "residence_id": 23 }
  Future<Map<String, dynamic>> getResidenceDocuments(int residenceId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.GET_RESIDENCE_DOCUMENTS,
        data: {'residence_id': residenceId},
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> documentsData =
            response.data['residence']?['documents'] ?? [];

        final documents = documentsData
            .map(
              (item) => {
                'id': item['id']?.toString() ?? '',
                'document_name': item['document_name'] ?? '',
                'file_type': item['file_type'] ?? '',
                'category_id': item['category_id'],
                'uploaded_date': item['uploaded_date'] ?? '',
                'file_size': item['file_size'] ?? '',
                'file_url': item['file_url'],
                'document_description': item['document_description'],
                'type_id': item['type_id'],
              },
            )
            .toList();

        return {
          'success': true,
          'data': documents,
          'residence': response.data['residence'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch documents',
        };
      }
    } catch (e) {
      print('Error fetching residence documents: $e');
      return {
        'success': false,
        'error': 'Failed to fetch documents. Please try again.',
      };
    }
  }

  /// Get All Documents
  /// GET /documents/
  /// Response: {
  ///   "status": true,
  ///   "data": [
  ///     {
  ///       "id": 12,
  ///       "document_name": "National ID Card",
  ///       "document_description": "Front side of NID",
  ///       "file_url": "https://...",
  ///       "file_type": "jpg",
  ///       "file_size": "0.01 MB",
  ///       "uploaded_date": "12-04-2025",
  ///       "category": { "id": 2, "category_name": "My Documents" },
  ///       "type": { "id": 2, "type_name": "Guarantees" },
  ///       "unit": { "id": 1, "unit_name": "Updated Unit A1" } or null
  ///     }
  ///   ]
  /// }
  Future<Map<String, dynamic>> getAllDocuments() async {
    try {
      final response = await _apiService.get(
        ApiConstants.GET_DOCUMENTS,
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> documentsData = response.data['data'] ?? [];

        final documents = documentsData
            .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
            .toList();

        return {
          'success': true,
          'data': documents,
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch documents',
        };
      }
    } catch (e) {
      print('Error fetching all documents: $e');
      return {
        'success': false,
        'error': 'Failed to fetch documents. Please try again.',
      };
    }
  }

  /// Get Unit Wise Documents
  /// POST /get_unit_wise_documents
  /// Request: { "token": "user token" }
  /// Response: {
  ///   "status": true,
  ///   "message": "Unit-wise documents retrieved successfully",
  ///   "data": [
  ///     { "unit_name": "Unit A1", "documents": [ ... ] }
  ///   ]
  /// }
  Future<Map<String, dynamic>> getUnitWiseDocuments() async {
    try {
      final storageService = Get.find<StorageService>();
      final token = storageService.getAccessToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'error': 'User token is missing. Please login again.',
        };
      }

      final response = await _apiService.post(
        ApiConstants.GET_UNIT_WISE_DOCUMENTS,
        data: {'token': token},
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> unitsData = response.data['data'] ?? [];

        // Flatten all documents from each unit
        final documents = <DocumentModel>[];
        for (final unit in unitsData) {
          final List<dynamic> unitDocuments = unit['documents'] ?? [];
          documents.addAll(
            unitDocuments
                .map(
                  (item) =>
                      DocumentModel.fromJson(item as Map<String, dynamic>),
                )
                .toList(),
          );
        }

        return {
          'success': true,
          'data': documents,
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch documents',
        };
      }
    } catch (e) {
      print('Error fetching unit-wise documents: $e');
      return {
        'success': false,
        'error': 'Failed to fetch documents. Please try again.',
      };
    }
  }

  /// Get Documents by Unit
  /// POST /documents/by_unit
  /// Request: { "token": "user_access_token" }
  /// Response: {
  ///   "status": true,
  ///   "message": "Documents retrieved successfully",
  ///   "unit_id": 12,
  ///   "documents": [
  ///     {
  ///       "id": 10,
  ///       "document_name": "January Invoice",
  ///       "document_description": "Monthly invoice for January",
  ///       "file_url": "https://...",
  ///       "file_type": "pdf",
  ///       "file_size": "1.20 MB",
  ///       "uploaded_date": "01-10-2025",
  ///       "category": { "id": 1, "category_name": "Invoice" },
  ///       "type": { "id": 2, "type_name": "PDF" }
  ///     }
  ///   ]
  /// }
  Future<Map<String, dynamic>> getDocumentsByUnit() async {
    try {
      final storageService = Get.find<StorageService>();
      final token = storageService.getAccessToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'error': 'User token is missing. Please login again.',
        };
      }

      print('📄 Fetching documents by unit with token: ${token.substring(0, 10)}...');

      final response = await _apiService.post(
        ApiConstants.GET_DOCUMENTS_BY_UNIT,
        data: {'token': token},
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        // Handle new response format with 'documents' array and 'unit_id'
        final List<dynamic> documentsData = response.data['documents'] ?? response.data['data'] ?? [];
        final int? unitId = response.data['unit_id'];

        final documents = documentsData
            .map(
              (item) => DocumentModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        print('✅ Successfully fetched ${documents.length} documents by unit (unit_id: $unitId)');

        return {
          'success': true,
          'data': documents,
          'unit_id': unitId,
        };
      } else {
        print('⚠️ API Error: ${response.data['message']}');
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch documents',
        };
      }
    } catch (e) {
      print('❌ Error fetching documents by unit: $e');
      return {
        'success': false,
        'error': 'Failed to fetch documents. Please try again.',
      };
    }
  }

  /// Upload User Document
  /// POST /user_document_upload
  /// Request: {
  ///   "token": "user_token",
  ///   "document_file": "file",
  ///   "document_title": "Passport Copy",
  ///   "document_category": 2,
  ///   "document_description": "User passport front page"
  /// }
  /// Response: {
  ///   "status": true,
  ///   "message": "Document uploaded successfully",
  ///   "data": { ... }
  /// }
  Future<Map<String, dynamic>> uploadDocument({
    required File documentFile,
    required String documentTitle,
    required int documentCategory,
    String? documentDescription,
  }) async {
    try {
      final storageService = Get.find<StorageService>();
      final token = storageService.getAccessToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'error': 'User token is missing. Please login again.',
        };
      }

      // Format current date as YYYY-MM-DD for MySQL compatibility
      // Backend was generating date incorrectly as DD-MM-YYYY, so we send it explicitly
      final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Create FormData for file upload
      final formData = dio.FormData.fromMap({
        'token': token,
        'document_file': await dio.MultipartFile.fromFile(
          documentFile.path,
          filename: documentFile.path.split('/').last,
        ),
        'document_title': documentTitle,
        'document_category': documentCategory,
        'uploaded_date': currentDate, // Explicitly send date in YYYY-MM-DD format (MySQL standard)
        if (documentDescription != null && documentDescription.isNotEmpty)
          'document_description': documentDescription,
      });

      print('📤 [DocumentRepository] Uploading document: $documentTitle');
      print('📤 [DocumentRepository] Category ID: $documentCategory');
      print('📤 [DocumentRepository] File: ${documentFile.path}');
      print('📅 [DocumentRepository] Sending uploaded_date: $currentDate (YYYY-MM-DD format)');

      // Make API call
      final response = await _apiService.post(
        ApiConstants.UPLOAD_USER_DOCUMENT,
        data: formData,
      );

      print('✅ [DocumentRepository] Upload response: ${response.statusCode}');
      print('📊 [DocumentRepository] Response data: ${response.data}');

      // Handle success response
      if (response.statusCode == 200 && response.data['status'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Document uploaded successfully',
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to upload document',
        };
      }
    } catch (e) {
      print('❌ [DocumentRepository] Error uploading document: $e');
      return {
        'success': false,
        'error': 'Upload failed: ${e.toString()}',
      };
    }
  }

  /// Delete Document
  /// DELETE /documents/delete/{document_id}
  /// Response: {
  ///   "status": true,
  ///   "message": "Document deleted successfully"
  /// }
  Future<Map<String, dynamic>> deleteDocument(int documentId) async {
    try {
      print('🗑️ [DocumentRepository] Deleting document with ID: $documentId');

      final response = await _apiService.delete(
        '/documents/delete/$documentId',
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        print('✅ [DocumentRepository] Document deleted successfully');
        return {
          'success': true,
          'message': response.data['message'] ?? 'Document deleted successfully',
        };
      } else {
        print('⚠️ [DocumentRepository] Delete failed: ${response.data['message']}');
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to delete document',
        };
      }
    } catch (e) {
      print('❌ [DocumentRepository] Error deleting document: $e');
      return {
        'success': false,
        'error': 'Failed to delete document. Please try again.',
      };
    }
  }
}
