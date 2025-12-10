import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../data/models/document_model.dart';
import 'document_colors.dart';

class DocumentCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = size.width / 390;
    final accentColor = documentCategoryColor(document.category);
    final iconAsset = _iconForType(document.type);

    return IntrinsicHeight(
      child: Container(
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
          ],
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// LEFT GREEN BORDER
            Container(
              width: 6 * scale,
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
                    Container(
                      width: 48 * scale,
                      height: 48 * scale,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14 * scale),
                      ),
                      child: iconAsset != null
                          ? SvgPicture.asset(
                              iconAsset,
                              width: 24 * scale,
                              height: 24 * scale,
                            )
                          : Text(
                              document.type,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13 * scale,
                              ),
                            ),
                    ),

                    SizedBox(width: 12 * scale),

                    /// TEXT SECTION
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// TITLE
                          Text(
                            document.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15 * scale,
                              color: Colors.black,
                            ),
                          ),

                          SizedBox(height: 4 * scale),

                          /// DATE & SIZE
                          Text(
                            "${document.date} • ${document.size}",
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
                            children: document.tags.map((tag) {
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
                          Row(
                            children: [
                              // Download Button
                              if (onDownload != null)
                                _actionBtn(
                                  "assets/images/download.svg",
                                  onDownload!,
                                  scale,
                                ),

                              // Share Button
                              if (onShare != null)
                                Padding(
                                  padding: EdgeInsets.only(left: 15 * scale),
                                  child: _actionIconBtn(
                                    Icons.share_outlined,
                                    onShare!,
                                    scale,
                                  ),
                                ),

                              // Chat Button
                              if (onChat != null)
                                Padding(
                                  padding: EdgeInsets.only(left: 15 * scale),
                                  child: _actionBtn(
                                    "assets/images/chat.svg",
                                    onChat!,
                                    scale,
                                  ),
                                ),

                              const Spacer(),
                            ],
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
    );
  }

  /// Action Button with SVG
  Widget _actionBtn(String asset, VoidCallback onTap, double scale) {
    return Padding(
      padding: EdgeInsets.only(right: 8 * scale),
      child: GestureDetector(
        onTap: onTap,
        child: SvgPicture.asset(asset, width: 20 * scale, height: 20 * scale),
      ),
    );
  }

  /// Action Button with Material Icon (for Share button)
  Widget _actionIconBtn(IconData icon, VoidCallback onTap, double scale) {
    return Padding(
      padding: EdgeInsets.only(right: 8 * scale),
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, size: 20 * scale, color: Colors.grey.shade700),
      ),
    );
  }

  String? _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'compliance':
        return 'assets/images/complience_doc_icon.svg';
      case 'owner':
        return 'assets/images/owner_doc_icon.svg';
      case 'technical':
        return 'assets/images/technical_doc_icon.svg';
      default:
        return null;
    }
  }
}
