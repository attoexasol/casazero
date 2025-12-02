import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ICON
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              document.type,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),

          const SizedBox(width: 12),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${document.date} • ${document.size}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 6),

                /// TAGS
                Wrap(
                  spacing: 6,
                  runSpacing: -4,
                  children: document.tags
                      .map(
                        (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ),
                  )
                      .toList(),
                ),

                const SizedBox(height: 8),

                /// ACTION BUTTONS
                Row(
                  children: [
                    if (onView != null)
                      _actionBtn(Icons.visibility_outlined, onView!),
                    if (onDownload != null)
                      _actionBtn(Icons.download_outlined, onDownload!),
                    if (onShare != null)
                      _actionBtn(Icons.share_outlined, onShare!),
                    if (onDelete != null)
                      _actionBtn(Icons.delete_outline, onDelete!),

                    const Spacer(),

                    /// ASK AI
                    GestureDetector(
                      onTap: onAskAI,
                      child: const Icon(Icons.auto_awesome,
                          color: Color(0xFF4CAF47)),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, size: 20, color: Colors.grey.shade700),
      ),
    );
  }
}
