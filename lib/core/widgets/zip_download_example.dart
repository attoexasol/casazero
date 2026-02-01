// core/widgets/zip_download_example.dart
//
// Minimal UI: download ZIP → extract (ask for password if protected) → open first file with native "open with".

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/zip_download_service.dart';
import '../controllers/message_popup_controller.dart';
import 'zip_password_dialog.dart';

/// Example widget: "Download ZIP" button + optional progress.
/// After download, the ZIP is extracted; if password-protected, a dialog asks
/// for the password. After successful extraction, the first file is opened
/// with native "open with".
class ZipDownloadExample extends StatefulWidget {
  /// Full URL of the AES-encrypted ZIP (e.g. from your backend).
  final String zipUrl;
  /// Optional label for the button.
  final String buttonLabel;
  /// Optional: show a linear progress indicator while downloading.
  final bool showProgress;

  const ZipDownloadExample({
    super.key,
    required this.zipUrl,
    this.buttonLabel = 'Download ZIP',
    this.showProgress = true,
  });

  @override
  State<ZipDownloadExample> createState() => _ZipDownloadExampleState();
}

class _ZipDownloadExampleState extends State<ZipDownloadExample> {
  bool _loading = false;
  double _progress = 0.0;

  Future<void> _onDownloadZip() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _progress = 0.0;
    });

    try {
      final service = Get.find<ZipDownloadService>();
      final result = await service.downloadAndOpenZip(
        zipUrl: widget.zipUrl,
        fileId: 'example_zip',
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
        onPasswordRequired: () => showZipPasswordDialog(context),
      );

      if (mounted) setState(() => _loading = false);

      if (result['success'] == true) {
        // ZIP downloaded, extracted, and first file opened with native "open with".
      } else {
        MessagePopupController.showError(
          messageKey: 'download_or_extraction_failed',
          titleKey: 'error',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      MessagePopupController.showError(
        messageKey: 'download_failed',
        titleKey: 'error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showProgress && _loading)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: LinearProgressIndicator(value: _progress > 0 ? _progress : null),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _loading ? null : _onDownloadZip,
          icon: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          label: Text(_loading ? 'Downloading…' : widget.buttonLabel),
        ),
      ],
    );
  }
}
