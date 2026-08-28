import 'dart:async';
import 'dart:io';
import 'dart:ui' show ErrorCallback, PlatformDispatcher;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Local diagnostic logger for TestFlight troubleshooting.
///
/// Writes timestamped entries to a rolling file in Application Support.
/// Never throws to callers. Does not upload logs.
class DiagnosticLogger with WidgetsBindingObserver {
  DiagnosticLogger._();

  static final DiagnosticLogger instance = DiagnosticLogger._();

  static const String _fileName = 'casazero_diagnostic.log';
  static const int _defaultMaxBytes = 10 * 1024 * 1024;
  static const int _defaultRetainBytes = 8 * 1024 * 1024;

  static final DateFormat _stampFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _exportNameFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');

  static final RegExp _redactBearer = RegExp(
    r'Bearer\s+\S+',
    caseSensitive: false,
  );
  static final RegExp _redactSensitivePairs = RegExp(
    r'(password|passwd|secret|token|refresh_token|access_token|'
    r'authorization|api[_-]?key|fcm_token|apns)\s*[:=]\s*\S+',
    caseSensitive: false,
  );

  final List<String> _pending = <String>[];
  Completer<void>? _initCompleter;
  Future<void>? _drainFuture;
  File? _file;
  bool _initialized = false;
  bool _lifecycleAttached = false;
  bool _errorHandlersInstalled = false;

  /// Overridable for tests. Production uses [_defaultMaxBytes].
  @visibleForTesting
  int maxLogBytes = _defaultMaxBytes;

  /// Overridable for tests. Production uses [_defaultRetainBytes].
  @visibleForTesting
  int retainLogBytes = _defaultRetainBytes;

  /// Initialize file storage. Safe to call multiple times. Never throws.
  Future<void> init({
    Directory? overrideDirectory,
    bool attachLifecycleObserver = true,
  }) async {
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();
    try {
      if (kIsWeb) {
        _initialized = true;
        return;
      }

      Directory dir;
      if (overrideDirectory != null) {
        dir = overrideDirectory;
      } else {
        dir = await getApplicationSupportDirectory().timeout(
          const Duration(seconds: 2),
        );
      }

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      _file = File('${dir.path}${Platform.pathSeparator}$_fileName');
      if (!await _file!.exists()) {
        await _file!.writeAsString(
          '=== CasaZero Diagnostic Log ===\n',
          flush: true,
        );
      }

      _initialized = true;
      await _drain();

      if (attachLifecycleObserver && !_lifecycleAttached) {
        try {
          WidgetsBinding.instance.addObserver(this);
          _lifecycleAttached = true;
        } catch (_) {}
      }
    } catch (_) {
      _initialized = _file != null;
    } finally {
      if (!(_initCompleter?.isCompleted ?? true)) {
        _initCompleter!.complete();
      }
    }
  }

  /// Additive Flutter / zone error hooks. Does not replace existing handlers.
  void installErrorHandlers() {
    if (_errorHandlersInstalled) return;
    _errorHandlersInstalled = true;

    try {
      final FlutterExceptionHandler? previousFlutterOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        error(
          'FlutterError',
          error: details.exception,
          stackTrace: details.stack,
          metadata: <String, Object?>{
            'type': details.exception.runtimeType.toString(),
            'library': details.library,
          },
        );
        if (previousFlutterOnError != null) {
          previousFlutterOnError(details);
        } else {
          FlutterError.presentError(details);
        }
      };
    } catch (_) {}

    try {
      final ErrorCallback? previousPlatformOnError =
          PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        this.error(
          'Uncaught asynchronous error',
          error: error,
          stackTrace: stack,
          metadata: <String, Object?>{
            'type': error.runtimeType.toString(),
          },
        );
        if (previousPlatformOnError != null) {
          return previousPlatformOnError(error, stack);
        }
        return false;
      };
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    info('App lifecycle: ${state.name}');
  }

  void debug(
    String message, {
    Map<String, Object?>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      DiagnosticLogLevel.debug,
      message,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void info(
    String message, {
    Map<String, Object?>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      DiagnosticLogLevel.info,
      message,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void warning(
    String message, {
    Map<String, Object?>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      DiagnosticLogLevel.warning,
      message,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void error(
    String message, {
    Map<String, Object?>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      DiagnosticLogLevel.error,
      message,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Append a structured diagnostic entry. Never throws.
  void log(
    DiagnosticLogLevel level,
    String message, {
    Map<String, Object?>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    try {
      final StringBuffer buffer = StringBuffer();
      buffer.write(_stampFormat.format(DateTime.now()));
      buffer.write(' [${level.label}] ');
      buffer.write(_sanitize(message));
      buffer.writeln();

      if (metadata != null && metadata.isNotEmpty) {
        metadata.forEach((String key, Object? value) {
          buffer.write('  ');
          buffer.write(_sanitize(key));
          buffer.write(': ');
          buffer.write(_sanitize('$value'));
          buffer.writeln();
        });
      }

      if (error != null) {
        buffer.write('Error: ');
        buffer.write(_sanitize(error.runtimeType.toString()));
        buffer.write(': ');
        buffer.write(_sanitize(error.toString()));
        buffer.writeln();
      }

      if (stackTrace != null) {
        buffer.write('StackTrace: ');
        buffer.writeln(_sanitize(stackTrace.toString()));
      }

      final String entry = buffer.toString();
      if (kDebugMode) {
        debugPrint(entry.trimRight());
      }
      _pending.add(entry);
      unawaited(_drain());
    } catch (_) {}
  }

  /// Records app/device environment. Safe to call unawaited. Never throws.
  Future<void> logEnvironment() async {
    try {
      await init();

      final Map<String, Object?> meta = <String, Object?>{
        'flutter': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'dart': _safeDartVersion(),
        'build_mode': kReleaseMode
            ? 'release'
            : (kProfileMode ? 'profile' : 'debug'),
      };

      try {
        final PackageInfo packageInfo = await PackageInfo.fromPlatform();
        meta['app_version'] = packageInfo.version;
        meta['build_number'] = packageInfo.buildNumber;
        meta['package_name'] = packageInfo.packageName;
      } catch (_) {
        meta['app_version'] = 'unavailable';
        meta['build_number'] = 'unavailable';
      }

      if (!kIsWeb) {
        meta['os'] = Platform.operatingSystem;
        meta['os_version'] = Platform.operatingSystemVersion;
        try {
          final DeviceInfoPlugin plugin = DeviceInfoPlugin();
          if (Platform.isIOS) {
            final IosDeviceInfo ios = await plugin.iosInfo;
            meta['ios_version'] = ios.systemVersion;
            meta['device_model'] = ios.utsname.machine;
            meta['is_physical_device'] = ios.isPhysicalDevice;
          } else if (Platform.isAndroid) {
            final AndroidDeviceInfo android = await plugin.androidInfo;
            meta['android_version'] = android.version.release;
            meta['device_model'] = '${android.brand} ${android.model}';
            meta['is_physical_device'] = android.isPhysicalDevice;
          }
        } catch (_) {}
      }

      info('Startup environment', metadata: meta);
    } catch (_) {}
  }

  /// Flush pending writes. Used before export. Never throws.
  Future<void> flush() async {
    try {
      await init();
      while (_pending.isNotEmpty || _drainFuture != null) {
        if (!_initialized || _file == null) break;
        await _drain();
      }
      try {
        final File? file = _file;
        if (file != null && await file.exists()) {
          final RandomAccessFile raf = await file.open(mode: FileMode.append);
          await raf.flush();
          await raf.close();
        }
      } catch (_) {}
    } catch (_) {}
  }

  /// Copy the log to a timestamped shareable file. Returns null on failure.
  @visibleForTesting
  Future<File?> prepareExportFile() async {
    try {
      await flush();
      final File? source = _file;
      if (kIsWeb || source == null) return null;

      if (!await source.exists()) {
        await source.writeAsString(
          '=== CasaZero Diagnostic Log ===\nNo entries captured yet.\n',
          flush: true,
        );
      }

      final String stamp = _exportNameFormat.format(DateTime.now());
      final String name = 'casazero_diagnostic_$stamp.txt';
      Directory destDir;
      try {
        destDir = await getTemporaryDirectory();
      } catch (_) {
        destDir = source.parent;
      }
      final File copy = File('${destDir.path}${Platform.pathSeparator}$name');
      await source.copy(copy.path);
      return copy;
    } catch (_) {
      return null;
    }
  }

  /// Flush, copy, and open the native share sheet. Returns false on failure.
  Future<bool> shareLogFile({Rect? shareOrigin}) async {
    try {
      final File? copy = await prepareExportFile();
      if (copy == null || !await copy.exists()) {
        error('Diagnostic log export failed: file unavailable');
        return false;
      }

      Rect origin = shareOrigin ?? const Rect.fromLTWH(0, 0, 1, 1);
      if (!kIsWeb && Platform.isIOS) {
        if (shareOrigin == null ||
            shareOrigin.width <= 0 ||
            shareOrigin.height <= 0) {
          origin = const Rect.fromLTWH(0, 0, 1, 1);
        }
      }

      await Share.shareXFiles(
        <XFile>[
          XFile(copy.path, name: copy.uri.pathSegments.last, mimeType: 'text/plain'),
        ],
        sharePositionOrigin: !kIsWeb && Platform.isIOS ? origin : null,
      );
      info('Diagnostic log exported');
      return true;
    } catch (e, st) {
      error('Diagnostic log export failed', error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> _drain() {
    return _drainFuture ??= _drainLoop().whenComplete(() {
      _drainFuture = null;
    });
  }

  Future<void> _drainLoop() async {
    try {
      while (_pending.isNotEmpty) {
        if (!_initialized || _file == null) {
          break;
        }
        final String batch = _pending.join();
        _pending.clear();
        try {
          await _file!.writeAsString(batch, mode: FileMode.append, flush: false);
          await _trimIfNeeded();
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _trimIfNeeded() async {
    final File? file = _file;
    if (file == null) return;
    try {
      final int length = await file.length();
      if (length <= maxLogBytes) return;

      final int retain = retainLogBytes < maxLogBytes
          ? retainLogBytes
          : (maxLogBytes * 4) ~/ 5;
      if (length <= retain) return;

      final RandomAccessFile raf = await file.open();
      try {
        final int start = length - retain;
        await raf.setPosition(start);
        final Uint8List bytes = await raf.read(retain);
        await raf.close();

        int cut = 0;
        for (int i = 0; i < bytes.length; i++) {
          if (bytes[i] == 10) {
            cut = i + 1;
            break;
          }
        }
        final Uint8List kept =
            cut > 0 && cut < bytes.length ? bytes.sublist(cut) : bytes;
        await file.writeAsBytes(kept, flush: true);
      } catch (_) {
        try {
          await raf.close();
        } catch (_) {}
      }
    } catch (_) {}
  }

  static String _safeDartVersion() {
    try {
      final String version = Platform.version;
      final int space = version.indexOf(' ');
      return space > 0 ? version.substring(0, space) : version;
    } catch (_) {
      return 'unavailable';
    }
  }

  static String _sanitize(String input) {
    String value = input;
    value = value.replaceAll(_redactBearer, 'Bearer [REDACTED]');
    value = value.replaceAllMapped(_redactSensitivePairs, (Match m) {
      final String key = m.group(1) ?? 'secret';
      return '$key=[REDACTED]';
    });
    return value;
  }

  @visibleForTesting
  File? get logFile => _file;

  @visibleForTesting
  static String sanitizeForTest(String input) => _sanitize(input);

  @visibleForTesting
  Future<void> resetForTest() async {
    _pending.clear();
    _file = null;
    _initialized = false;
    _initCompleter = null;
    _drainFuture = null;
    maxLogBytes = _defaultMaxBytes;
    retainLogBytes = _defaultRetainBytes;
  }
}

enum DiagnosticLogLevel {
  debug,
  info,
  warning,
  error;

  String get label {
    switch (this) {
      case DiagnosticLogLevel.debug:
        return 'DEBUG';
      case DiagnosticLogLevel.info:
        return 'INFO';
      case DiagnosticLogLevel.warning:
        return 'WARNING';
      case DiagnosticLogLevel.error:
        return 'ERROR';
    }
  }
}
