// core/services/zip_download_service.dart
//
// Download encrypted ZIP → extract (with optional password) → open first file with native "open with".
// If the ZIP is password-protected, the caller provides password via [onPasswordRequired].
// After successful extraction, the first extracted file is opened with the OS app chooser.

import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'storage_service.dart';

/// Downloads ZIP, extracts it (prompts for password if protected), then opens
/// the first extracted file with native "open with".
///
/// Use [onPasswordRequired] to show a password dialog when the ZIP is encrypted.
/// Minimal UI: see [ZipDownloadExample] in core/widgets/zip_download_example.dart.
class ZipDownloadService extends getx.GetxService {
  late final Dio _dio;
  final getx.RxMap<String, double> downloadProgress = <String, double>{}.obs;
  final getx.RxMap<String, bool> isDownloading = <String, bool>{}.obs;

  ZipDownloadService() {
    _dio = Dio();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final storage = getx.Get.isRegistered<StorageService>()
                ? getx.Get.find<StorageService>()
                : null;
            final token = storage?.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          return handler.next(options);
        },
      ),
    );
  }

  /// Downloads ZIP from [zipUrl], extracts it (asking for password via
  /// [onPasswordRequired] if protected), then opens the first extracted file
  /// with native "open with".
  ///
  /// [zipUrl] – Full URL of the ZIP (e.g. from backend).
  /// [fileName] – Optional save name (default: derived from URL or "download.zip").
  /// [fileId] – Optional id for progress tracking.
  /// [onProgress] – Optional progress callback (0.0–1.0).
  /// [onPasswordRequired] – When the ZIP is password-protected, this is called
  ///   to get the password (e.g. show a dialog). Return null to cancel.
  ///
  /// Returns map with 'success', 'filePath' / 'extractedDir' on success, or
  /// 'success': false and 'error' on failure.
  Future<Map<String, dynamic>> downloadAndOpenZip({
    required String zipUrl,
    String? fileName,
    String? fileId,
    void Function(double progress)? onProgress,
    Future<String?> Function()? onPasswordRequired,
  }) async {
    final id = fileId ?? 'zip_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // --- 1) Permissions (Android). iOS uses app Documents, no extra permission. ---
      final hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        return {
          'success': false,
          'error': 'Storage permission denied. Please enable it in settings.',
        };
      }

      isDownloading[id] = true;
      downloadProgress[id] = 0.0;

      // --- 2) Resolve storage directory (platform-specific). ---
      final directory = await _getStorageDirectory();
      if (directory == null) {
        isDownloading[id] = false;
        downloadProgress.remove(id);
        return {
          'success': false,
          'error': 'Could not access storage directory.',
        };
      }

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Resolve file name
      String saveFileName = fileName ?? _fileNameFromUrl(zipUrl);
      saveFileName = _sanitizeFileName(saveFileName);
      if (!saveFileName.toLowerCase().endsWith('.zip')) {
        saveFileName = '$saveFileName.zip';
      }

      String filePath = '${directory.path}/$saveFileName';
      final file = File(filePath);

      // Unique name if file exists
      if (await file.exists()) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final base = saveFileName.replaceAll(RegExp(r'\.zip$', caseSensitive: false), '');
        saveFileName = '${base}_$ts.zip';
        filePath = '${directory.path}/$saveFileName';
      }

      // --- 3) Stream download to file (Dio writes directly to path = no full buffering). ---
      await _dio.download(
        zipUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final p = (received / total).clamp(0.0, 1.0);
            downloadProgress[id] = p;
            onProgress?.call(p);
          }
        },
      );

      isDownloading[id] = false;
      downloadProgress.remove(id);

      final savedFile = File(filePath);
      if (!await savedFile.exists()) {
        return {'success': false, 'error': 'File was not saved correctly.'};
      }

      // --- 4) Extract ZIP (with password if protected). ---
      final baseName = saveFileName.replaceAll(RegExp(r'\.zip$', caseSensitive: false), '');
      final ts = DateTime.now().millisecondsSinceEpoch;
      final outputDirPath = '${directory.path}/${baseName}_$ts';
      final outputDir = Directory(outputDirPath);
      await outputDir.create(recursive: true);

      final extractResult = await extractZipFile(
        zipPath: filePath,
        outputDirPath: outputDirPath,
        onPasswordRequired: onPasswordRequired,
      );

      if (extractResult['success'] != true) {
        final err = extractResult['error'] ?? 'Extraction failed.';
        final needPw = extractResult['needPassword'] == true;
        return {
          'success': false,
          'error': err,
          'filePath': filePath,
          'needPassword': needPw,
        };
      }

      // --- 5) Open first extracted file with native "open with". ---
      final firstFile = extractResult['firstFilePath'] as String?;
      if (firstFile != null && await File(firstFile).exists()) {
        await OpenFilex.open(firstFile);
      } else {
        // No file to open (empty zip or only directories); open extracted folder if possible
        await OpenFilex.open(outputDirPath);
      }

      return {
        'success': true,
        'filePath': filePath,
        'fileName': saveFileName,
        'extractedDir': outputDirPath,
      };
    } catch (e) {
      isDownloading[id] = false;
      downloadProgress.remove(id);
      String msg = 'Download failed.';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          msg = 'Connection timeout. Check your network.';
        } else if (e.type == DioExceptionType.badResponse) {
          msg = 'Server error. Try again later.';
        } else {
          msg = 'Network error. Check your connection.';
        }
      }
      return {'success': false, 'error': msg};
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.storage.isGranted) return true;
    final status = await Permission.storage.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) await openAppSettings();
    return true;
  }

  /// Android: public Downloads. iOS: app Documents (Files app can open and prompt for password).
  Future<Directory?> _getStorageDirectory() async {
    try {
      if (Platform.isAndroid) {
        const path = '/storage/emulated/0/Download';
        final dir = Directory(path);
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir;
      }
      if (Platform.isIOS) {
        return await getApplicationDocumentsDirectory();
      }
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return null;
    }
  }

  static String _fileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final seg = uri.pathSegments;
      if (seg.isNotEmpty) {
        final last = seg.last;
        if (last.contains('.')) return last;
      }
    } catch (_) {}
    return 'download.zip';
  }

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').replaceAll(RegExp(r'\s+'), '_');
  }

  /// Extracts [zipPath] to [outputDirPath]. Shows password option FIRST via
  /// [onPasswordRequired], then verifies by extracting. Only on success returns
  /// firstFilePath; native "open with" is shown by the caller after that.
  Future<Map<String, dynamic>> extractZipFile({
    required String zipPath,
    required String outputDirPath,
    Future<String?> Function()? onPasswordRequired,
  }) async {
    try {
      // --- Password first: always show password dialog before attempting extraction. ---
      String? password;
      if (onPasswordRequired != null) {
        password = await onPasswordRequired();
        // null = user cancelled
        if (password == null) {
          return {
            'success': false,
            'error': 'Cancelled.',
            'needPassword': true,
          };
        }
        // empty string = user chose "no password" (unencrypted ZIP)
      }

      // --- Verify password by extracting (with password if provided, else without). ---
      try {
        if (password != null && password.isNotEmpty) {
          await extractFileToDisk(zipPath, outputDirPath, password: password);
        } else {
          await extractFileToDisk(zipPath, outputDirPath);
        }
      } catch (e) {
        // Extraction failed: wrong password or corrupt/encrypted without password
        return {
          'success': false,
          'error': 'Wrong password or extraction failed. Please try again.',
          'needPassword': true,
        };
      }

      final firstFile = _firstFileInDirectory(Directory(outputDirPath));
      return {
        'success': true,
        'extractedDir': outputDirPath,
        'firstFilePath': firstFile,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), ''),
        'needPassword': false,
      };
    }
  }

  /// Returns the path of the first file found under [dir] (recursive), or null.
  static String? _firstFileInDirectory(Directory dir) {
    if (!dir.existsSync()) return null;
    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is File) return entity.path;
      if (entity is Directory) {
        final f = _firstFileInDirectory(entity);
        if (f != null) return f;
      }
    }
    return null;
  }

  double getProgress(String fileId) => downloadProgress[fileId] ?? 0.0;
  bool isFileDownloading(String fileId) => isDownloading[fileId] ?? false;
}
