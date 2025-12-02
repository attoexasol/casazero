import 'package:casazero/presentation/documents/viwes/sections/document_card.dart';
import 'package:casazero/presentation/documents/viwes/sections/document_filter_bar.dart';
import 'package:casazero/presentation/documents/viwes/sections/document_search_bar.dart';
import 'package:casazero/presentation/documents/viwes/sections/empty_state.dart';
import 'package:casazero/presentation/documents/viwes/sections/upload_document_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/utils/permissions.dart';
import '../../../data/models/document_model.dart';

class DocumentsScreen extends StatefulWidget {
  final Role role;
  final VoidCallback onAskAI;

  const DocumentsScreen({
    super.key,
    required this.role,
    required this.onAskAI,
  });

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String searchQuery = "";
  String activeCategory = "all";

  bool showUploadDialog = false;

  // Mock documents (will place in separate file later)
  final mockDocuments = DocumentModel.mockDocuments;

  @override
  Widget build(BuildContext context) {
    final permissions = Permissions.fromRole(widget.role);

    final filteredDocs = mockDocuments.where((doc) {
      final matchesSearch =
      doc.title.toLowerCase().contains(searchQuery.toLowerCase());

      bool matchesCategory = activeCategory == "all";

      if (activeCategory == "mydocuments") {
        matchesCategory = doc.category == "My Documents";
      } else if (activeCategory != "all") {
        matchesCategory =
            doc.category.toLowerCase().contains(activeCategory.toLowerCase());
      }

      return matchesSearch && matchesCategory;
    }).toList();

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
            DocumentFilterBar(
              activeCategory: activeCategory,
              onCategoryChanged: (c) => setState(() => activeCategory = c),
            ),

            const SizedBox(height: 12),

            /// DOCUMENTS LIST
            Expanded(
              child: filteredDocs.isNotEmpty
                  ? ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredDocs.length,
                itemBuilder: (_, i) {
                  final doc = filteredDocs[i];
                  return DocumentCard(
                    document: doc,
                    onAskAI: widget.onAskAI,
                    onView: () {},
                    onDelete: permissions.canDeleteDocuments ? () {} : null,
                    onDownload: () {},
                    onShare: permissions.canSharedDocuments ? () {} : null,
                  ).animate().fadeIn().slideY(begin: 0.1);
                },
              )
                  : EmptyState(
                title: searchQuery.isNotEmpty
                    ? "noDocumentsFound".tr
                    : "noDocumentsYet".tr,
                description: searchQuery.isNotEmpty
                    ? "tryAdjustingSearch".tr
                    : "adminWillUpload".tr,
              ),
            ),
          ],
        ),

        /// FLOATING ACTION BUTTON
        if (permissions.canUploadDocuments)
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF4CAF47),
              onPressed: () => setState(() => showUploadDialog = true),
              child: const Icon(Icons.add, size: 26, color: Colors.white),
            ).animate()..scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
            ).fadeIn(),
          ),

        /// UPLOAD DOCUMENT DIALOG
        if (showUploadDialog)
          UploadDocumentDialog(
            onClose: () => setState(() => showUploadDialog = false),
          ),
      ],
    );
  }
}
