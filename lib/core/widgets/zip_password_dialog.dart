// core/widgets/zip_password_dialog.dart
//
// Simple dialog to ask the user for the ZIP password.
// Returns the entered password on OK, null on Cancel.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'responsive_alert_dialog.dart';

/// Shows the password dialog FIRST after download. User enters ZIP password
/// (or leaves empty for unencrypted ZIP). Returns password on OK, null on Cancel.
/// Empty string = no password (extraction will be tried without password).
Future<String?> showZipPasswordDialog(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ResponsiveAlertDialog(
      scrollable: true,
      title: const Text(
        'ZIP password',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter the ZIP password. Leave empty if the file is not protected.',
            style: TextStyle(fontSize: 14.sp),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter password or leave empty',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(
            'Cancel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(
            'OK',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
  final raw = result == true ? controller.text : null;
  controller.dispose();
  if (result != true) return null;
  return raw?.trim() ?? '';
}
