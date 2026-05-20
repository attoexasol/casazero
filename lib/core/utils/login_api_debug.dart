import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'firebase_response_parser.dart';

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

    print('');
    print('╔══════════════════════════════════════════════════════════╗');
    print('║              LOGIN API — OUTGOING REQUEST                ║');
    print('╚══════════════════════════════════════════════════════════╝');
    print('[LOGIN API] method=$method');
    print('[LOGIN API] url=$fullUrl');
    print('[LOGIN API] request body:');
    print(_safeEncode(safeBody));
    print('');
  }

  static void logResponse({
    required String fullUrl,
    required int? statusCode,
    required dynamic rawData,
    Map<String, dynamic>? normalizedBody,
  }) {
    print('');
    print('╔══════════════════════════════════════════════════════════╗');
    print('║              LOGIN API — INCOMING RESPONSE               ║');
    print('╚══════════════════════════════════════════════════════════╝');
    print('[LOGIN API] url=$fullUrl');
    print('[LOGIN API] statusCode=$statusCode');
    print('[LOGIN API] rawData.runtimeType=${rawData.runtimeType}');

    if (rawData is String) {
      print('[LOGIN API] rawData (string, first 2000 chars):');
      final s = rawData;
      print(s.length > 2000 ? s.substring(0, 2000) : s);
    } else {
      print('[LOGIN API] rawData:');
      print(_safeEncode(rawData));
    }

    if (normalizedBody != null) {
      print('[LOGIN API] normalized body keys=${normalizedBody.keys.join(", ")}');
      print('[LOGIN API] normalized body:');
      print(_safeEncode(normalizedBody));

      print('================ LOGIN RESPONSE DEBUG ================');
      print('response keys=${normalizedBody.keys}');
      print(
        'firebase_token (snake_case) exists=${normalizedBody['firebase_token'] != null}',
      );
      print(
        'firebaseToken (camelCase) exists=${normalizedBody['firebaseToken'] != null}',
      );
      final parsed = FirebaseResponseParser.extractFirebaseToken(normalizedBody);
      print('firebase custom token parsed=${parsed != null}');
      print('firebase custom token length=${parsed?.length ?? 0}');
      if (parsed != null && parsed.length > 20) {
        print('firebase custom token prefix=${parsed.substring(0, 20)}...');
      }
      print(
        'firebase_project_id=${FirebaseResponseParser.extractFirebaseProjectId(normalizedBody) ?? normalizedBody['firebase_project_id'] ?? normalizedBody['firebaseProjectId']}',
      );
      print('status=${normalizedBody['status']}');
      print('message=${normalizedBody['message']}');
      print('token (api) exists=${normalizedBody['token'] != null}');
      print('user exists=${normalizedBody['user'] != null}');
      print('is_trusted=${normalizedBody['is_trusted']}');
      print('=====================================================');

      _scanForFirebaseKeys(normalizedBody, prefix: 'body');
    } else {
      print('[LOGIN API] WARNING: could not normalize response to Map');
    }
    print('');
  }

  /// Finds firebase_* keys anywhere in JSON (debug only).
  static void _scanForFirebaseKeys(dynamic node, {required String prefix}) {
    if (node is Map) {
      for (final entry in node.entries) {
        final key = entry.key.toString();
        final path = '$prefix.$key';
        if (key.toLowerCase().contains('firebase')) {
          final v = entry.value;
          print(
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
