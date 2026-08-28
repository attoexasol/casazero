import 'dart:convert';

import 'firebase_response_parser.dart';
import 'package:casazero/core/logging/diagnostic_logger.dart';

/// Verbose login API logging (passwords redacted).
class LoginApiDebug {
  LoginApiDebug._();

  static const _encoder = JsonEncoder.withIndent('  ');

  static void logRequest({
    required String method,
    required String fullUrl,
    required Map<String, dynamic> body,
  }) {
    final safeBody = Map<String, dynamic>.from(body);
    if (safeBody.containsKey('password')) {
      safeBody['password'] = '***REDACTED***';
    }

    DiagnosticLogger.instance.debug('');
    DiagnosticLogger.instance.debug('╔══════════════════════════════════════════════════════════╗');
    DiagnosticLogger.instance.debug('║              LOGIN API — OUTGOING REQUEST                ║');
    DiagnosticLogger.instance.debug('╚══════════════════════════════════════════════════════════╝');
    DiagnosticLogger.instance.debug('[LOGIN API] method=$method');
    DiagnosticLogger.instance.debug('[LOGIN API] url=$fullUrl');
    DiagnosticLogger.instance.debug('[LOGIN API] request body:');
    DiagnosticLogger.instance.debug(_safeEncode(safeBody));
    DiagnosticLogger.instance.debug('');
  }

  static void logResponse({
    required String fullUrl,
    required int? statusCode,
    required dynamic rawData,
    Map<String, dynamic>? normalizedBody,
  }) {
    DiagnosticLogger.instance.debug('');
    DiagnosticLogger.instance.debug('╔══════════════════════════════════════════════════════════╗');
    DiagnosticLogger.instance.debug('║              LOGIN API — INCOMING RESPONSE               ║');
    DiagnosticLogger.instance.debug('╚══════════════════════════════════════════════════════════╝');
    DiagnosticLogger.instance.debug('[LOGIN API] url=$fullUrl');
    DiagnosticLogger.instance.debug('[LOGIN API] statusCode=$statusCode');
    DiagnosticLogger.instance.debug('[LOGIN API] rawData.runtimeType=${rawData.runtimeType}');

    if (rawData is String) {
      DiagnosticLogger.instance.debug('[LOGIN API] rawData (string, first 2000 chars):');
      final s = rawData;
      DiagnosticLogger.instance.debug(s.length > 2000 ? s.substring(0, 2000) : s);
    } else {
      DiagnosticLogger.instance.debug('[LOGIN API] rawData:');
      DiagnosticLogger.instance.debug(_safeEncode(rawData));
    }

    if (normalizedBody != null) {
      DiagnosticLogger.instance.debug('[LOGIN API] normalized body keys=${normalizedBody.keys.join(", ")}');
      DiagnosticLogger.instance.debug('[LOGIN API] normalized body:');
      DiagnosticLogger.instance.debug(_safeEncode(normalizedBody));

      DiagnosticLogger.instance.debug('================ LOGIN RESPONSE DEBUG ================');
      DiagnosticLogger.instance.debug('response keys=${normalizedBody.keys}');
      DiagnosticLogger.instance.debug(
        'firebase_token (snake_case) exists=${normalizedBody['firebase_token'] != null}',
      );
      DiagnosticLogger.instance.debug(
        'firebaseToken (camelCase) exists=${normalizedBody['firebaseToken'] != null}',
      );
      final parsed = FirebaseResponseParser.extractFirebaseToken(normalizedBody);
      DiagnosticLogger.instance.debug('firebase custom token parsed=${parsed != null}');
      DiagnosticLogger.instance.debug('firebase custom token length=${parsed?.length ?? 0}');
      if (parsed != null && parsed.length > 20) {
        DiagnosticLogger.instance.debug('firebase custom token prefix=${parsed.substring(0, 20)}...');
      }
      DiagnosticLogger.instance.debug(
        'firebase_project_id=${FirebaseResponseParser.extractFirebaseProjectId(normalizedBody) ?? normalizedBody['firebase_project_id'] ?? normalizedBody['firebaseProjectId']}',
      );
      DiagnosticLogger.instance.debug('status=${normalizedBody['status']}');
      DiagnosticLogger.instance.debug('message=${normalizedBody['message']}');
      DiagnosticLogger.instance.debug('token (api) exists=${normalizedBody['token'] != null}');
      DiagnosticLogger.instance.debug('user exists=${normalizedBody['user'] != null}');
      DiagnosticLogger.instance.debug('is_trusted=${normalizedBody['is_trusted']}');
      DiagnosticLogger.instance.warning('=====================================================');

      _scanForFirebaseKeys(normalizedBody, prefix: 'body');
    } else {
      DiagnosticLogger.instance.warning('[LOGIN API] WARNING: could not normalize response to Map');
    }
    DiagnosticLogger.instance.debug('');
  }

  /// Finds firebase_* keys anywhere in JSON (debug only).
  static void _scanForFirebaseKeys(dynamic node, {required String prefix}) {
    if (node is Map) {
      for (final entry in node.entries) {
        final key = entry.key.toString();
        final path = '$prefix.$key';
        if (key.toLowerCase().contains('firebase')) {
          final v = entry.value;
          DiagnosticLogger.instance.debug(
            '[LOGIN API] FOUND firebase-related key at $path '
            'type=${v.runtimeType} '
            'preview=${_previewValue(v)}',
          );
        }
        _scanForFirebaseKeys(entry.value, prefix: path);
      }
    } else if (node is List) {
      for (var i = 0; i < node.length; i++) {
        _scanForFirebaseKeys(node[i], prefix: '$prefix[$i]');
      }
    }
  }

  static String _previewValue(dynamic v) {
    if (v == null) return 'null';
    final s = v.toString();
    if (s.length > 40) return '${s.substring(0, 40)}...';
    return s;
  }

  static String _safeEncode(dynamic value) {
    try {
      return _encoder.convert(value);
    } catch (e) {
      return value.toString();
    }
  }
}
