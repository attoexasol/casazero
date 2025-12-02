import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadDocumentDialog extends StatefulWidget {
  final VoidCallback onClose;

  const UploadDocumentDialog({super.key, required this.onClose});

  @override
  State<UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<UploadDocumentDialog> {
  String title = "";
  String type = "";
  String description = "";
  // File? file (You will add file picker later)

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 350),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("addDocument".tr,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              TextField(
                decoration:
                InputDecoration(labelText: "title".tr),
                onChanged: (v) => setState(() => title = v),
              ),
              const SizedBox(height: 12),

              TextField(
                decoration:
                InputDecoration(labelText: "description".tr),
                onChanged: (v) => setState(() => description = v),
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onClose,
                    child: Text("cancel".tr),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Upload logic
                      widget.onClose();
                    },
                    child: Text("upload".tr),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
