import 'package:casazero/presentation/documents/viwes/sections/document_card.dart';
import 'package:casazero/presentation/documents/viwes/sections/document_filter_bar.dart';
import 'package:casazero/presentation/documents/viwes/sections/document_search_bar.dart';
import 'package:casazero/presentation/documents/viwes/sections/empty_state.dart';
import 'package:casazero/presentation/documents/viwes/sections/add_document_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/utils/permissions.dart';
import '../../../data/models/document_model.dart';
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

  final DocumentsController _controller = Get.put(DocumentsController());

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
                                print('Delete document: ${doc.title}');
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
