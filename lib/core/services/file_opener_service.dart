import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

/// Service to force native "Open With" chooser for all file types
/// This ensures images don't auto-open and always show the app chooser
class FileOpenerService {
  static const MethodChannel _channel = MethodChannel('com.example.casazero/file_opener');

  /// Open file with forced native chooser
  /// This will ALWAYS show the app chooser, even for images
  /// Uses platform channel on Android/iOS, falls back to OpenFilex if not available
  static Future<OpenResult> openWithChooser(String filePath) async {
    try {
      // Try platform channel first (if native code is implemented)
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
            'openWithChooser',
            {'filePath': filePath},
          );
          
          if (result != null) {
            final type = result['type'] as String?;
            final message = result['message'] as String? ?? '';
            
            // Map platform channel result to OpenFilex ResultType
            ResultType resultType;
            switch (type) {
              case 'done':
                resultType = ResultType.done;
                break;
              case 'noAppToOpen':
                resultType = ResultType.noAppToOpen;
                break;
              case 'fileNotFound':
                resultType = ResultType.fileNotFound;
                break;
              case 'permissionDenied':
                resultType = ResultType.permissionDenied;
                break;
              default:
                resultType = ResultType.error;
            }
            
            return OpenResult(
              type: resultType,
              message: message,
            );
          }
        } catch (e) {
          // Platform channel not implemented, fallback to OpenFilex
          print('⚠️ Platform channel not available, using OpenFilex: $e');
        }
      }

      // Fallback: Use OpenFilex
      // Note: This may still auto-open images if default app is set
      // For a guaranteed chooser, implement the platform channel native code
      return await OpenFilex.open(filePath);
    } catch (e) {
      print('❌ Error opening file with chooser: $e');
      return OpenResult(
        type: ResultType.error,
        message: e.toString(),
      );
    }
  }
}
