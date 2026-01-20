import 'package:casazero/presentation/documents/viwes/sections/document_card.dart';
import 'package:casazero/presentation/documents/viwes/sections/document_filter_bar.dart';
import 'package:casazero/presentation/documents/viwes/sections/document_search_bar.dart';
import 'package:casazero/presentation/documents/viwes/sections/empty_state.dart';
import 'package:casazero/presentation/documents/viwes/sections/add_document_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/utils/permissions.dart';
import '../controllers/documents_controller.dart';

class DocumentsScreen extends StatefulWidget {
  final Role role;
  final VoidCallback onAskAI;

  const DocumentsScreen({super.key, required this.role, required this.onAskAI});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String searchQuery = "";
  String activeCategory = "all";
  bool showUploadDialog = false;

  late final DocumentsController _controller;
  
  @override
  void initState() {
    super.initState();
    // Ensure controller is initialized, reuse if exists
    if (!Get.isRegistered<DocumentsController>()) {
      _controller = Get.put(DocumentsController());
    } else {
      _controller = Get.find<DocumentsController>();
    }
    
    // Snackbar listeners removed - snackbars now handled ONLY in AddDocumentDialog
  }

  @override
  Widget build(BuildContext context) {
    final permissions = Permissions.fromRole(widget.role);

    return Stack(
      children: [
        Column(
          children: [
            /// SEARCH BAR
            DocumentSearchBar(
              value: searchQuery,
              onChanged: (value) => setState(() => searchQuery = value),
            ),

            /// FILTER CATEGORIES
            Obx(
              () => DocumentFilterBar(
                activeCategory: activeCategory,
                onCategoryChanged: (c) => setState(() => activeCategory = c),
                apiCategories: _controller.categories,
                isLoading: _controller.isLoadingCategories.value,
                totalDocumentCount: _controller.totalDocumentCount.value,
              ),
            ),

            const SizedBox(height: 12),

            /// DOCUMENTS LIST
            Expanded(
              child: Obx(() {
                // Show error state if there's an error
                if (_controller.hasError.value && 
                    _controller.documents.isEmpty &&
                    !_controller.isLoadingDocuments.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Documents',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _controller.errorMessage.value.isNotEmpty
                                ? _controller.errorMessage.value
                                : 'Failed to load documents. Please try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => _controller.retryFetchDocuments(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF47),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (_controller.isLoadingDocuments.value &&
                    _controller.documents.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CAF47)),
                  );
                }

                final filteredDocs = _controller.documents.where((doc) {
                  final matchesSearch = doc.title.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  );

                  bool matchesCategory = activeCategory == "all";

                  if (activeCategory == "mydocuments") {
                    matchesCategory = doc.category == "My Documents";
                  } else if (activeCategory != "all") {
                    matchesCategory = doc.category.toLowerCase().contains(
                      activeCategory.toLowerCase(),
                    );
                  }

                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return EmptyState(
                    title: searchQuery.isNotEmpty
                        ? "noDocumentsFound".tr
                        : "noDocumentsYet".tr,
                    description: searchQuery.isNotEmpty
                        ? "tryAdjustingSearch".tr
                        : "adminWillUpload".tr,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _controller.refreshData(),
                  color: const Color(0xFF4CAF47),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (_, i) {
                      final doc = filteredDocs[i];
                      return DocumentCard(
                        document: doc,
                        onAskAI: widget.onAskAI,
                        onView: () {
                          print('View document: ${doc.title}');
                        },
                        onDelete: permissions.canDeleteDocuments
                            ? () {
                                _controller.deleteDocument(doc);
                              }
                            : null,
                        onDownload: () {
                          _controller.downloadDocument(doc);
                        },
                        onShare: permissions.canSharedDocuments
                            ? () {
                                _controller.shareDocument(doc);
                              }
                            : null,
                        onChat: permissions.canSharedDocuments
                            ? () {
                                print('Chat about document: ${doc.title}');
                              }
                            : null,
                      ).animate().fadeIn().slideY(begin: 0.1);
                    },
                  ),
                );
              }),
            ),
          ],
        ),

        /// FLOATING ACTION BUTTON
        if (permissions.canUploadDocuments)
          Positioned(
            bottom: 20,
            right: 20,
            child:
                FloatingActionButton(
                    backgroundColor: const Color(0xFF4CAF47),
                    onPressed: () => setState(() => showUploadDialog = true),
                    child: const Icon(Icons.add, size: 26, color: Colors.white),
                  ).animate()
                  ..scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                  ).fadeIn(),
          ),

        /// ADD DOCUMENT DIALOG
        if (showUploadDialog)
          AddDocumentDialog(
            onClose: () => setState(() => showUploadDialog = false),
            onUpload: (documentData) async {
              // The dialog already handles the upload and refresh
              // This callback is optional and can be used for additional handling if needed
              print('✅ Document upload completed: ${documentData['title']}');
            },
          ),
      ],
    );
  }
}
