import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../data/models/document_model.dart';
import 'document_colors.dart';

class DocumentCard extends StatefulWidget {
  final DocumentModel document;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onChat;
  final VoidCallback? onDelete;
  final VoidCallback onAskAI;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onAskAI,
    this.onView,
    this.onDownload,
    this.onShare,
    this.onChat,
    this.onDelete,
  });

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = size.width / 390;
    final accentColor = documentCategoryColor(widget.document.category);
    final typeKey = _documentTypeKey(widget.document);
    final typeColor = documentTypeColor(typeKey);

    return IntrinsicHeight(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) {
          _setPressed(false);
          widget.onView?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(bottom: 12 * scale),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24 * scale),
            border: Border.all(
              color: const Color(0xFFF2F2F2),
              width: 1.2 * scale,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x22000000),
                offset: Offset(0, 4 * scale),
                blurRadius: 12 * scale,
              ),
              BoxShadow(
                color: const Color(0x11000000),
                offset: Offset(0, 2 * scale),
                blurRadius: 8 * scale,
              ),
              BoxShadow(
                color: typeColor.withOpacity(_isPressed ? 0.28 : 0.0),
                blurRadius: _isPressed ? 30 * scale : 4 * scale,
                spreadRadius: _isPressed ? 2 * scale : 0,
                offset: Offset(0, _isPressed ? 10 * scale : 4 * scale),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// LEFT ACCENT BORDER
              Container(
                //height: double.,
                width: 8 * scale,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24 * scale),
                    bottomLeft: Radius.circular(24 * scale),
                  ),
                ),
              ),

              /// CONTENT SECTION
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14 * scale),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// FILE TYPE ICON BOX
                      // Icon box background uses category color to match sidebar
                      // Icon itself uses file type color for visual clarity
                      Builder(
                        builder: (context) {
                          final fileTypeData = _getFileTypeIcon();
                          final fileIcon = fileTypeData['icon'] as IconData;
                          final fileColor = fileTypeData['color'] as Color;

                          return Container(
                            width: 48 * scale,
                            height: 48 * scale,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(
                                0.15,
                              ), // Background matches category color (sidebar)
                              borderRadius: BorderRadius.circular(14 * scale),
                            ),
                            child: Icon(
                              fileIcon,
                              size: 24 * scale,
                              color: fileColor, // Icon color remains file type color
                            ),
                          );
                        },
                      ),

                      SizedBox(width: 12 * scale),

                      /// TEXT SECTION
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// TITLE
                            Text(
                              widget.document.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15 * scale,
                                color: Colors.black,
                              ),
                            ),

                            SizedBox(height: 4 * scale),

                            /// DATE & SIZE
                            Text(
                              "${widget.document.date} • ${widget.document.size}",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13 * scale,
                              ),
                            ),

                            SizedBox(height: 6 * scale),

                            /// TAGS
                            Wrap(
                              spacing: 6 * scale,
                              runSpacing: -4,
                              children: widget.document.tags.map((tag) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8 * scale,
                                    vertical: 3 * scale,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(
                                      20 * scale,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 11 * scale,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            SizedBox(height: 10 * scale),

                            /// ACTION BUTTONS
                            Listener(
                              // Stop pointer events from propagating to parent GestureDetector
                              onPointerDown: (event) {
                                // Consume the pointer event to prevent parent from receiving it
                              },
                              child: Row(
                                children: [
                                  // Download Button
                                  if (widget.onDownload != null)
                                    _actionBtn(
                                      "assets/images/download.svg",
                                      widget.onDownload!,
                                      scale,
                                    ),

                                  // Share Button
                                  if (widget.onShare != null)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: 15 * scale,
                                      ),
                                      child: _actionIconBtn(
                                        Icons.share_outlined,
                                        widget.onShare!,
                                        scale,
                                      ),
                                    ),

                                  // Chat Button
                                  if (widget.onChat != null)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: 15 * scale,
                                      ),
                                      child: _actionBtn(
                                        "assets/images/chat.svg",
                                        widget.onChat!,
                                        scale,
                                      ),
                                    ),

                                  const Spacer(),

                                  // Delete Button
                                  // Positioned at bottom-right, after Spacer to align right
                                  // Consistent visibility: shows for all cards when onDelete callback is provided
                                  if (widget.onDelete != null)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: 15 * scale,
                                      ),
                                      child: _actionBtn(
                                        "assets/images/delete.svg",
                                        widget.onDelete!,
                                        scale,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Action Button with SVG
  Widget _actionBtn(String asset, VoidCallback onTap, double scale) {
    return Padding(
      padding: EdgeInsets.only(right: 8 * scale),
      child: GestureDetector(
        onTap: () {
          print('🔘 [DocumentCard] Action button tapped: $asset');
          onTap();
        },
        onTapDown: (_) {
          // Consume the tap event to prevent parent GestureDetector from handling it
          print('🔘 [DocumentCard] Action button tap down: $asset');
        },
        behavior: HitTestBehavior.opaque,
        child: SvgPicture.asset(asset, width: 20 * scale, height: 20 * scale),
      ),
    );
  }

  /// Action Button with Material Icon (for Share button)
  Widget _actionIconBtn(IconData icon, VoidCallback onTap, double scale) {
    return Padding(
      padding: EdgeInsets.only(right: 8 * scale),
      child: Listener(
        onPointerDown: (_) {
          // Stop event propagation to prevent parent GestureDetector from handling the tap
        },
        child: GestureDetector(
          onTap: () {
            onTap();
          },
          behavior: HitTestBehavior.opaque,
          child: Icon(icon, size: 20 * scale, color: Colors.grey.shade700),
        ),
      ),
    );
  }

  String _documentTypeKey(DocumentModel document) {
    // Prefer tags/type hints if available, fallback to category keywords
    final lowerTags = document.tags.map((t) => t.toLowerCase()).toList();
    if (lowerTags.any((t) => t.contains('compliance'))) return 'compliance';
    if (lowerTags.any((t) => t.contains('owner') || t.contains('ownership'))) {
      return 'owner';
    }
    if (lowerTags.any((t) => t.contains('technical'))) return 'technical';

    final cat = document.category.toLowerCase();
    if (cat.contains('compliance')) return 'compliance';
    if (cat.contains('owner')) return 'owner';
    if (cat.contains('technical')) return 'technical';

    return 'owner';
  }

  /// Get file type icon based on file extension or mime type
  /// Returns IconData and Color for the file type
  /// Handles uppercase/lowercase extensions, missing extensions, and null safety
  Map<String, dynamic> _getFileTypeIcon() {
    // Try to get file extension from fileUrl first
    String? extension;
    if (widget.document.fileUrl != null &&
        widget.document.fileUrl!.isNotEmpty) {
      final url = widget.document.fileUrl!;
      final lastDot = url.lastIndexOf('.');
      if (lastDot != -1 && lastDot < url.length - 1) {
        extension = url.substring(lastDot + 1).toLowerCase();
      }
    }

    // Fallback to type field if no extension found in fileUrl
    if (extension == null || extension.isEmpty) {
      final type = widget.document.type.toLowerCase();
      // Remove common prefixes and extract extension
      if (type.contains('.')) {
        extension = type.substring(type.lastIndexOf('.') + 1);
      } else {
        // Type might be just the extension (e.g., "PDF", "JPG")
        extension = type;
      }
    }

    // Map file extension to icon and color
    switch (extension) {
      // PDF files → PDF icon (red tone)
      case 'pdf':
        return {
          'icon': Icons.picture_as_pdf_outlined,
          'color': const Color(0xFFDC2626), // Red tone
        };

      // Word documents → Word document icon (blue tone)
      case 'doc':
      case 'docx':
        return {
          'icon': Icons.description_outlined,
          'color': const Color(0xFF2563EB), // Blue tone
        };

      // Excel files → Spreadsheet icon (green tone)
      case 'xls':
      case 'xlsx':
        return {
          'icon': Icons.table_chart_outlined,
          'color': const Color(0xFF16A34A), // Green tone
        };

      // Image files → Image icon (accent color)
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
      case 'bmp':
      case 'svg':
        return {
          'icon': Icons.image_outlined,
          'color': const Color(0xFF4CAF47), // Accent color (brand sage)
        };

      // Text files → Text file icon
      case 'txt':
        return {
          'icon': Icons.text_snippet_outlined,
          'color': Colors.grey.shade700, // Neutral color
        };

      // Archive files → Archive icon
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return {
          'icon': Icons.folder_zip_outlined,
          'color': Colors.grey.shade700, // Neutral color
        };

      // Default/Unknown → Generic file icon (neutral color)
      default:
        return {
          'icon': Icons.insert_drive_file_outlined,
          'color': Colors.grey.shade700, // Neutral color
        };
    }
  }

}
