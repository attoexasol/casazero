import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../data/models/document_model.dart';
import 'document_colors.dart';

/// Callback that runs the download and completes when done (success or error).
/// Used so the card can show a button-level loader and clear it when the future completes.
typedef DownloadCallback = Future<void> Function();

class DocumentCard extends StatefulWidget {
  final DocumentModel document;
  final VoidCallback? onView;
  final DownloadCallback? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final VoidCallback onAskAI;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onAskAI,
    this.onView,
    this.onDownload,
    this.onShare,
    this.onDelete,
  });

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard> {
  bool _isPressed = false;
  bool _isDownloading = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final cardRadius = 24.r;
    final borderWidth = 1.2.w;
    // Inner corner radius must account for the card border so the accent
    // strip follows the same curve as the card edge.
    final innerRadius = cardRadius - borderWidth;
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
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: const Color(0xFFF2F2F2),
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x22000000),
                offset: Offset(0, 4.h),
                blurRadius: 12.r,
              ),
              BoxShadow(
                color: const Color(0x11000000),
                offset: Offset(0, 2.h),
                blurRadius: 8.r,
              ),
              BoxShadow(
                color: typeColor.withOpacity(_isPressed ? 0.28 : 0.0),
                blurRadius: _isPressed ? 30.r : 4.r,
                spreadRadius: _isPressed ? 2.r : 0,
                offset: Offset(0, _isPressed ? 10.h : 4.h),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// LEFT ACCENT BORDER
              Container(
                width: 8.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(innerRadius),
                    bottomLeft: Radius.circular(innerRadius),
                  ),
                ),
              ),

              /// CONTENT SECTION
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// FILE TYPE ICON BOX
                      Builder(
                        builder: (context) {
                          final fileTypeData = _getFileTypeIcon();
                          final fileIcon = fileTypeData['icon'] as IconData;
                          final fileColor = fileTypeData['color'] as Color;

                          return Container(
                            width: 48.w,
                            height: 48.w,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Icon(
                              fileIcon,
                              size: 24.sp,
                              color: fileColor,
                            ),
                          );
                        },
                      ),

                      SizedBox(width: 12.w),

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
                                fontSize: 15.sp,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(height: 4.h),

                            /// DATE & SIZE (date switches EN/IT with locale)
                            Obx(() {
                              try {
                                final localeController =
                                    Get.find<LocaleController>();
                                final _ = localeController.locale;
                              } catch (_) {}

                              final localizedDate =
                                  widget.document.getLocalizedDate();
                              return Text(
                                "$localizedDate • ${widget.document.size}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }),

                            SizedBox(height: 6.h),

                            /// TAGS (category / type names switch with EN/IT)
                            Obx(() {
                              try {
                                final localeController =
                                    Get.find<LocaleController>();
                                // Access locale so tags rebuild on language change
                                final _ = localeController.locale;
                              } catch (_) {}

                              final displayTags =
                                  widget.document.getLocalizedTags();
                              return Wrap(
                                spacing: 6.w,
                                runSpacing: 4.h,
                                children: displayTags.map((tag) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 3.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey.shade700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                              );
                            }),

                            SizedBox(height: 10.h),

                            /// ACTION BUTTONS
                            Listener(
                              onPointerDown: (event) {},
                              child: Row(
                                children: [
                                  if (widget.onDownload != null)
                                    _downloadActionBtn(),

                                  if (widget.onShare != null)
                                    Padding(
                                      padding: EdgeInsets.only(left: 15.w),
                                      child: _actionIconBtn(
                                        Icons.share_outlined,
                                        widget.onShare!,
                                      ),
                                    ),

                                  const Spacer(),

                                  if (widget.onDelete != null)
                                    Padding(
                                      padding: EdgeInsets.only(left: 15.w),
                                      child: _actionIconBtn(
                                        Icons.delete_outline,
                                        widget.onDelete!,
                                        color: const Color(0xFFDC2626),
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

  /// Download action button: shows icon normally, shows in-button loader while downloading.
  Widget _downloadActionBtn() {
    final size = 20.w;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: _isDownloading
            ? null
            : () async {
                print('🔘 [DocumentCard] Download button tapped');
                setState(() => _isDownloading = true);
                try {
                  await widget.onDownload!();
                } finally {
                  if (mounted) setState(() => _isDownloading = false);
                }
              },
        onTapDown: (_) {
          if (!_isDownloading) {
            print('🔘 [DocumentCard] Action button tap down: download');
          }
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size,
          height: size,
          child: _isDownloading
              ? SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey.shade700,
                    ),
                  ),
                )
              : SvgPicture.asset(
                  "assets/images/download.svg",
                  width: size,
                  height: size,
                ),
        ),
      ),
    );
  }

  /// Action Button with Material Icon (for Share / Delete buttons)
  Widget _actionIconBtn(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Listener(
        onPointerDown: (_) {},
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Icon(
            icon,
            size: 20.sp,
            color: color ?? Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  String _documentTypeKey(DocumentModel document) {
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
  Map<String, dynamic> _getFileTypeIcon() {
    String? extension;
    if (widget.document.fileUrl != null &&
        widget.document.fileUrl!.isNotEmpty) {
      final url = widget.document.fileUrl!;
      final lastDot = url.lastIndexOf('.');
      if (lastDot != -1 && lastDot < url.length - 1) {
        extension = url.substring(lastDot + 1).toLowerCase();
      }
    }

    if (extension == null || extension.isEmpty) {
      final type = widget.document.type.toLowerCase();
      if (type.contains('.')) {
        extension = type.substring(type.lastIndexOf('.') + 1);
      } else {
        extension = type;
      }
    }

    switch (extension) {
      case 'pdf':
        return {
          'icon': Icons.picture_as_pdf_outlined,
          'color': const Color(0xFFDC2626),
        };
      case 'doc':
      case 'docx':
        return {
          'icon': Icons.description_outlined,
          'color': const Color(0xFF2563EB),
        };
      case 'xls':
      case 'xlsx':
        return {
          'icon': Icons.table_chart_outlined,
          'color': const Color(0xFF16A34A),
        };
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
      case 'bmp':
      case 'svg':
        return {
          'icon': Icons.image_outlined,
          'color': const Color(0xFF4CAF47),
        };
      case 'txt':
        return {
          'icon': Icons.text_snippet_outlined,
          'color': Colors.grey.shade700,
        };
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return {
          'icon': Icons.folder_zip_outlined,
          'color': Colors.grey.shade700,
        };
      default:
        return {
          'icon': Icons.insert_drive_file_outlined,
          'color': Colors.grey.shade700,
        };
    }
  }
}
