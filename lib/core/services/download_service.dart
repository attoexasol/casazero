import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

class DownloadService extends getx.GetxService {
  final Dio _dio = Dio();
  final StorageService _storageService = getx.Get.find();

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
          print('🌐 [DOWNLOAD REQUEST] ${options.method} ${options.uri}');
          print('🔑 [DOWNLOAD TOKEN] ${token ?? 'NO_TOKEN_FOUND'}');
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

      print('📥 Downloading to: $finalPath');
      print('📥 From URL: $fileUrl');

      // Prepare the full URL
      String fullUrl = fileUrl;
      if (!fileUrl.startsWith('http://') && !fileUrl.startsWith('https://')) {
        // If URL is relative, prepend the base URL
        fullUrl = '${ApiConstants.BASE_URL.replaceAll('/api', '')}$fileUrl';
      }

      // Download the file with progress tracking
      await _dio.download(
        fullUrl,
        finalPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total);
            downloadProgress[fileId] = progress;
            print('📥 Download progress: ${(progress * 100).toStringAsFixed(0)}%');
          }
        },
      );

      // Download complete
      isDownloading[fileId] = false;
      downloadProgress.remove(fileId);

      print('✅ Download completed: $finalPath');

      return {
        'success': true,
        'filePath': finalPath,
        'fileName': fileName,
      };
    } catch (e) {
      print('❌ Download error: $e');
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
  Future<bool> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we don't need WRITE_EXTERNAL_STORAGE
      // For Android 10-12, we need storage permission
      if (await Permission.storage.isGranted) {
        return true;
      }

      // Request permission
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }

      // If denied, check if we can request again
      if (status.isDenied) {
        // Try requesting photos permission for Android 13+
        final photosStatus = await Permission.photos.request();
        return photosStatus.isGranted;
      }

      // Permanently denied - need to open settings
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }

      return false;
    } else if (Platform.isIOS) {
      // iOS doesn't need special permissions for app's documents directory
      return true;
    }

    return true;
  }

  /// Get the appropriate download directory based on platform
  Future<Directory?> _getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        // For Android, try to get the Downloads directory
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          return directory;
        }

        // Fallback to external storage directory
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Create a Downloads folder in app's external directory
          final downloadsDir = Directory('${externalDir.path}/Downloads');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          return downloadsDir;
        }

        // Last resort - app's documents directory
        return await getApplicationDocumentsDirectory();
      } else if (Platform.isIOS) {
        // For iOS, use the app's documents directory
        return await getApplicationDocumentsDirectory();
      }

      // For other platforms
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      print('❌ Error getting download directory: $e');
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
}