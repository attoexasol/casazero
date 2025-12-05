import 'package:get/get.dart';
import '../../../data/models/document_category_model.dart';
import '../../../data/models/document_model.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../core/services/download_service.dart';
import '../../home/controllers/home_controller.dart';
import 'package:flutter/material.dart';

class DocumentsController extends GetxController {
  final DocumentRepository _repository = DocumentRepository();
  final DownloadService _downloadService = Get.find<DownloadService>();

  // Reactive variables for categories
  final RxList<DocumentCategoryModel> categories =
      <DocumentCategoryModel>[].obs;
  final RxBool isLoadingCategories = false.obs;

  // Reactive variables for documents
  final RxList<DocumentModel> documents = <DocumentModel>[].obs;
  final RxBool isLoadingDocuments = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDocumentCategories();
    fetchDocuments();
  }

  /// Fetch document categories from API
  Future<void> fetchDocumentCategories() async {
    try {
      isLoadingCategories.value = true;
      errorMessage.value = '';

      final result = await _repository.getDocumentCategories();

      if (result['success'] == true) {
        final List<DocumentCategoryModel> fetchedCategories = result['data'];

        // Always add "All" as the first category
        categories.value = fetchedCategories;
      } else {
        errorMessage.value = result['error'] ?? 'Failed to fetch categories';
        // Set empty list on error, "All" will still be shown in UI
        categories.value = [];
      }
    } catch (e) {
      print('Error in fetchDocumentCategories: $e');
      errorMessage.value = 'An error occurred while fetching categories';
      categories.value = [];
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// Fetch documents from API based on selected residence
  Future<void> fetchDocuments() async {
    try {
      isLoadingDocuments.value = true;
      errorMessage.value = '';
      hasError.value = false;

      // Get the selected residence ID from HomeController
      final HomeController homeController = Get.find<HomeController>();
      final residenceId = homeController.selectedResidence.value?.id;

      if (residenceId == null) {
        print('⚠️ No residence selected, using mock data');
        // Fallback to mock data if no residence is selected
        documents.value = DocumentModel.mockDocuments;
        isLoadingDocuments.value = false;
        return;
      }

      print('📄 Fetching documents for residence ID: $residenceId');

      final result = await _repository.getResidenceDocuments(residenceId);

      if (result['success'] == true) {
        final List<dynamic> documentsData = result['data'] ?? [];

        // Convert the data to DocumentModel objects
        final fetchedDocuments = documentsData
            .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
            .toList();

        documents.value = fetchedDocuments;

        print('✅ Loaded ${documents.length} documents from API');
      } else {
        print('⚠️ API Error: ${result['error']}');
        errorMessage.value = result['error'] ?? 'Failed to fetch documents';
        hasError.value = true;

        // Fallback to mock data on error
        documents.value = DocumentModel.mockDocuments;
      }
    } catch (e) {
      print('❌ Error in fetchDocuments: $e');
      errorMessage.value = 'An error occurred while fetching documents';
      hasError.value = true;

      // Fallback to mock data on exception
      documents.value = DocumentModel.mockDocuments;
    } finally {
      isLoadingDocuments.value = false;
    }
  }

  /// Download a document
  /// Shows loading dialog, downloads the file, and shows result
  Future<void> downloadDocument(DocumentModel document) async {
    try {
      // Validate that document has a file URL
      if (document.fileUrl == null || document.fileUrl!.isEmpty) {
        Get.snackbar(
          'downloadError'.tr,
          'Document URL is not available',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[700],
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Generate a clean filename
      final fileName = _generateFileName(document);
      final fileId = document.id;

      print('📥 Starting download: $fileName');
      print('📥 URL: ${document.fileUrl}');

      // Show downloading snackbar
      Get.snackbar(
        'downloading'.tr,
        document.title,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue[700],
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.download, color: Colors.white),
      );

      // Start the download
      final result = await _downloadService.downloadDocument(
        fileUrl: document.fileUrl!,
        fileName: fileName,
        fileId: fileId,
      );

      // Handle result
      if (result['success'] == true) {
        // Download successful
        Get.snackbar(
          'downloadSuccess'.tr,
          '${'downloadComplete'.tr}: ${result['fileName']}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[700],
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );

        print('✅ Download successful: ${result['filePath']}');
      } else {
        // Download failed
        Get.snackbar(
          'downloadFailed'.tr,
          result['error'] ?? 'downloadError'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[700],
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.white),
        );

        print('❌ Download failed: ${result['error']}');
      }
    } catch (e) {
      print('❌ Error downloading document: $e');
      Get.snackbar(
        'downloadFailed'.tr,
        'downloadError'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  /// Generate a clean filename from document data
  String _generateFileName(DocumentModel document) {
    // Try to extract filename from URL
    if (document.fileUrl != null && document.fileUrl!.isNotEmpty) {
      final urlParts = document.fileUrl!.split('/');
      if (urlParts.isNotEmpty) {
        final lastPart = urlParts.last;
        // If the last part has an extension, use it
        if (lastPart.contains('.')) {
          return lastPart;
        }
      }
    }

    // Generate filename from document title and type
    final cleanTitle = document.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final extension = document.type.toLowerCase();

    return '$cleanTitle.$extension';
  }

  /// Get download progress for a document
  double getDownloadProgress(String fileId) {
    return _downloadService.getProgress(fileId);
  }

  /// Check if a document is currently being downloaded
  bool isDocumentDownloading(String fileId) {
    return _downloadService.isFileDownloading(fileId);
  }

  /// Retry fetching categories (useful for error handling)
  void retryFetchCategories() {
    fetchDocumentCategories();
  }

  /// Retry fetching documents
  void retryFetchDocuments() {
    fetchDocuments();
  }

  /// Refresh all data (pull-to-refresh)
  Future<void> refreshData() async {
    await Future.wait([fetchDocumentCategories(), fetchDocuments()]);
  }
}
