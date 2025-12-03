import 'package:get/get.dart';
import '../../../data/models/document_category_model.dart';
import '../../../data/repositories/document_repository.dart';

class DocumentsController extends GetxController {
  final DocumentRepository _repository = DocumentRepository();

  // Reactive variables
  final RxList<DocumentCategoryModel> categories =
      <DocumentCategoryModel>[].obs;
  final RxBool isLoadingCategories = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDocumentCategories();
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

  /// Retry fetching categories (useful for error handling)
  void retryFetchCategories() {
    fetchDocumentCategories();
  }
}
