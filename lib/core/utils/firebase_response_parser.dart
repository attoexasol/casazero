import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Parses Laravel login JSON. Firebase fields are TOP LEVEL ONLY.
class FirebaseResponseParser {
  FirebaseResponseParser._();

  /// Dio body → `Map<String, dynamic>` (handles Map or JSON string).
  static Map<String, dynamic>? normalizeBody(dynamic root) {
    if (root == null) return null;

    if (root is Response) {
      return normalizeBody(root.data);
    }

    if (root is String) {
      final trimmed = root.trim();
      if (trimmed.isEmpty) return null;
      try {
        return normalizeBody(jsonDecode(trimmed));
      } catch (_) {
        return null;
      }
    }

    if (root is Map) {
      return Map<String, dynamic>.from(
        root.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    return null;
  }

  /// Top-level `firebase_token` only (not inside `data`).
  static String? extractFirebaseToken(Map<String, dynamic> body) {
    final raw = body['firebase_token'] ?? body['firebaseToken'];
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return s;
  }

  /// Top-level `firebase_project_id` only.
  static String? extractFirebaseProjectId(Map<String, dynamic> body) {
    final raw = body['firebase_project_id'] ?? body['firebaseProjectId'];
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    return s;
  }

  static void logLoginBody(Map<String, dynamic> body) {
    final token = extractFirebaseToken(body);
    final projectId = extractFirebaseProjectId(body);
    debugPrint('[LOGIN] response keys=${body.keys.join(", ")}');
    debugPrint(
      '[LOGIN] firebase_token (snake) exists=${body['firebase_token'] != null}',
    );
    debugPrint(
      '[LOGIN] firebaseToken (camel) exists=${body['firebaseToken'] != null}',
    );
    debugPrint('[LOGIN] custom token parsed=${token != null}');
    debugPrint('[LOGIN] custom token length=${token?.length ?? 0}');
    if (token != null && token.length > 12) {
      debugPrint('[LOGIN] custom token prefix=${token.substring(0, 12)}...');
    }
    debugPrint('[LOGIN] firebase_project_id=${projectId ?? "null"}');
  }

  static String describeTokenPresence(String? token) {
    if (token == null) return 'null';
    final t = token.trim();
    if (t.isEmpty) return 'empty';
    return 'len=${t.length} prefix=${t.length > 12 ? t.substring(0, 12) : t}...';
  }
}
