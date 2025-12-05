import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../data/models/document_model.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = size.width / 390;

    return IntrinsicHeight(
      // 🔥 FIX: prevents height crash in ListView
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
            /// --------------------------------------------------
            /// ⭐ LEFT GREEN BORDER (NO INFINITY → NO CRASH)
            /// --------------------------------------------------
            Container(
              width: 6 * scale,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF47), Color(0x804CAF47)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24 * scale),
                  bottomLeft: Radius.circular(24 * scale),
                ),
              ),
            ),

            /// --------------------------------------------------
            /// CONTENT SECTION
            /// --------------------------------------------------
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
                      child: Text(
                        document.type,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13 * scale,
                        ),
                      ),
                    ),

                    SizedBox(width: 12 * scale),

                    /// --------------------------------------------------
                    /// TEXT SECTION
                    /// --------------------------------------------------
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

                          /// --------------------------------------------------
                          /// ACTION BUTTONS + ASK AI
                          /// --------------------------------------------------
                          Row(
                            children: [
                              if (onDownload != null)
                                _actionBtn(
                                  "assets/images/download.svg",
                                  onDownload!,
                                  scale,
                                ),
                              SizedBox(width: 15),
                              if (onShare != null)
                                _actionBtn(
                                  "assets/images/chat.svg",
                                  onShare!,
                                  scale,
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
}
