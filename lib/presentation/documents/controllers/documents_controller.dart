import 'package:get/get.dart';
import '../../../data/models/document_category_model.dart';
import '../../../data/models/document_model.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../core/services/download_service.dart';
import '../../../core/services/file_opener_service.dart';
import '../../../core/controllers/message_popup_controller.dart';
import '../../../core/widgets/custom_message_popup.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../models/upload_result.dart';

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

  // Document counts per category
  final RxInt totalDocumentCount = 0.obs;

  // Upload state
  final RxBool isUploading = false.obs;
  final RxBool uploadSuccess = false.obs;
  final RxString uploadErrorMessage = ''.obs;

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

        // If documents are already loaded, update category counts
        if (documents.isNotEmpty) {
          _updateCategoryCounts(documents);
        }
      } else {
        errorMessage.value = result['error'] ?? 'failedToFetchCategories'.tr;
        categories.value = [];
      }
    } catch (e) {
      print('Error in fetchDocumentCategories: $e');
      errorMessage.value = 'errorFetchingCategories'.tr;
      categories.value = [];
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// Fetch documents from API
  /// Uses the documents/by_unit endpoint to get all documents
  Future<void> fetchDocuments() async {
    try {
      isLoadingDocuments.value = true;
      errorMessage.value = '';
      hasError.value = false;

      print('📄 Fetching documents by unit from API');

      final result = await _repository.getDocumentsByUnit();

      if (result['success'] == true) {
        final dynamic data = result['data'];
        final List<DocumentModel> fetchedDocuments = data is List<DocumentModel>
            ? data
            : (data as List<dynamic>?)
                      ?.map((item) => item as DocumentModel)
                      .toList() ??
                  [];

        documents.value = fetchedDocuments;
        totalDocumentCount.value = fetchedDocuments.length;

        // Update category counts based on loaded documents
        _updateCategoryCounts(fetchedDocuments);

        print('✅ Loaded ${documents.length} documents from API');
      } else {
        print('⚠️ API Error: ${result['error']}');
        errorMessage.value = result['error'] ?? 'failedToFetchDocuments'.tr;
        hasError.value = true;
        documents.clear();
      }
    } catch (e) {
      print('❌ Error in fetchDocuments: $e');
      errorMessage.value = 'errorFetchingDocuments'.tr;
      hasError.value = true;
      documents.clear();
    } finally {
      isLoadingDocuments.value = false;
    }
  }

  /// Download a document
  /// Shows loading dialog, downloads the file, and shows result with Open button
  Future<void> downloadDocument(DocumentModel document) async {
    try {
      final documentId = int.tryParse(document.id);
      if (documentId == null) {
        MessagePopupController.showError(
          messageKey: 'invalidDocumentId'.tr,
          titleKey: 'downloadError'.tr,
        );
        return;
      }

      final fileName = _generateFileName(document);
      final fileId = document.id;

      print('📥 Starting download: $fileName');

      // 1. Show downloading popup (stays open)
      MessagePopupController.showDownloading(
        messageKey: 'downloading'.tr + ': ${document.title}',
      );

      // 2. Call API
      final apiResult = await _repository.downloadDocument(
        documentId: documentId,
      );

      if (apiResult['success'] != true) {
        MessagePopupController.closePopup();
        await MessagePopupController.showError(
          messageKey: apiResult['error'] ?? 'downloadError'.tr,
          titleKey: 'downloadFailed'.tr,
        );
        return;
      }

      // Get file bytes from API response
      final fileBytes = apiResult['data'] as List<int>?;
      if (fileBytes == null || fileBytes.isEmpty) {
        if (Get.isDialogOpen ?? false) Get.back();
        await MessagePopupController.showError(
          messageKey: 'noFileDataReceived'.tr,
          titleKey: 'downloadFailed'.tr,
        );
        print('❌ [DocumentsController] No file bytes received');
        return;
      }

      // Save the file bytes
      final saveResult = await _downloadService.saveDocumentBytes(
        fileBytes: fileBytes,
        fileName: fileName,
        fileId: fileId,
      );

      if (saveResult['success'] == true) {
        final filePath = saveResult['filePath'] as String;

        // CRITICAL: Verify file exists before showing confirmation dialog
        final savedFile = File(filePath);
        final fileExists = await savedFile.exists();

        if (!fileExists) {
          print(
            '❌ [DocumentsController] File does not exist after save: $filePath',
          );
          if (Get.isDialogOpen ?? false) Get.back();
          await MessagePopupController.showError(
            messageKey: 'fileNotSavedCorrectly'.tr,
            titleKey: 'downloadFailed'.tr,
          );
          return;
        }

        // Verify file has content
        final fileSize = await savedFile.length();
        if (fileSize == 0) {
          print('❌ [DocumentsController] File is empty after save: $filePath');
          if (Get.isDialogOpen ?? false) Get.back();
          await MessagePopupController.showError(
            messageKey: 'fileEmptyPleaseDownloadAgain'.tr,
            titleKey: 'downloadFailed'.tr,
          );
          return;
        }

        print('✅ [DocumentsController] Download successful: $filePath');
        print(
          '✅ [DocumentsController] File verified: exists=${fileExists}, size=${fileSize} bytes',
        );

        // Close "downloading" info, then show confirmation (no middle success message)
        if (Get.isDialogOpen ?? false) Get.back();
        await _showDownloadConfirmationDialog(filePath, document.title);
      } else {
        if (Get.isDialogOpen ?? false) Get.back();
        await MessagePopupController.showError(
          messageKey: saveResult['error'] ?? 'downloadError'.tr,
          titleKey: 'downloadFailed'.tr,
        );
        print('❌ [DocumentsController] Save failed: ${saveResult['error']}');
      }
    } catch (e) {
      print('❌ [DocumentsController] Error downloading document: $e');
      if (Get.isDialogOpen ?? false) Get.back();
      await MessagePopupController.showError(
        messageKey: 'downloadError'.tr,
        titleKey: 'downloadFailed'.tr,
      );
    }
  }

  /// Show download confirmation dialog with Open With and Cancel options
  /// File is NOT opened automatically - only when user taps "Open With"
  /// NOTE: File existence should be verified BEFORE calling this method
  Future<void> _showDownloadConfirmationDialog(
    String filePath,
    String fileName,
  ) async {
    try {
      // Double-check file exists (defensive programming)
      final file = File(filePath);
      final fileExists = await file.exists();

      if (!fileExists) {
        print(
          '❌ [DocumentsController] File not found in confirmation dialog: $filePath',
        );
        MessagePopupController.showError(
          messageKey: 'fileNotFoundInStorage'.tr,
          titleKey: 'openFileFailed'.tr,
        );
        return;
      }

      // Verify file has content
      final fileSize = await file.length();
      if (fileSize == 0) {
        print(
          '❌ [DocumentsController] File is empty in confirmation dialog: $filePath',
        );
        MessagePopupController.showError(
          messageKey: 'fileEmptyPleaseDownloadAgain'.tr,
          titleKey: 'openFileFailed'.tr,
        );
        return;
      }

      print(
        '✅ [DocumentsController] Showing confirmation dialog for file: $filePath (${fileSize} bytes)',
      );

      // Show confirmation popup using CustomMessagePopup
      final shouldOpen = await MessagePopupController.showCustom(
        messageKey: 'fileDownloadedSuccessfully'.tr.replaceAll(
          '{fileName}',
          fileName,
        ),
        titleKey: 'downloadSuccess'.tr,
        messageType: MessageType.success,
        primaryAction: PopupAction(labelKey: 'openWith', isPrimary: true),
        secondaryAction: PopupAction(labelKey: 'cancel', isPrimary: false),
        barrierDismissible: true,
      );

      // Only open file if user explicitly tapped "Open With"
      if (shouldOpen == true) {
        print('📂 User chose to open file: $fileName');
        await _openFileFromLocalStorage(filePath, fileName);
      } else {
        print(
          '📂 User cancelled file opening. File remains saved at: $filePath',
        );
      }
    } catch (e) {
      print('❌ Error showing download confirmation dialog: $e');
      MessagePopupController.showError(
        messageKey: 'anErrorOccurred'.tr,
        titleKey: 'error'.tr,
      );
    }
  }

  /// Open file from local storage (only called when user explicitly chooses to open)
  Future<void> _openFileFromLocalStorage(
    String filePath,
    String fileName,
  ) async {
    try {
      // Verify file exists before attempting to open
      final file = File(filePath);
      final fileExists = await file.exists();

      if (!fileExists) {
        print(
          '❌ [DocumentsController] File not found when trying to open: $filePath',
        );
        MessagePopupController.showError(
          messageKey: 'fileNotFoundInStorage'.tr,
          titleKey: 'openFileFailed'.tr,
        );
        return;
      }

      // Verify file has content
      final fileSize = await file.length();
      if (fileSize == 0) {
        print(
          '❌ [DocumentsController] File is empty when trying to open: $filePath',
        );
        MessagePopupController.showError(
          messageKey: 'fileEmptyPleaseDownloadAgain'.tr,
          titleKey: 'openFileFailed'.tr,
        );
        return;
      }

      print(
        '📂 [DocumentsController] Opening file from local storage: $filePath (${fileSize} bytes)',
      );

      // CRITICAL: Force native chooser for ALL file types (including images)
      // Use platform channel which uses Intent.createChooser on Android
      // This ALWAYS shows the app chooser, preventing auto-open for images
      try {
        final result = await FileOpenerService.openWithChooser(filePath);

        print(
          '📂 [DocumentsController] Open file result: ${result.type} - ${result.message}',
        );

        // Handle the result
        if (result.type == ResultType.noAppToOpen) {
          MessagePopupController.showWarning(
            messageKey: 'noAppToOpen'.tr,
            titleKey: 'openFileFailed'.tr,
          );
        } else if (result.type == ResultType.error ||
            result.type == ResultType.fileNotFound) {
          MessagePopupController.showError(
            messageKey: result.message.isNotEmpty
                ? result.message
                : 'openFileError'.tr,
            titleKey: 'openFileFailed'.tr,
          );
        } else if (result.type == ResultType.done) {
          print('✅ [DocumentsController] File chooser shown successfully');
        }
      } catch (e) {
        print('❌ [DocumentsController] Error opening file: $e');
        MessagePopupController.showError(
          messageKey: 'openFileError'.tr,
          titleKey: 'openFileFailed'.tr,
        );
      }
    } catch (e) {
      print(
        '❌ [DocumentsController] Error opening file from local storage: $e',
      );
      MessagePopupController.showError(
        messageKey: 'openFileError'.tr,
        titleKey: 'openFileFailed'.tr,
      );
    }
  }

  /// Show native "Open with" chooser with available apps to open the file
  /// Uses open_filex which shows native Android chooser or iOS share sheet
  /// NOTE: This method is kept for backward compatibility but is no longer called automatically
  Future<void> _showOpenFileBottomSheet(
    String filePath,
    String fileName,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        MessagePopupController.showError(
          messageKey: 'fileNotFound'.tr,
          titleKey: 'openFileFailed'.tr,
        );
        return;
      }

      // Use open_filex to show native "Open with" chooser
      // This will show all available apps that can open the file type
      print('📂 Opening native "Open with" chooser for file: $fileName');
      final result = await OpenFilex.open(filePath);

      print('📂 Open file result: ${result.type} - ${result.message}');

      // Handle the result
      if (result.type == ResultType.noAppToOpen) {
        MessagePopupController.showWarning(
          messageKey: 'noAppToOpen'.tr,
          titleKey: 'openFileFailed'.tr,
        );
      } else if (result.type == ResultType.error ||
          result.type == ResultType.fileNotFound) {
        MessagePopupController.showError(
          messageKey: result.message.isNotEmpty
              ? result.message
              : 'openFileError'.tr,
          titleKey: 'openFileFailed'.tr,
        );
      }
    } catch (e) {
      print('❌ Error showing file chooser: $e');
      MessagePopupController.showError(
        messageKey: 'openFileError'.tr,
        titleKey: 'openFileFailed'.tr,
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
        MessagePopupController.showError(
          messageKey: 'fileNotFound'.tr,
          titleKey: 'openFileFailed'.tr,
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
          MessagePopupController.showError(
            messageKey: 'fileNotFound'.tr,
            titleKey: 'openFileFailed'.tr,
          );
          break;

        case ResultType.noAppToOpen:
          MessagePopupController.showWarning(
            messageKey: 'noAppToOpen'.tr,
            titleKey: 'openFileFailed'.tr,
          );
          break;

        case ResultType.permissionDenied:
          MessagePopupController.showError(
            messageKey: 'permissionDenied'.tr,
            titleKey: 'openFileFailed'.tr,
          );
          break;

        case ResultType.error:
          MessagePopupController.showError(
            messageKey: result.message,
            titleKey: 'openFileFailed'.tr,
          );
          break;
      }
    } catch (e) {
      print('❌ Error opening file: $e');
      MessagePopupController.showError(
        messageKey: 'openFileError'.tr,
        titleKey: 'openFileFailed'.tr,
      );
    }
  }

  /// Share a document
  /// Downloads the file first, then shares it using native share
  Future<void> shareDocument(DocumentModel document) async {
    try {
      if (document.fileUrl == null || document.fileUrl!.isEmpty) {
        MessagePopupController.showError(
          messageKey: 'documentUrlNotAvailable'.tr,
          titleKey: 'shareError'.tr,
        );
        return;
      }

      final fileName = _generateFileName(document);
      final fileId = document.id;

      print('📤 Starting share process: $fileName');

      // Show preparing share info (no auto-dismiss; we close when done)
      MessagePopupController.showInfo(
        messageKey: 'preparingShare'.tr + ': ${document.title}',
        titleKey: '',
        autoDismissSeconds: 0,
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

          if (Get.isDialogOpen ?? false) Get.back();
          final xFile = XFile(filePath);
          await Share.shareXFiles(
            [xFile],
            text: document.title,
            subject: 'sharingDocument'.tr,
          );

          print('✅ Share dialog opened successfully');

          // No confirmation; just success message for 3 seconds
          // await MessagePopupController.showSuccess(
          //   messageKey: 'shareSuccess'.tr + ': ${document.title}',
          //   titleKey: '',
          // );
        } else {
          throw Exception('File not found after download');
        }
      } else {
        if (Get.isDialogOpen ?? false) Get.back();
        await MessagePopupController.showError(
          messageKey: result['error'] ?? 'shareError'.tr,
          titleKey: 'shareFailed'.tr,
        );
        print('❌ Share failed: ${result['error']}');
      }
    } catch (e) {
      print('❌ Error sharing document: $e');
      if (Get.isDialogOpen ?? false) Get.back();
      await MessagePopupController.showError(
        messageKey: 'shareError'.tr,
        titleKey: 'shareFailed'.tr,
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

  /// Upload a document
  /// Returns UploadResult - NO side effects, NO snackbars, NO UI updates
  /// UI layer must handle snackbars and dialog closing
  Future<UploadResult> uploadDocument({
    required File documentFile,
    required String documentTitle,
    int? documentCategoryId,
    String? documentType,
    String? documentDescription,
  }) async {
    isUploading.value = true;

    try {
      int? categoryId =
          documentCategoryId ??
          (documentType != null
              ? _mapDocumentTypeToCategoryId(documentType)
              : null);

      if (categoryId == null) {
        isUploading.value = false;
        return UploadResult.error('invalidDocumentCategorySelected'.tr);
      }

      final result = await _repository.uploadDocument(
        documentFile: documentFile,
        documentTitle: documentTitle,
        documentCategory: categoryId,
        documentDescription: documentDescription,
      );

      // Check if upload succeeded
      final bool isSuccess = result['success'] == true;

      // Defensive check: if message contains "successfully", treat as success
      // This prevents success messages from being routed to error snackbar
      final String? message = result['message'] as String?;
      final String? error = result['error'] as String?;
      final String? checkMessage = error ?? message;
      final bool hasSuccessMessage =
          checkMessage?.toLowerCase().contains('successfully') ?? false;

      if (isSuccess || hasSuccessMessage) {
        // Refresh documents silently (non-blocking)
        fetchDocuments().catchError((_) {});

        isUploading.value = false;
        return UploadResult.success('documentUploadSuccess'.tr);
      } else {
        final String errorMessage = error ?? 'documentUploadError'.tr;
        isUploading.value = false;
        return UploadResult.error(errorMessage);
      }
    } catch (e) {
      isUploading.value = false;
      return UploadResult.error('documentUploadError'.tr);
    }
  }

  /// Map document type string to category ID
  /// Uses the categories list to find matching category
  int? _mapDocumentTypeToCategoryId(String documentType) {
    // Map document type values to category names
    final Map<String, String> typeToCategoryName = {
      'ownership_legal': 'Ownership & Legal',
      'technical_building': 'Technical Building',
      'energy_environmental': 'Energy & Environmental',
      'compliance_safety': 'Compliance & Safety',
      'administrative_maintenance': 'Administrative & Maintenance',
    };

    final categoryName = typeToCategoryName[documentType];
    if (categoryName == null) {
      print('⚠️ [DocumentsController] Unknown document type: $documentType');
      return null;
    }

    // Find category ID from categories list
    try {
      final category = categories.firstWhere(
        (cat) =>
            cat.categoryName.toLowerCase().trim() ==
            categoryName.toLowerCase().trim(),
      );

      print(
        '✅ [DocumentsController] Mapped "$documentType" to category "${category.categoryName}" (ID: ${category.id})',
      );
      return category.id;
    } catch (e) {
      // Try fallback: match by partial name
      try {
        final fallbackCategory = categories.firstWhere(
          (cat) => cat.categoryName.toLowerCase().contains(
            categoryName.toLowerCase().split(' ').first,
          ),
        );

        print(
          '✅ [DocumentsController] Mapped "$documentType" to category "${fallbackCategory.categoryName}" (ID: ${fallbackCategory.id}) - fallback match',
        );
        return fallbackCategory.id;
      } catch (e2) {
        // No match found
      }
    }

    print(
      '⚠️ [DocumentsController] Could not find category for type: $documentType',
    );
    return null;
  }

  /// Update category counts based on loaded documents
  void _updateCategoryCounts(List<DocumentModel> documents) {
    // Create a map to count documents per category (case-insensitive)
    final Map<String, int> categoryCounts = {};

    // Count documents by category name (normalize for matching)
    for (var doc in documents) {
      final categoryName = doc.category.trim();
      if (categoryName.isNotEmpty) {
        categoryCounts[categoryName] = (categoryCounts[categoryName] ?? 0) + 1;
      }
    }

    // Update category models with counts (case-insensitive matching)
    final updatedCategories = categories.map((category) {
      // Try exact match first
      var count = categoryCounts[category.categoryName] ?? 0;

      // If no exact match, try case-insensitive match
      if (count == 0) {
        for (var entry in categoryCounts.entries) {
          if (entry.key.toLowerCase().trim() ==
              category.categoryName.toLowerCase().trim()) {
            count = entry.value;
            break;
          }
        }
      }

      return category.copyWith(count: count);
    }).toList();

    categories.value = updatedCategories;

    print('📊 Updated category counts:');
    for (var cat in updatedCategories) {
      print('  - ${cat.categoryName}: ${cat.count}');
    }
  }

  // -------------------------------------------------------------------------
  // UPLOAD SNACKBARS REMOVED
  // -------------------------------------------------------------------------
  // Snackbars are now handled ONLY in UI layer (AddDocumentDialog)
  // Controller returns UploadResult - no side effects

  /// Delete a document
  /// Calls the delete API and removes the document from the list on success
  Future<bool> deleteDocument(DocumentModel document) async {
    try {
      // Parse document ID from String to int (API expects int)
      final documentId = int.tryParse(document.id);
      if (documentId == null) {
        print('❌ [DocumentsController] Invalid document ID: ${document.id}');
        MessagePopupController.showError(
          messageKey: 'invalidDocumentId'.tr,
          titleKey: 'deleteFailed'.tr,
        );
        return false;
      }

      print(
        '🗑️ [DocumentsController] Deleting document: ${document.title} (ID: $documentId)',
      );

      // Call delete API
      final result = await _repository.deleteDocument(documentId);

      if (result['success'] == true) {
        print('✅ [DocumentsController] Delete success, removing from UI');

        // Remove document from reactive list immediately
        documents.removeWhere((d) => d.id == document.id);

        // Update total count
        totalDocumentCount.value = documents.length;

        // Update category counts
        _updateCategoryCounts(documents.toList());

        // Show success popup
        MessagePopupController.showSuccess(
          messageKey: 'documentDeletedSuccessfully'.tr.replaceAll(
            '{title}',
            document.title,
          ),
          titleKey: 'documentDeleted'.tr,
        );

        return true;
      } else {
        // Show error popup
        MessagePopupController.showError(
          messageKey: result['error'] ?? 'failedToDeleteDocument'.tr,
          titleKey: 'deleteFailed'.tr,
        );
        print('❌ [DocumentsController] Delete failed: ${result['error']}');
        return false;
      }
    } catch (e) {
      print('❌ [DocumentsController] Error deleting document: $e');
      MessagePopupController.showError(
        messageKey: 'errorDeletingDocument'.tr,
        titleKey: 'deleteFailed'.tr,
      );
      return false;
    }
  }
}
