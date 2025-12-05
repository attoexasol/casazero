import 'package:get/get.dart';
import '../../../data/models/document_category_model.dart';
import '../../../data/models/document_model.dart';
import '../../../data/repositories/document_repository.dart';
import '../../home/controllers/home_controller.dart';

class DocumentsController extends GetxController {
  final DocumentRepository _repository = DocumentRepository();

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
    //fetchDocuments();
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

      //final residenceId = homeController.selectedResidence.value?.id ?? 23;

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
