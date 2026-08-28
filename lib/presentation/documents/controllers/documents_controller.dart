import 'package:get/get.dart';
import '../../../data/models/document_category_model.dart';
import '../../../data/models/document_model.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../core/services/download_service.dart';
import '../../../core/services/file_opener_service.dart';
import '../../../core/controllers/message_popup_controller.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../models/upload_result.dart';
import 'package:casazero/core/logging/diagnostic_logger.dart';

class DocumentsController extends GetxController {
  final DocumentRepository _repository = DocumentRepository();
  final DownloadService _downloadService = Get.find<DownloadService>();
  final bool skipInitialFetch;

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

  DocumentsController({this.skipInitialFetch = false});

  @override
  void onInit() {
    super.onInit();
    if (skipInitialFetch) return;
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

        // If documents are already loaded (e.g. preloaded), sync all counts
        if (documents.isNotEmpty) {
          _syncCountsFromDocuments();
        }
      } else {
        errorMessage.value = result['error'] ?? 'failedToFetchCategories'.tr;
        categories.value = [];
      }
    } catch (e) {
      DiagnosticLogger.instance.error('Error in fetchDocumentCategories: $e');
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

      DiagnosticLogger.instance.debug('📄 Fetching documents by unit from API');

      final result = await _repository.getDocumentsByUnit();

      if (result['success'] == true) {
        final dynamic data = result['data'];
        final List<DocumentModel> fetchedDocuments = data is List<DocumentModel>
            ? data
            : (data as List<dynamic>?)
                      ?.map((item) => item as DocumentModel)
                      .toList() ??
                  [];

        _applyLoadedDocuments(fetchedDocuments);

        DiagnosticLogger.instance.error('✅ Loaded ${documents.length} documents from API');
      } else {
        DiagnosticLogger.instance.error('⚠️ API Error: ${result['error']}');
        errorMessage.value = result['error'] ?? 'failedToFetchDocuments'.tr;
        hasError.value = true;
        clearDocuments();
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ Error in fetchDocuments: $e');
      errorMessage.value = 'errorFetchingDocuments'.tr;
      hasError.value = true;
      clearDocuments();
    } finally {
      isLoadingDocuments.value = false;
    }
  }

  /// Download a document
  /// When [showDownloadingPopup] is false, no "Downloading…" modal is shown (e.g. for button-level loader).
  /// When [skipOpenCancelConfirmation] is true, after success goes directly to native app chooser (no Open/Cancel dialog).
  Future<void> downloadDocument(
    DocumentModel document, {
    bool showDownloadingPopup = true,
    bool skipOpenCancelConfirmation = false,
  }) async {
    try {
      final documentId = int.tryParse(document.id);
      if (documentId == null) {
        MessagePopupController.showError(
          messageKey: 'invalidDocumentId',
          titleKey: 'downloadFailed',
        );
        return;
      }

      final fileName = _generateFileName(document);
      final fileId = document.id;

      DiagnosticLogger.instance.debug('📥 Starting download: $fileName');

      if (showDownloadingPopup) {
        MessagePopupController.showDownloading(
          messageKey: '${'downloading'.tr}: ${document.title}',
        );
      }

      // Call API
      final apiResult = await _repository.downloadDocument(
        documentId: documentId,
      );

      if (apiResult['success'] != true) {
        if (showDownloadingPopup && (Get.isDialogOpen ?? false)) Get.back();
        await MessagePopupController.showError(
          messageKey: apiResult['errorCode'] == 'documentPasswordNotSet'
              ? 'documentPasswordNotSet'
              : 'downloadError',
          titleKey: 'downloadFailed',
        );
        return;
      }

      // Get file bytes from API response
      final fileBytes = apiResult['data'] as List<int>?;
      if (fileBytes == null || fileBytes.isEmpty) {
        if (showDownloadingPopup && (Get.isDialogOpen ?? false)) Get.back();
        await MessagePopupController.showError(
          messageKey: 'noFileDataReceived',
          titleKey: 'downloadFailed',
        );
        DiagnosticLogger.instance.error('❌ [DocumentsController] No file bytes received');
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
          DiagnosticLogger.instance.error(
            '❌ [DocumentsController] File does not exist after save: $filePath',
          );
          if (showDownloadingPopup && (Get.isDialogOpen ?? false)) Get.back();
          await MessagePopupController.showError(
            messageKey: 'fileNotSavedCorrectly',
            titleKey: 'downloadFailed',
          );
          return;
        }

        // Verify file has content
        final fileSize = await savedFile.length();
        if (fileSize == 0) {
          DiagnosticLogger.instance.error('❌ [DocumentsController] File is empty after save: $filePath');
          if (showDownloadingPopup && (Get.isDialogOpen ?? false)) Get.back();
          await MessagePopupController.showError(
            messageKey: 'fileEmptyPleaseDownloadAgain',
            titleKey: 'downloadFailed',
          );
          return;
        }

        DiagnosticLogger.instance.info('✅ [DocumentsController] Download successful: $filePath');
        DiagnosticLogger.instance.info(
          '✅ [DocumentsController] File verified: exists=$fileExists, size=$fileSize bytes',
        );

        if (showDownloadingPopup && (Get.isDialogOpen ?? false)) Get.back();

        if (skipOpenCancelConfirmation) {
          await _openFileFromLocalStorage(filePath, document.title);
        } else {
          final userWantsOpen = await FileOpenerService.showNativeOpenCancelConfirmation(
            title: 'downloadSuccess'.tr,
            message: 'fileDownloadedSuccessfully'.tr.replaceAll(
              '{fileName}',
              document.title,
            ),
          );
          if (!userWantsOpen) {
            DiagnosticLogger.instance.debug('📂 User cancelled. File remains saved at: $filePath');
            return;
          }
          await _openFileFromLocalStorage(filePath, document.title);
        }
      } else {
        if (showDownloadingPopup && (Get.isDialogOpen ?? false)) Get.back();
        await MessagePopupController.showError(
          messageKey: 'downloadError',
          titleKey: 'downloadFailed',
        );
        DiagnosticLogger.instance.error('❌ [DocumentsController] Save failed: ${saveResult['error']}');
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [DocumentsController] Error downloading document: $e');
      if (showDownloadingPopup && (Get.isDialogOpen ?? false)) Get.back();
      await MessagePopupController.showError(
        messageKey: 'downloadError',
        titleKey: 'downloadFailed',
      );
    }
  }

  /// Open file from local storage (called after successful download to show native open/chooser)
  Future<void> _openFileFromLocalStorage(
    String filePath,
    String fileName,
  ) async {
    try {
      // Verify file exists before attempting to open
      final file = File(filePath);
      final fileExists = await file.exists();

      if (!fileExists) {
        DiagnosticLogger.instance.error(
          '❌ [DocumentsController] File not found when trying to open: $filePath',
        );
        MessagePopupController.showError(
          messageKey: 'fileNotFoundInStorage',
          titleKey: 'openFileFailed',
        );
        return;
      }

      // Verify file has content
      final fileSize = await file.length();
      if (fileSize == 0) {
        DiagnosticLogger.instance.error(
          '❌ [DocumentsController] File is empty when trying to open: $filePath',
        );
        MessagePopupController.showError(
          messageKey: 'fileEmptyPleaseDownloadAgain',
          titleKey: 'openFileFailed',
        );
        return;
      }

      DiagnosticLogger.instance.debug(
        '📂 [DocumentsController] Opening file from local storage: $filePath ($fileSize bytes)',
      );

      // CRITICAL: Force native chooser for ALL file types (including images)
      // Use platform channel which uses Intent.createChooser on Android
      // This ALWAYS shows the app chooser, preventing auto-open for images
      try {
        final result = await FileOpenerService.openWithChooser(filePath);

        DiagnosticLogger.instance.debug(
          '📂 [DocumentsController] Open file result: ${result.type} - ${result.message}',
        );

        // Handle the result
        if (result.type == ResultType.noAppToOpen) {
          MessagePopupController.showWarning(
            messageKey: 'noAppToOpen',
            titleKey: 'openFileFailed',
          );
        } else if (result.type == ResultType.error ||
            result.type == ResultType.fileNotFound) {
          MessagePopupController.showError(
            messageKey: 'openFileError',
            titleKey: 'openFileFailed',
          );
        } else if (result.type == ResultType.done) {
          DiagnosticLogger.instance.error('✅ [DocumentsController] File chooser shown successfully');
        }
      } catch (e) {
        DiagnosticLogger.instance.error('❌ [DocumentsController] Error opening file: $e');
        MessagePopupController.showError(
          messageKey: 'openFileError',
          titleKey: 'openFileFailed',
        );
      }
    } catch (e) {
      DiagnosticLogger.instance.error(
        '❌ [DocumentsController] Error opening file from local storage: $e',
      );
      MessagePopupController.showError(
        messageKey: 'openFileError',
        titleKey: 'openFileFailed',
      );
    }
  }

  /// Open a downloaded file with external app
  /// Uses native file manager or appropriate app viewer
  Future<void> openFile(String filePath, String fileName) async {
    try {
      DiagnosticLogger.instance.error('📂 Opening file: $filePath');

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        MessagePopupController.showError(
          messageKey: 'fileNotFound',
          titleKey: 'openFileFailed',
        );
        DiagnosticLogger.instance.error('❌ File not found: $filePath');
        return;
      }

      // Open the file using open_filex
      final result = await OpenFilex.open(filePath);

      DiagnosticLogger.instance.info('📂 Open file result: ${result.type} - ${result.message}');

      // Handle the result
      switch (result.type) {
        case ResultType.done:
          // File opened successfully
          DiagnosticLogger.instance.error('✅ File opened successfully');
          break;

        case ResultType.fileNotFound:
          MessagePopupController.showError(
            messageKey: 'fileNotFound'.tr,
            titleKey: 'openFileFailed'.tr,
          );
          break;

        case ResultType.noAppToOpen:
          MessagePopupController.showWarning(
            messageKey: 'noAppToOpen',
            titleKey: 'openFileFailed',
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
      DiagnosticLogger.instance.error('❌ Error opening file: $e');
      MessagePopupController.showError(
        messageKey: 'openFileError',
        titleKey: 'openFileFailed',
      );
    }
  }

  /// Share a document
  /// Downloads the file first via API, then shares it using native share
  Future<void> shareDocument(
    DocumentModel document, {
    Rect? shareOrigin,
  }) async {
    try {
      final documentId = int.tryParse(document.id);
      if (documentId == null) {
        MessagePopupController.showError(
          messageKey: 'invalidDocumentId',
          titleKey: 'shareFailed',
        );
        return;
      }

      final fileName = _generateFileName(document);
      final fileId = document.id;

      DiagnosticLogger.instance.debug('📤 Starting share process: $fileName');

      // Show preparing share info (no auto-dismiss; we close when done)
      MessagePopupController.showInfo(
        messageKey: '${'preparingShare'.tr}: ${document.title}',
        titleKey: '',
        autoDismissSeconds: 0,
      );

      final apiResult = await _repository.downloadDocument(
        documentId: documentId,
      );

      if (apiResult['success'] != true) {
        if (Get.isDialogOpen ?? false) Get.back();
        await MessagePopupController.showError(
          messageKey: 'shareError',
          titleKey: 'shareFailed',
        );
        DiagnosticLogger.instance.error('❌ Share failed: ${apiResult['error']}');
        return;
      }

      final fileBytes = apiResult['data'] as List<int>?;
      if (fileBytes == null || fileBytes.isEmpty) {
        if (Get.isDialogOpen ?? false) Get.back();
        await MessagePopupController.showError(
          messageKey: 'noFileDataReceived',
          titleKey: 'shareFailed',
        );
        return;
      }

      final saveResult = await _downloadService.saveDocumentBytes(
        fileBytes: fileBytes,
        fileName: fileName,
        fileId: fileId,
      );

      if (saveResult['success'] == true) {
        final filePath = saveResult['filePath'] as String;
        final file = File(filePath);

        if (await file.exists()) {
          DiagnosticLogger.instance.info('✅ File ready for sharing: $filePath');

          if (Get.isDialogOpen ?? false) Get.back();
          // iOS needs the preparing dialog fully dismissed before presenting
          // UIActivityViewController, and a non-zero sharePositionOrigin.
          if (Platform.isIOS) {
            await WidgetsBinding.instance.endOfFrame;
          }

          final xFile = XFile(filePath, name: fileName);
          await Share.shareXFiles(
            [xFile],
            text: document.title,
            subject: 'sharingDocument'.tr,
            sharePositionOrigin: Platform.isIOS
                ? _resolveShareOrigin(shareOrigin)
                : null,
          );

          DiagnosticLogger.instance.error('✅ Share dialog opened successfully');
        } else {
          throw Exception('File not found after download');
        }
      } else {
        if (Get.isDialogOpen ?? false) Get.back();
        await MessagePopupController.showError(
          messageKey: 'shareError',
          titleKey: 'shareFailed',
        );
        DiagnosticLogger.instance.error('❌ Share failed: ${saveResult['error']}');
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ Error sharing document: $e');
      if (Get.isDialogOpen ?? false) Get.back();
      await MessagePopupController.showError(
        messageKey: 'shareError',
        titleKey: 'shareFailed',
      );
    }
  }

  /// iOS requires a non-zero rect to anchor the share sheet popover.
  Rect _resolveShareOrigin(Rect? shareOrigin) {
    if (shareOrigin != null &&
        shareOrigin.width > 0 &&
        shareOrigin.height > 0) {
      return shareOrigin;
    }

    final context = Get.context;
    if (context != null) {
      final size = MediaQuery.sizeOf(context);
      return Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 2,
        height: 2,
      );
    }

    return const Rect.fromLTWH(0, 0, 1, 1);
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
  /// Returns UploadResult - NO side effects, NO popups, NO UI updates
  /// UI layer must handle popups and dialog closing
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
      // This prevents success messages from being routed to error popup
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
      DiagnosticLogger.instance.warning('⚠️ [DocumentsController] Unknown document type: $documentType');
      return null;
    }

    // Find category ID from categories list
    try {
      final category = categories.firstWhere(
        (cat) =>
            cat.categoryName.toLowerCase().trim() ==
            categoryName.toLowerCase().trim(),
      );

      DiagnosticLogger.instance.info(
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

        DiagnosticLogger.instance.info(
          '✅ [DocumentsController] Mapped "$documentType" to category "${fallbackCategory.categoryName}" (ID: ${fallbackCategory.id}) - fallback match',
        );
        return fallbackCategory.id;
      } catch (e2) {
        // No match found
      }
    }

    DiagnosticLogger.instance.warning(
      '⚠️ [DocumentsController] Could not find category for type: $documentType',
    );
    return null;
  }

  /// Apply a loaded document list and keep total + per-category counts in sync.
  void applyDocuments(List<DocumentModel> loadedDocuments) {
    _applyLoadedDocuments(loadedDocuments);
  }

  /// Clear documents and reset all related counts.
  void clearDocuments() {
    documents.clear();
    totalDocumentCount.value = 0;
    if (categories.isNotEmpty) {
      categories.value =
          categories.map((c) => c.copyWith(count: 0)).toList();
    }
  }

  void _applyLoadedDocuments(List<DocumentModel> loadedDocuments) {
    documents.value = loadedDocuments;
    _syncCountsFromDocuments(loadedDocuments);
  }

  void _syncCountsFromDocuments([List<DocumentModel>? source]) {
    final docs = source ?? documents.toList();
    totalDocumentCount.value = docs.length;
    if (categories.isNotEmpty) {
      _updateCategoryCounts(docs);
    }
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

    DiagnosticLogger.instance.debug('📊 Updated category counts:');
    for (var cat in updatedCategories) {
      DiagnosticLogger.instance.debug('  - ${cat.categoryName}: ${cat.count}');
    }
  }

  // -------------------------------------------------------------------------
  // UPLOAD POPUPS HANDLED IN UI LAYER
  // -------------------------------------------------------------------------
  // Popups are now handled ONLY in UI layer (AddDocumentDialog)
  // Controller returns UploadResult - no side effects

  /// Delete a document
  /// Calls the delete API and removes the document from the list on success
  Future<bool> deleteDocument(DocumentModel document) async {
    try {
      // Parse document ID from String to int (API expects int)
      final documentId = int.tryParse(document.id);
      if (documentId == null) {
        DiagnosticLogger.instance.error('❌ [DocumentsController] Invalid document ID: ${document.id}');
        MessagePopupController.showError(
          messageKey: 'invalidDocumentId',
          titleKey: 'deleteFailed',
        );
        return false;
      }

      DiagnosticLogger.instance.debug(
        '🗑️ [DocumentsController] Deleting document: ${document.title} (ID: $documentId)',
      );

      // Call delete API
      final result = await _repository.deleteDocument(documentId);

      if (result['success'] == true) {
        DiagnosticLogger.instance.info('✅ [DocumentsController] Delete success, removing from UI');

        // Remove document from reactive list immediately
        documents.removeWhere((d) => d.id == document.id);
        _syncCountsFromDocuments();

        MessagePopupController.showSuccess(
          messageKey: 'documentDeletedSuccessfully'.tr.replaceAll(
            '{title}',
            document.title,
          ),
          titleKey: 'documentDeleted',
        );

        return true;
      } else {
        final isAdminDocument = result['isAdminDocument'] == true;

        if (isAdminDocument) {
          MessagePopupController.showWarning(
            messageKey: 'cannotDeleteAdminDocument',
            titleKey: 'deleteNotAllowed',
          );
        } else {
          MessagePopupController.showError(
            messageKey: 'failedToDeleteDocument',
            titleKey: 'deleteFailed',
          );
        }

        DiagnosticLogger.instance.error('❌ [DocumentsController] Delete failed: ${result['error']}');
        return false;
      }
    } catch (e) {
      DiagnosticLogger.instance.error('❌ [DocumentsController] Error deleting document: $e');
      MessagePopupController.showError(
        messageKey: 'errorDeletingDocument',
        titleKey: 'deleteFailed',
      );
      return false;
    }
  }
}
