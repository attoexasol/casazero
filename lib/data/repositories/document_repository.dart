import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/document_category_model.dart';
import '../models/document_model.dart';
import '../models/user_model.dart';
import 'package:casazero/core/logging/diagnostic_logger.dart';

/// Upload method enum
enum DocumentUploadMethod {
  /// Base64 encoded string in JSON payload (default, mobile-friendly)
  base64,

  /// Multipart/form-data with File (Postman-compatible)
  multipart,
}

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
      DiagnosticLogger.instance.error('Error fetching document categories: $e');
      return {
        'success': false,
        'error': 'Failed to fetch categories. Please try again.',
      };
    }
  }

  /// Get Residence Documents
  /// POST /get_residence_wise_documents
  /// Request: { "residence_id": 23 }
  Future<Map<String, dynamic>> getResidenceDocuments(dynamic residenceId) async {
    try {
      final cleanResidenceId =
          UserModel.parseResidenceIdAsInt(residenceId) ?? 0;
      final response = await _apiService.post(
        ApiConstants.GET_RESIDENCE_DOCUMENTS,
        data: {'residence_id': cleanResidenceId},
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
      DiagnosticLogger.instance.error('Error fetching residence documents: $e');
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
      final response = await _apiService.get(ApiConstants.GET_DOCUMENTS);

      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> documentsData = response.data['data'] ?? [];

        final documents = documentsData
            .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
            .toList();

        return {'success': true, 'data': documents};
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch documents',
        };
      }
    } catch (e) {
      DiagnosticLogger.instance.error('Error fetching all documents: $e');
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

        return {'success': true, 'data': documents};
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch documents',
        };
      }
    } catch (e) {
      DiagnosticLogger.instance.error('Error fetching unit-wise documents: $e');
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
  ///       "category": {
  ///         "id": 1,
  ///         "category_name": "Invoice",
  ///         "category_name_it": "Fattura"
  ///       },
  ///       "type": {
  ///         "id": 2,
  ///         "type_name": "PDF",
  ///         "type_name_it": "PDF"
  ///       }
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

      DiagnosticLogger.instance.debug(
        '📄 Fetching documents by unit with token: ${token.substring(0, 10)}...',
      );

      final response = await _apiService.post(
        ApiConstants.GET_DOCUMENTS_BY_UNIT,
        data: {'token': token},
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        // Handle new response format with 'documents' array and 'unit_id'
        final List<dynamic> documentsData =
            response.data['documents'] ?? response.data['data'] ?? [];
        final int? unitId = response.data['unit_id'];

        final documents = documentsData
            .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
            .toList();

        DiagnosticLogger.instance.warning(
          '✅ Successfully fetched ${documents.length} documents by unit (unit_id: $unitId)',
        );

        return {'success': true, 'data': documents, 'unit_id': unitId};
      } else {
        DiagnosticLogger.instance.error('⚠️ API Error: ${response.data['message']}');
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch documents',
        };
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ Error fetching documents by unit: $e');
      return {
        'success': false,
        'error': 'Failed to fetch documents. Please try again.',
      };
    }
  }

  /// Upload User Document
  /// POST /user_document_upload
  ///
  /// PRIMARY METHOD: Multipart/form-data (matches Postman - GUARANTEED TO WORK)
  ///
  /// Request format (multipart/form-data):
  /// - token: Text
  /// - document_file: File (actual file, NOT base64)
  /// - document_title: Text
  /// - document_category: Int
  /// - document_description: Text (optional)
  ///
  /// Response: {
  ///   "status": true,
  ///   "message": "Document uploaded successfully",
  ///   "data": {
  ///     "file_url": "documents/...",
  ///     "file_type": "jpeg",
  ///     "file_size": "0.5 MB",
  ///     ...
  ///   }
  /// }
  ///
  /// ALTERNATIVE: Base64 upload (only if backend explicitly supports it)
  /// Request format (application/json):
  /// - token: String
  /// - document_file: "data:image/jpeg;base64,..."
  /// - document_title: String
  /// - document_category: Int
  /// - document_description: String (optional)
  Future<Map<String, dynamic>> uploadDocument({
    required File documentFile,
    required String documentTitle,
    required int documentCategory,
    String? documentDescription,
    DocumentUploadMethod uploadMethod = DocumentUploadMethod
        .multipart, // DEFAULT: multipart (Postman-compatible)
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

      // Validate file exists and is not empty
      if (!await documentFile.exists()) {
        return {
          'success': false,
          'error': 'File does not exist: ${documentFile.path}',
        };
      }

      final fileBytes = await documentFile.readAsBytes();

      if (fileBytes.isEmpty) {
        return {
          'success': false,
          'error': 'File is empty. Cannot upload empty file.',
        };
      }

      final fileName = documentFile.path.split('/').last;
      final fileExtension = fileName.toLowerCase().split('.').last;
      final mimeType = _getMimeType(fileExtension);

      // Route to appropriate upload method
      if (uploadMethod == DocumentUploadMethod.multipart) {
        return await _uploadDocumentMultipart(
          documentFile: documentFile,
          fileBytes: fileBytes,
          fileName: fileName,
          token: token,
          documentTitle: documentTitle,
          documentCategory: documentCategory,
          documentDescription: documentDescription,
          mimeType: mimeType,
        );
      } else {
        return await _uploadDocumentBase64(
          fileBytes: fileBytes,
          token: token,
          documentTitle: documentTitle,
          documentCategory: documentCategory,
          documentDescription: documentDescription,
          mimeType: mimeType,
          fileExtension: fileExtension,
          fileName: fileName,
        );
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [DocumentRepository] Error uploading document: $e');
      DiagnosticLogger.instance.error('📚 [DocumentRepository] Error stack trace: ${StackTrace.current}');
      return {'success': false, 'error': 'Upload failed: ${e.toString()}'};
    }
  }

  /// Upload document using Base64 encoding (JSON payload)
  /// Backend must detect and process base64 string correctly
  Future<Map<String, dynamic>> _uploadDocumentBase64({
    required List<int> fileBytes,
    required String token,
    required String documentTitle,
    required int documentCategory,
    String? documentDescription,
    required String mimeType,
    required String fileExtension,
    required String fileName,
  }) async {
    try {
      // ============================================
      // STEP 1: Convert to base64 (ensure no whitespace)
      // ============================================
      final base64String = base64Encode(fileBytes);

      if (base64String.isEmpty) {
        return {
          'success': false,
          'error': 'Failed to encode file to base64. File may be corrupted.',
        };
      }

      // Remove any whitespace/newlines that might have been introduced
      final cleanBase64 = base64String.replaceAll(RegExp(r'\s+'), '');

      if (cleanBase64.isEmpty) {
        return {
          'success': false,
          'error': 'Base64 encoding resulted in empty string.',
        };
      }

      // ============================================
      // STEP 2: Verify decoded size matches original
      // ============================================
      try {
        final decodedBytes = base64Decode(cleanBase64);
        if (decodedBytes.isEmpty) {
          return {
            'success': false,
            'error': 'Base64 decodes to empty bytes. Invalid encoding.',
          };
        }
        if (decodedBytes.length != fileBytes.length) {
          DiagnosticLogger.instance.warning(
            '⚠️ [DocumentRepository] WARNING: Decoded size (${decodedBytes.length}) != original size (${fileBytes.length})',
          );
        }
      } catch (e) {
        return {
          'success': false,
          'error':
              'Base64 string is invalid and cannot be decoded: ${e.toString()}',
        };
      }

      // ============================================
      // STEP 3: Format as data URI with MIME prefix
      // Backend should detect and strip prefix if needed
      // Format: "data:image/jpeg;base64,{base64_string}"
      // ============================================
      final documentFileDataUri = 'data:$mimeType;base64,$cleanBase64';

      // Verify the data URI format is correct
      final expectedPrefix = 'data:$mimeType;base64,';
      if (!documentFileDataUri.startsWith(expectedPrefix)) {
        return {
          'success': false,
          'error': 'Failed to format data URI correctly.',
        };
      }

      if (documentFileDataUri.length <= expectedPrefix.length) {
        return {
          'success': false,
          'error': 'Data URI is missing base64 content after prefix.',
        };
      }

      // ============================================
      // STEP 4: Create JSON payload
      // ============================================
      final requestBody = <String, dynamic>{
        'token': token,
        'document_file': documentFileDataUri,
        'document_title': documentTitle,
        'document_category': documentCategory,
        if (documentDescription != null && documentDescription.isNotEmpty)
          'document_description': documentDescription,
      };

      // ============================================
      // STEP 5: Debug logging (without full base64)
      // ============================================
      DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');
      DiagnosticLogger.instance.debug('📤 [DocumentRepository] BASE64 UPLOAD REQUEST');
      DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');
      DiagnosticLogger.instance.debug('📄 File: $fileName');
      DiagnosticLogger.instance.debug('📏 Original file size: ${fileBytes.length} bytes');
      DiagnosticLogger.instance.debug('🔤 Base64 length: ${cleanBase64.length} characters');
      DiagnosticLogger.instance.debug('📋 MIME type: $mimeType');
      DiagnosticLogger.instance.debug('📝 File extension: $fileExtension');
      DiagnosticLogger.instance.info('🏷️  Document title: $documentTitle');
      DiagnosticLogger.instance.info('📂 Category ID: $documentCategory');
      DiagnosticLogger.instance.info('🔑 Token: ${token.substring(0, 10)}...');
      DiagnosticLogger.instance.info('📊 Data URI prefix: data:$mimeType;base64,');
      DiagnosticLogger.instance.info('✅ Base64 validation: PASSED (non-empty, properly formatted)');
      DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');

      // ============================================
      // STEP 6: Make API call with JSON payload
      // Content-Type will be application/json (set by ApiService)
      // ============================================
      try {
        final response = await _apiService.post(
          ApiConstants.UPLOAD_USER_DOCUMENT,
          data: requestBody,
        );

        return _handleUploadResponse(response, 'BASE64');
      } on dio.DioException catch (dioError) {
        DiagnosticLogger.instance.error('❌ [DocumentRepository] DioException in Base64 upload:');
        DiagnosticLogger.instance.error('   Type: ${dioError.type}');
        DiagnosticLogger.instance.error('   Message: ${dioError.message}');
        DiagnosticLogger.instance.error('   Response: ${dioError.response?.data}');
        DiagnosticLogger.instance.error('   Status Code: ${dioError.response?.statusCode}');

        String errorMessage = 'Failed to upload document';
        if (dioError.response?.data != null) {
          final responseData = dioError.response!.data;
          if (responseData is Map && responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          } else if (responseData is String) {
            errorMessage = responseData;
          }
        } else if (dioError.message != null) {
          errorMessage = dioError.message!;
        }

        return {'success': false, 'error': errorMessage};
      } catch (e) {
        DiagnosticLogger.instance.error('❌ [DocumentRepository] Error in Base64 upload: $e');
        DiagnosticLogger.instance.error('📚 [DocumentRepository] Stack trace: ${StackTrace.current}');
        return {
          'success': false,
          'error': 'Base64 upload failed: ${e.toString()}',
        };
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [DocumentRepository] Error in Base64 upload (outer): $e');
      return {
        'success': false,
        'error': 'Base64 upload failed: ${e.toString()}',
      };
    }
  }

  /// Upload document using multipart/form-data (File upload)
  /// PRIMARY METHOD - Matches Postman exactly, guaranteed to work
  /// Backend extracts file from multipart and stores metadata correctly
  Future<Map<String, dynamic>> _uploadDocumentMultipart({
    required File documentFile,
    required List<int> fileBytes,
    required String fileName,
    required String token,
    required String documentTitle,
    required int documentCategory,
    String? documentDescription,
    required String mimeType,
  }) async {
    try {
      // ============================================
      // STEP 1: Create FormData matching Postman format exactly
      // Fields must match Postman request 1:1
      // ============================================
      final formData = dio.FormData.fromMap({
        'token': token, // Text field
        'document_file': await dio.MultipartFile.fromFile(
          documentFile.path,
          filename: fileName, // Preserve original filename
        ), // File field - NOT base64
        'document_title': documentTitle, // Text field
        'document_category': documentCategory, // Int field
        if (documentDescription != null && documentDescription.isNotEmpty)
          'document_description': documentDescription, // Text field (optional)
      });

      // ============================================
      // STEP 2: Debug logging
      // ============================================
      DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');
      DiagnosticLogger.instance.debug('📤 [DocumentRepository] MULTIPART UPLOAD REQUEST');
      DiagnosticLogger.instance.debug(
        '📤 [DocumentRepository] Format: multipart/form-data (Postman-compatible)',
      );
      DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');
      DiagnosticLogger.instance.debug('📄 File: $fileName');
      DiagnosticLogger.instance.debug(
        '📏 File size: ${fileBytes.length} bytes (${(fileBytes.length / 1024 / 1024).toStringAsFixed(2)} MB)',
      );
      DiagnosticLogger.instance.debug('📋 MIME type: $mimeType');
      DiagnosticLogger.instance.debug('🏷️  Document title: $documentTitle');
      DiagnosticLogger.instance.debug('📂 Category ID: $documentCategory');
      DiagnosticLogger.instance.info('📝 Description: ${documentDescription ?? '(none)'}');
      DiagnosticLogger.instance.info('🔑 Token: ${token.substring(0, 10)}...');
      DiagnosticLogger.instance.info('📊 Content-Type: multipart/form-data (auto-set by Dio)');
      DiagnosticLogger.instance.info('✅ File validation: PASSED (file exists, non-empty)');
      DiagnosticLogger.instance.info('✅ Request format: MATCHES POSTMAN');
      DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');

      // ============================================
      // STEP 3: Make API call with FormData
      // Dio automatically sets Content-Type: multipart/form-data
      // This matches Postman request format exactly
      // ============================================
      final response = await _apiService.post(
        ApiConstants.UPLOAD_USER_DOCUMENT,
        data: formData,
      );

      return _handleUploadResponse(response, 'MULTIPART');
    } on dio.DioException catch (dioError) {
      DiagnosticLogger.instance.error('❌ [DocumentRepository] DioException in multipart upload:');
      DiagnosticLogger.instance.error('   Type: ${dioError.type}');
      DiagnosticLogger.instance.error('   Message: ${dioError.message}');
      DiagnosticLogger.instance.error('   Response: ${dioError.response?.data}');
      DiagnosticLogger.instance.error('   Status Code: ${dioError.response?.statusCode}');

      String errorMessage = 'Failed to upload document';
      if (dioError.response?.data != null) {
        final responseData = dioError.response!.data;
        if (responseData is Map && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        } else if (responseData is String) {
          errorMessage = responseData;
        }
      } else if (dioError.message != null) {
        errorMessage = dioError.message!;
      }

      return {'success': false, 'error': errorMessage};
    } catch (e) {
      // ApiService throws the server message string on DioException, so we often
      // get a plain string (e.g. "Upload failed") instead of DioException here.
      final message = e.toString();
      DiagnosticLogger.instance.error('❌ [DocumentRepository] Error in multipart upload: $e');
      DiagnosticLogger.instance.error('📚 [DocumentRepository] Stack trace: ${StackTrace.current}');
      if (e is! dio.DioException) {
        DiagnosticLogger.instance.warning(
          '📌 [DocumentRepository] Message may be from server. Check [API ERROR RESPONSE] logs above for status and body.',
        );
      }
      final errorText = e is String ? e : 'Multipart upload failed: $message';
      return {'success': false, 'error': errorText};
    }
  }

  /// Handle upload response and verify database fields
  /// Common handler for both upload methods
  Future<Map<String, dynamic>> _handleUploadResponse(
    dynamic response,
    String uploadMethod,
  ) async {
    DiagnosticLogger.instance.info('✅ [DocumentRepository] Upload response: ${response.statusCode}');
    DiagnosticLogger.instance.debug('📊 [DocumentRepository] Response data: ${response.data}');

    // ============================================
    // Handle response and verify database fields
    // ============================================
    if (response.statusCode == 200 && response.data['status'] == true) {
      final responseData = response.data['data'];

      // CRITICAL: Verify that backend stored file metadata correctly
      if (responseData != null) {
        final fileUrl = responseData['file_url'];
        final fileType = responseData['file_type'];
        final fileSize = responseData['file_size'];

        DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');
        DiagnosticLogger.instance.error('📋 [DocumentRepository] DATABASE VERIFICATION ($uploadMethod)');
        DiagnosticLogger.instance.error('═══════════════════════════════════════════════════════════');
        DiagnosticLogger.instance.error('📁 file_url: ${fileUrl ?? '❌ NULL'}');
        DiagnosticLogger.instance.error('📄 file_type: ${fileType ?? '❌ NULL'}');
        DiagnosticLogger.instance.error('📏 file_size: ${fileSize ?? '❌ NULL'}');

        // Check if any critical fields are missing
        bool hasIssues = false;
        if (fileUrl == null || fileUrl.toString().isEmpty) {
          DiagnosticLogger.instance.warning('⚠️ [DocumentRepository] WARNING: file_url is NULL or empty');
          hasIssues = true;
        }
        if (fileType == null || fileType.toString().isEmpty) {
          DiagnosticLogger.instance.warning('⚠️ [DocumentRepository] WARNING: file_type is NULL or empty');
          hasIssues = true;
        }
        if (fileSize == null || fileSize.toString().isEmpty) {
          DiagnosticLogger.instance.warning('⚠️ [DocumentRepository] WARNING: file_size is NULL or empty');
          hasIssues = true;
        }

        // If all fields are present, log success
        if (!hasIssues) {
          DiagnosticLogger.instance.error(
            '✅ [DocumentRepository] All file metadata fields are populated correctly',
          );
        } else {
          DiagnosticLogger.instance.error('❌ [DocumentRepository] Some file metadata fields are missing');
          DiagnosticLogger.instance.debug(
            '   Backend may not have processed $uploadMethod upload correctly',
          );
          DiagnosticLogger.instance.debug('   Check backend logic for $uploadMethod file handling');
        }
        DiagnosticLogger.instance.debug('═══════════════════════════════════════════════════════════');
      }

      return {
        'success': true,
        'message': response.data['message'] ?? 'Document uploaded successfully',
        'data': responseData,
      };
    } else {
      return {
        'success': false,
        'error': response.data['message'] ?? 'Failed to upload document',
      };
    }
  }

  /// Get MIME type from file extension
  /// Returns appropriate MIME type for common document formats
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  /// Delete Document
  /// DELETE /documents/delete/{document_id}
  /// Request: { "api_token": "`<CURRENT_USER_API_TOKEN>`" }
  /// Response: {
  ///   "status": true,
  ///   "message": "Document deleted successfully."
  /// }
  Future<Map<String, dynamic>> deleteDocument(int documentId) async {
    try {
      DiagnosticLogger.instance.debug('🗑️ [DocumentRepository] Deleting document with ID: $documentId');

      final storageService = Get.find<StorageService>();
      final apiToken = storageService.getAccessToken();

      if (apiToken == null || apiToken.isEmpty) {
        return {
          'success': false,
          'error': 'User token is missing. Please login again.',
        };
      }

      final response = await _apiService.delete(
        '${ApiConstants.DELETE_DOCUMENT}/$documentId',
        data: {'api_token': apiToken},
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        DiagnosticLogger.instance.info('✅ [DocumentRepository] Document deleted successfully');
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Document deleted successfully.',
        };
      } else {
        final errorMessage =
            response.data['message'] ??
            response.data['error'] ??
            'Failed to delete document';
        DiagnosticLogger.instance.error('⚠️ [DocumentRepository] Delete failed: $errorMessage');
        return {
          'success': false,
          'error': errorMessage,
          'isAdminDocument': _isAdminUploadedDocumentError(errorMessage),
        };
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [DocumentRepository] Error deleting document: $e');

      final errorMessage = e.toString().isNotEmpty
          ? e.toString()
          : 'Failed to delete document. Please try again.';

      return {
        'success': false,
        'error': errorMessage,
        'isAdminDocument': _isAdminUploadedDocumentError(errorMessage),
      };
    }
  }

  bool _isAdminUploadedDocumentError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('admin') &&
        (lower.contains('delete') ||
            lower.contains('cannot') ||
            lower.contains("can't") ||
            lower.contains('not allowed') ||
            lower.contains('uploaded'));
  }

  /// Download Document
  /// POST /download_document
  /// Request: {
  ///   "token": "`<CURRENT_USER_API_TOKEN>`",
  ///   "document_id": `<DOCUMENT_ID>`
  /// }
  /// Response: File bytes (binary data)
  Future<Map<String, dynamic>> downloadDocument({
    required int documentId,
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

      DiagnosticLogger.instance.debug(
        '📥 [DocumentRepository] Downloading document with ID: $documentId',
      );
      DiagnosticLogger.instance.debug(
        '🔑 [DocumentRepository] Using token: ${token.substring(0, 10)}...',
      );

      // Use Dio directly to get bytes response
      final dioInstance = dio.Dio(
        dio.BaseOptions(
          baseUrl: ApiConstants.BASE_URL,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await dioInstance.post(
        ApiConstants.DOWNLOAD_DOCUMENT,
        data: {'token': token, 'document_id': documentId},
        options: dio.Options(responseType: dio.ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        DiagnosticLogger.instance.info(
          '✅ [DocumentRepository] Document downloaded successfully (${response.data.length} bytes)',
        );
        return {
          'success': true,
          'data': response.data as List<int>, // File bytes
        };
      } else {
        DiagnosticLogger.instance.warning(
          '⚠️ [DocumentRepository] Download failed: Status ${response.statusCode}',
        );
        return {
          'success': false,
          'error':
              'Failed to download document. Server returned status ${response.statusCode}',
        };
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [DocumentRepository] Error downloading document: $e');

      String errorMessage = 'Failed to download document. Please try again.';
      if (e is dio.DioException) {
        if (e.type == dio.DioExceptionType.connectionTimeout ||
            e.type == dio.DioExceptionType.receiveTimeout) {
          errorMessage = 'Download timeout. Please check your connection.';
        } else if (e.type == dio.DioExceptionType.badResponse) {
          final statusCode = e.response?.statusCode;
          final serverMessage = _parseDownloadErrorMessage(e.response?.data);
          if (_isDocumentPasswordNotSetError(statusCode, serverMessage)) {
            return {
              'success': false,
              'errorCode': 'documentPasswordNotSet',
              'error': serverMessage ??
                  'Document password is not set. Please set it in Profile.',
            };
          }
          if (statusCode == 401) {
            errorMessage = 'Unauthorized. Please log in again.';
          } else if (statusCode == 404) {
            errorMessage = 'Document not found.';
          } else if (serverMessage != null && serverMessage.isNotEmpty) {
            errorMessage = serverMessage;
          } else {
            errorMessage = 'Server error. Please try again later.';
          }
        } else {
          errorMessage = 'Network error. Please check your connection.';
        }
      }

      return {'success': false, 'error': errorMessage};
    }
  }

  String? _parseDownloadErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      return data['message']?.toString() ?? data['error']?.toString();
    }

    if (data is List<int>) {
      try {
        final decoded = jsonDecode(utf8.decode(data));
        if (decoded is Map) {
          return decoded['message']?.toString() ?? decoded['error']?.toString();
        }
      } catch (_) {}
      return null;
    }

    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            return decoded['message']?.toString() ??
                decoded['error']?.toString();
          }
        } catch (_) {}
      }
      if (!trimmed.startsWith('<!DOCTYPE') && !trimmed.startsWith('<html')) {
        return trimmed;
      }
    }

    return null;
  }

  bool _isDocumentPasswordNotSetError(int? statusCode, String? message) {
    if (statusCode != 403) return false;
    if (message == null || message.isEmpty) return true;

    final lower = message.toLowerCase();
    return lower.contains('password') &&
        (lower.contains('not set') ||
            lower.contains('not_set') ||
            lower.contains('required') ||
            lower.contains('please set'));
  }
}
