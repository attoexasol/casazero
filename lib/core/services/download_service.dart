import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';
import 'package:casazero/core/logging/diagnostic_logger.dart';

class DownloadService extends getx.GetxService {
  final Dio _dio = Dio();
  final StorageService _storageService = getx.Get.find();
  static const MethodChannel _platformChannel = MethodChannel('com.example.casazero/file_opener');

  // Track download progress for multiple files
  final getx.RxMap<String, double> downloadProgress = <String, double>{}.obs;
  final getx.RxMap<String, bool> isDownloading = <String, bool>{}.obs;

  DownloadService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add access token to headers if available
          final token = _storageService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          DiagnosticLogger.instance.debug('🌐 [DOWNLOAD REQUEST] ${options.method} ${options.uri}');
          DiagnosticLogger.instance.debug('🔑 [DOWNLOAD TOKEN] ${token ?? 'NO_TOKEN_FOUND'}');
          return handler.next(options);
        },
      ),
    );
  }

  /// Download a document with progress tracking
  /// [fileUrl] - URL of the file to download
  /// [fileName] - Name to save the file as
  /// [fileId] - Unique identifier for tracking this download
  Future<Map<String, dynamic>> downloadDocument({
    required String fileUrl,
    required String fileName,
    required String fileId,
  }) async {
    try {
      // Check and request permissions first
      final hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        return {
          'success': false,
          'error': 'Storage permission denied. Please enable it in settings.',
        };
      }

      // Mark as downloading
      isDownloading[fileId] = true;
      downloadProgress[fileId] = 0.0;

      // Get the appropriate directory
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        isDownloading[fileId] = false;
        return {
          'success': false,
          'error': 'Could not access download directory',
        };
      }

      // Create the full file path
      final filePath = '${directory.path}/$fileName';

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        // File already exists, ask user or use a different name
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nameParts = fileName.split('.');
        final extension = nameParts.length > 1 ? nameParts.last : '';
        final nameWithoutExt = nameParts.length > 1
            ? nameParts.sublist(0, nameParts.length - 1).join('.')
            : fileName;
        fileName = '${nameWithoutExt}_$timestamp${extension.isNotEmpty ? '.$extension' : ''}';
      }

      final finalPath = '${directory.path}/$fileName';

      DiagnosticLogger.instance.debug('📥 Downloading to: $finalPath');
      DiagnosticLogger.instance.debug('📥 From URL: $fileUrl');

      // Prepare the full URL
      String fullUrl = fileUrl;
      if (!fileUrl.startsWith('http://') && !fileUrl.startsWith('https://')) {
        // If URL is relative, prepend the base URL
        fullUrl = ApiConstants.buildOriginUrl(fileUrl);
      }

      DiagnosticLogger.instance.debug('📥 Full URL: $fullUrl');

      // Download the file with progress tracking
      await _dio.download(
        fullUrl,
        finalPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total);
            downloadProgress[fileId] = progress;
            DiagnosticLogger.instance.debug('📥 Download progress: ${(progress * 100).toStringAsFixed(0)}%');
          }
        },
      );

      // Download complete
      isDownloading[fileId] = false;
      downloadProgress.remove(fileId);

      DiagnosticLogger.instance.error('✅ Download completed: $finalPath');

      return {
        'success': true,
        'filePath': finalPath,
        'fileName': fileName,
      };
    } catch (e) {
      DiagnosticLogger.instance.error('❌ Download error: $e');
      isDownloading[fileId] = false;
      downloadProgress.remove(fileId);

      String errorMessage = 'Failed to download document';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Download timeout. Please check your connection.';
        } else if (e.type == DioExceptionType.badResponse) {
          errorMessage = 'Server error. Please try again later.';
        } else {
          errorMessage = 'Network error. Please check your connection.';
        }
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  /// Check and request storage permissions
  /// For Android 11+ (API 30+), we may need additional permissions for public Downloads
  Future<bool> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 10 and below, request storage permission
      if (await Permission.storage.isGranted) {
        return true;
      }

      // Request storage permission
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }

      // For Android 11+ (API 30+), storage permission might not be enough
      // But we can still use app's external storage directory
      // Try requesting photos permission as fallback for Android 13+
      if (status.isDenied) {
        try {
          final photosStatus = await Permission.photos.request();
          if (photosStatus.isGranted) {
            return true;
          }
        } catch (e) {
          DiagnosticLogger.instance.warning('⚠️ Photos permission not available: $e');
        }
      }

      // Permanently denied - need to open settings
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }

      // Even if permission is denied, we can still use app's external directory
      // Return true to allow saving to app's Downloads folder
      DiagnosticLogger.instance.warning('⚠️ Storage permission not granted, but will try app directory');
      return true;
    } else if (Platform.isIOS) {
      // iOS doesn't need special permissions for app's documents directory
      return true;
    }

    return true;
  }

  /// Get the appropriate download directory based on platform
  /// Android: ALWAYS returns public Downloads folder (/storage/emulated/0/Download)
  ///         This ensures files are visible in File Manager
  /// iOS: Returns Documents directory (OS limitation)
  Future<Directory?> _getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        // CRITICAL: Always use public Downloads directory for visibility in File Manager
        // Path: /storage/emulated/0/Download
        // This is the standard Android Downloads folder visible to users
        final publicDownloadsPath = '/storage/emulated/0/Download';
        final publicDownloads = Directory(publicDownloadsPath);
        
        // Ensure directory exists - create if it doesn't
        if (!await publicDownloads.exists()) {
          try {
            await publicDownloads.create(recursive: true);
            DiagnosticLogger.instance.warning('📁 Created public Downloads directory: $publicDownloadsPath');
          } catch (e) {
            DiagnosticLogger.instance.warning('⚠️ Could not create public Downloads directory: $e');
            // Still try to return it - might work even if create failed
          }
        }
        
        // Verify we can access the directory
        try {
          if (await publicDownloads.exists()) {
            DiagnosticLogger.instance.warning('📁 Using public Downloads directory: ${publicDownloads.path}');
            return publicDownloads;
          }
        } catch (e) {
          DiagnosticLogger.instance.warning('⚠️ Cannot write to public Downloads directory: $e');
        }
        
        // If public Downloads fails, log error but don't fallback to app directory
        // This ensures we know when files won't be visible
        DiagnosticLogger.instance.error('❌ Public Downloads directory not accessible. Files may not be visible in File Manager.');
        return publicDownloads; // Return anyway - let the save operation handle the error
      } else if (Platform.isIOS) {
        // iOS: Use Documents directory (visible in Files app)
        final documentsDir = await getApplicationDocumentsDirectory();
        DiagnosticLogger.instance.debug('📁 Using iOS Documents directory: ${documentsDir.path}');
        return documentsDir;
      }

      // For other platforms
      final appDir = await getApplicationDocumentsDirectory();
      DiagnosticLogger.instance.error('📁 Using default documents directory: ${appDir.path}');
      return appDir;
    } catch (e) {
      DiagnosticLogger.instance.error('❌ Error getting download directory: $e');
      return null;
    }
  }

  /// Cancel an ongoing download
  void cancelDownload(String fileId) {
    isDownloading[fileId] = false;
    downloadProgress.remove(fileId);
  }

  /// Get download progress for a specific file
  double getProgress(String fileId) {
    return downloadProgress[fileId] ?? 0.0;
  }

  /// Check if a file is currently being downloaded
  bool isFileDownloading(String fileId) {
    return isDownloading[fileId] ?? false;
  }

  /// Save document bytes to file
  /// [fileBytes] - File bytes as List`<int>`
  /// [fileName] - Name to save the file as
  /// [fileId] - Unique identifier for tracking this download
  /// Saves to device Downloads folder (Android) or Documents directory (iOS)
  Future<Map<String, dynamic>> saveDocumentBytes({
    required List<int> fileBytes,
    required String fileName,
    required String fileId,
  }) async {
    try {
      // Check and request permissions first
      final hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        return {
          'success': false,
          'error': 'Storage permission denied. Please enable it in settings.',
        };
      }

      // Mark as saving
      isDownloading[fileId] = true;
      downloadProgress[fileId] = 0.0;

      // Get the appropriate directory - use actual Downloads folder for visibility
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        isDownloading[fileId] = false;
        return {
          'success': false,
          'error': 'Could not access download directory',
        };
      }
      
      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      DiagnosticLogger.instance.debug('📁 Using download directory: ${directory.path}');

      // Sanitize filename - remove invalid characters
      String sanitizedFileName = fileName
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');

      // Create the initial file path
      String filePath = '${directory.path}/$sanitizedFileName';
      File file = File(filePath);

      // Check if file already exists and generate unique name if needed
      if (await file.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nameParts = sanitizedFileName.split('.');
        final extension = nameParts.length > 1 ? nameParts.last : '';
        final nameWithoutExt = nameParts.length > 1
            ? nameParts.sublist(0, nameParts.length - 1).join('.')
            : sanitizedFileName;
        sanitizedFileName = '${nameWithoutExt}_$timestamp${extension.isNotEmpty ? '.$extension' : ''}';
        filePath = '${directory.path}/$sanitizedFileName';
        file = File(filePath); // Create new File object with updated path
      }

      DiagnosticLogger.instance.debug('💾 Saving file bytes to: $filePath');
      DiagnosticLogger.instance.debug('💾 File size: ${fileBytes.length} bytes');
      DiagnosticLogger.instance.debug('💾 Directory exists: ${await directory.exists()}');

      // Write bytes to file with flush to ensure data is written
      await file.writeAsBytes(fileBytes, flush: true);

      // CRITICAL: Verify file exists after writing
      final fileExists = await file.exists();
      if (!fileExists) {
        DiagnosticLogger.instance.error('❌ File does not exist after write operation');
        isDownloading[fileId] = false;
        downloadProgress.remove(fileId);
        return {
          'success': false,
          'error': 'File save failed: File was not created',
        };
      }

      // Verify file size matches
      final savedFileSize = await file.length();
      if (savedFileSize != fileBytes.length) {
        DiagnosticLogger.instance.warning('⚠️ File size mismatch: Expected ${fileBytes.length}, got $savedFileSize');
        // Don't fail here, but log the warning
      }

      // For Android 10+ (API 29+): Index file in MediaStore to ensure visibility in Downloads app
      // Note: Files in /storage/emulated/0/Download are visible in File Manager,
      // but MediaStore indexing ensures they appear in the Downloads app
      if (Platform.isAndroid) {
        try {
          await _indexFileInMediaStore(filePath, sanitizedFileName);
        } catch (e) {
          // Don't fail if MediaStore indexing fails - file is still saved
          DiagnosticLogger.instance.warning('⚠️ Could not index file in MediaStore (file is still saved): $e');
        }
      }

      // Save complete
      isDownloading[fileId] = false;
      downloadProgress.remove(fileId);

      DiagnosticLogger.instance.info('✅ File saved successfully: $filePath');
      DiagnosticLogger.instance.info('✅ File exists: ${await file.exists()}');
      DiagnosticLogger.instance.info('✅ File size: ${await file.length()} bytes');
      DiagnosticLogger.instance.info('✅ File location: ${directory.path} (visible in File Manager)');

      return {
        'success': true,
        'filePath': filePath, // Return absolute path
        'fileName': sanitizedFileName,
      };
    } catch (e, stackTrace) {
      DiagnosticLogger.instance.error('❌ Error saving file bytes: $e');
      DiagnosticLogger.instance.error('❌ Stack trace: $stackTrace');
      isDownloading[fileId] = false;
      downloadProgress.remove(fileId);

      return {
        'success': false,
        'error': 'Failed to save file: ${e.toString()}',
      };
    }
  }

  /// Index file in MediaStore for Android 10+ (API 29+)
  /// This ensures files appear in the Downloads app
  /// Files in /storage/emulated/0/Download are already visible in File Manager
  Future<void> _indexFileInMediaStore(String filePath, String fileName) async {
    if (!Platform.isAndroid) {
      return; // Only needed for Android
    }

    try {
      final result = await _platformChannel.invokeMethod<bool>(
        'indexFileInMediaStore',
        {
          'filePath': filePath,
          'fileName': fileName,
        },
      );

      if (result == true) {
        DiagnosticLogger.instance.warning('✅ File indexed in MediaStore: $fileName');
      } else {
        DiagnosticLogger.instance.warning('⚠️ MediaStore indexing returned false (file still saved)');
      }
    } catch (e) {
      // Don't throw - file is still saved and visible in File Manager
      DiagnosticLogger.instance.warning('⚠️ MediaStore indexing error (non-critical): $e');
    }
  }
}