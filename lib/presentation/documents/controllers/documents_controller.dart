import 'package:get/get.dart';
import '../../../data/models/document_category_model.dart';
import '../../../data/models/document_model.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../core/services/download_service.dart';
import '../../home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';

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
        categories.value = fetchedCategories;
      } else {
        errorMessage.value = result['error'] ?? 'Failed to fetch categories';
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
        documents.value = DocumentModel.mockDocuments;
        isLoadingDocuments.value = false;
        return;
      }

      print('📄 Fetching documents for residence ID: $residenceId');

      final result = await _repository.getResidenceDocuments(residenceId);

      if (result['success'] == true) {
        final List<dynamic> documentsData = result['data'] ?? [];

        final fetchedDocuments = documentsData
            .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
            .toList();

        documents.value = fetchedDocuments;

        print('✅ Loaded ${documents.length} documents from API');
      } else {
        print('⚠️ API Error: ${result['error']}');
        errorMessage.value = result['error'] ?? 'Failed to fetch documents';
        hasError.value = true;
        documents.value = DocumentModel.mockDocuments;
      }
    } catch (e) {
      print('❌ Error in fetchDocuments: $e');
      errorMessage.value = 'An error occurred while fetching documents';
      hasError.value = true;
      documents.value = DocumentModel.mockDocuments;
    } finally {
      isLoadingDocuments.value = false;
    }
  }

  /// Download a document
  /// Shows loading dialog, downloads the file, and shows result with Open button
  Future<void> downloadDocument(DocumentModel document) async {
    try {
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

      final fileName = _generateFileName(document);
      final fileId = document.id;

      print('📥 Starting download: $fileName');
      print('📥 URL: ${document.fileUrl}');

      Get.snackbar(
        'downloading'.tr,
        document.title,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue[700],
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.download, color: Colors.white),
      );

      final result = await _downloadService.downloadDocument(
        fileUrl: document.fileUrl!,
        fileName: fileName,
        fileId: fileId,
      );

      if (result['success'] == true) {
        final filePath = result['filePath'] as String;

        // Download successful - Show snackbar with Open button
        Get.snackbar(
          'downloadSuccess'.tr,
          '${'downloadComplete'.tr}: ${result['fileName']}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[700],
          colorText: Colors.white,
          duration: const Duration(
            seconds: 5,
          ), // Longer duration for user to tap Open
          icon: const Icon(Icons.check_circle, color: Colors.white),
          mainButton: TextButton(
            onPressed: () {
              // Close the snackbar first
              Get.closeCurrentSnackbar();
              // Open the file
              openFile(filePath, document.title);
            },
            child: Text(
              'openFile'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );

        print('✅ Download successful: $filePath');
      } else {
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

  /// Open a downloaded file with external app
  /// Uses native file manager or appropriate app viewer
  Future<void> openFile(String filePath, String fileName) async {
    try {
      print('📂 Opening file: $filePath');

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        Get.snackbar(
          'openFileFailed'.tr,
          'fileNotFound'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[700],
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.white),
        );
        print('❌ File not found: $filePath');
        return;
      }

      // Open the file using open_filex
      final result = await OpenFilex.open(filePath);

      print('📂 Open file result: ${result.type} - ${result.message}');

      // Handle the result
      switch (result.type) {
        case ResultType.done:
          // File opened successfully
          print('✅ File opened successfully');
          break;

        case ResultType.fileNotFound:
          Get.snackbar(
            'openFileFailed'.tr,
            'fileNotFound'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[700],
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          break;

        case ResultType.noAppToOpen:
          Get.snackbar(
            'openFileFailed'.tr,
            'noAppToOpen'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange[700],
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            icon: const Icon(Icons.warning, color: Colors.white),
          );
          break;

        case ResultType.permissionDenied:
          Get.snackbar(
            'openFileFailed'.tr,
            'permissionDenied'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[700],
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          break;

        case ResultType.error:
          Get.snackbar(
            'openFileFailed'.tr,
            result.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[700],
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          break;
      }
    } catch (e) {
      print('❌ Error opening file: $e');
      Get.snackbar(
        'openFileFailed'.tr,
        'openFileError'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  /// Share a document
  /// Downloads the file first, then shares it using native share
  Future<void> shareDocument(DocumentModel document) async {
    try {
      if (document.fileUrl == null || document.fileUrl!.isEmpty) {
        Get.snackbar(
          'shareError'.tr,
          'Document URL is not available',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[700],
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final fileName = _generateFileName(document);
      final fileId = document.id;

      print('📤 Starting share process: $fileName');

      Get.snackbar(
        'preparingShare'.tr,
        document.title,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue[700],
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.share, color: Colors.white),
      );

      final result = await _downloadService.downloadDocument(
        fileUrl: document.fileUrl!,
        fileName: fileName,
        fileId: fileId,
      );

      if (result['success'] == true) {
        final filePath = result['filePath'] as String;
        final file = File(filePath);

        if (await file.exists()) {
          print('✅ File ready for sharing: $filePath');

          final xFile = XFile(filePath);
          await Share.shareXFiles(
            [xFile],
            text: document.title,
            subject: 'sharingDocument'.tr,
          );

          print('✅ Share dialog opened successfully');

          Get.snackbar(
            'shareSuccess'.tr,
            document.title,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green[700],
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
        } else {
          throw Exception('File not found after download');
        }
      } else {
        Get.snackbar(
          'shareFailed'.tr,
          result['error'] ?? 'shareError'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[700],
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.white),
        );
        print('❌ Share failed: ${result['error']}');
      }
    } catch (e) {
      print('❌ Error sharing document: $e');
      Get.snackbar(
        'shareFailed'.tr,
        'shareError'.tr,
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
    if (document.fileUrl != null && document.fileUrl!.isNotEmpty) {
      final urlParts = document.fileUrl!.split('/');
      if (urlParts.isNotEmpty) {
        final lastPart = urlParts.last;
        if (lastPart.contains('.')) {
          return lastPart;
        }
      }
    }

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

  /// Retry fetching categories
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
