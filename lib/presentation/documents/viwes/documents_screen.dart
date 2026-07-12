import 'package:casazero/presentation/documents/viwes/sections/document_card.dart';
import 'package:casazero/presentation/documents/viwes/sections/document_filter_bar.dart';
import 'package:casazero/presentation/documents/viwes/sections/document_search_bar.dart';
import 'package:casazero/presentation/documents/viwes/sections/empty_state.dart';
import 'package:casazero/presentation/documents/viwes/sections/add_document_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/controllers/message_popup_controller.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/widgets/floating_bottom_nav_bar.dart';
import '../../../core/widgets/tablet_centered_layout.dart';
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

    // Popup messages are handled ONLY in AddDocumentDialog
  }

  void _openAddDocumentDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AddDocumentDialog(
        onClose: () => Navigator.of(dialogContext).pop(),
        onUpload: (documentData) async {
          print('✅ Document upload completed: ${documentData['title']}');
        },
      ),
    );
  }

  int? _currentUserId() {
    final rawId = Get.find<StorageService>().getUserData()?['id'];
    if (rawId is int) return rawId;
    return int.tryParse(rawId?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final permissions = Permissions.fromRole(widget.role);
    final currentUserId = _currentUserId();
    final navScrollPadding = FloatingBottomNavBar.contentBottomPadding(context);
    const fabMargin = 20.0;

    return Stack(
      clipBehavior: Clip.none,
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
                isLoading: _controller.isLoadingCategories.value ||
                    (_controller.isLoadingDocuments.value &&
                        _controller.documents.isEmpty),
                totalDocumentCount: _controller.documents.length,
              ),
            ),

            const SizedBox(height: 12),

            /// DOCUMENTS LIST
            Expanded(
              child: TabletCenteredLayout(
                child: Obx(() {
                // Show error state if there's an error
                if (_controller.hasError.value &&
                    _controller.documents.isEmpty &&
                    !_controller.isLoadingDocuments.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64.sp,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Error Loading Documents',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.w),
                          child: Text(
                            _controller.errorMessage.value.isNotEmpty
                                ? _controller.errorMessage.value
                                : 'Failed to load documents. Please try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14.sp,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 24.h),
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

                return Padding(
                  padding: EdgeInsets.zero,
                  child: RefreshIndicator(
                    onRefresh: () => _controller.refreshData(),
                    color: const Color(0xFF4CAF47),
                    child: ListView.builder(
                      padding: FloatingBottomNavBar.screenPadding(context),
                      itemCount: filteredDocs.length,
                      itemBuilder: (_, i) {
                        final doc = filteredDocs[i];
                        return DocumentCard(
                          document: doc,
                          onAskAI: widget.onAskAI,
                          onView: () {
                            print('View document: ${doc.title}');
                          },
                          onDelete: permissions.canDeleteDocuments &&
                                  doc.isDeletableByUser(currentUserId)
                              ? () async {
                                  // Show localized confirmation (en/it from language settings)
                                  final confirmed =
                                      await MessagePopupController.showConfirmation(
                                        titleKey: 'delete_document',
                                        messageKey:
                                            'delete_document_confirmation',
                                        primaryButtonKey: 'delete',
                                        secondaryButtonKey: 'cancel',
                                      );

                                  if (confirmed == true) {
                                    await _controller.deleteDocument(doc);
                                  }
                                }
                              : null,
                          onDownload: () => _controller.downloadDocument(
                            doc,
                            showDownloadingPopup: false,
                            skipOpenCancelConfirmation: true,
                          ),
                          onShare: permissions.canSharedDocuments
                              ? (shareOrigin) {
                                  _controller.shareDocument(
                                    doc,
                                    shareOrigin: shareOrigin,
                                  );
                                }
                              : null,
                        ).animate().fadeIn().slideY(begin: 0.1);
                      },
                    ),
                  ),
                );
              }),
              ),
            ),
          ],
        ),

        /// FLOATING ACTION BUTTON — keyboard offset isolated to this widget
        if (permissions.canUploadDocuments)
          _KeyboardAwareFabPosition(
            navScrollPadding: navScrollPadding,
            fabMargin: fabMargin,
            right: 20.w,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF4CAF47),
              onPressed: _openAddDocumentDialog,
              child: const Icon(Icons.add, size: 26, color: Colors.white),
            ).animate()
              ..scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
              )
              .fadeIn(),
          ),

      ],
    );
  }
}

class _KeyboardAwareFabPosition extends StatelessWidget {
  const _KeyboardAwareFabPosition({
    required this.navScrollPadding,
    required this.fabMargin,
    required this.right,
    required this.child,
  });

  final double navScrollPadding;
  final double fabMargin;
  final double right;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final keyboardInset = route != null && !route.isCurrent
        ? 0.0
        : MediaQuery.viewInsetsOf(context).bottom;
    final bottom = navScrollPadding + fabMargin - keyboardInset;

    return Positioned(
      bottom: bottom,
      right: right,
      child: child,
    );
  }
}
