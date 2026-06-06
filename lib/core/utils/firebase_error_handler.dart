import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Parsed Firebase/Firestore failure with a user-facing message key.
class FirebaseErrorInfo {
  final String code;
  final String message;
  final String userMessageKey;
  final bool isRetryable;
  final bool isIndexRequired;
  final bool isPermissionDenied;

  const FirebaseErrorInfo({
    required this.code,
    required this.message,
    required this.userMessageKey,
    this.isRetryable = false,
    this.isIndexRequired = false,
    this.isPermissionDenied = false,
  });

  static const String defaultUserMessageKey = 'tryAgainLater';
  static const String networkUserMessageKey = 'checkNetworkAndRetry';
  static const String permissionUserMessageKey = 'adminChatAccessDenied';
  static const String indexUserMessageKey = 'privateChatIndexPending';
}

/// Centralized Firebase error parsing, logging, and user-friendly messages.
class FirebaseErrorHandler {
  FirebaseErrorHandler._();

  static FirebaseErrorInfo parse(Object error) {
    if (error is FirebaseException) {
      return _fromFirebaseException(error);
    }
    final text = error.toString().toLowerCase();
    if (text.contains('permission') || text.contains('permission-denied')) {
      return const FirebaseErrorInfo(
        code: 'permission-denied',
        message: 'Permission denied',
        userMessageKey: FirebaseErrorInfo.permissionUserMessageKey,
        isPermissionDenied: true,
      );
    }
    if (text.contains('failed_precondition') ||
        text.contains('failed-precondition') ||
        text.contains('requires an index')) {
      return const FirebaseErrorInfo(
        code: 'failed-precondition',
        message: 'Index required',
        userMessageKey: FirebaseErrorInfo.indexUserMessageKey,
        isIndexRequired: true,
        isRetryable: true,
      );
    }
    if (text.contains('unavailable') || text.contains('network')) {
      return const FirebaseErrorInfo(
        code: 'unavailable',
        message: 'Service unavailable',
        userMessageKey: FirebaseErrorInfo.networkUserMessageKey,
        isRetryable: true,
      );
    }
    return FirebaseErrorInfo(
      code: 'unknown',
      message: error.toString(),
      userMessageKey: FirebaseErrorInfo.defaultUserMessageKey,
      isRetryable: true,
    );
  }

  static FirebaseErrorInfo _fromFirebaseException(FirebaseException e) {
    final code = e.code;
    switch (code) {
      case 'permission-denied':
        return FirebaseErrorInfo(
          code: code,
          message: e.message ?? 'Permission denied',
          userMessageKey: FirebaseErrorInfo.permissionUserMessageKey,
          isPermissionDenied: true,
        );
      case 'failed-precondition':
        return FirebaseErrorInfo(
          code: code,
          message: e.message ?? 'Index required',
          userMessageKey: FirebaseErrorInfo.indexUserMessageKey,
          isIndexRequired: true,
          isRetryable: true,
        );
      case 'unavailable':
      case 'deadline-exceeded':
        return FirebaseErrorInfo(
          code: code,
          message: e.message ?? 'Service unavailable',
          userMessageKey: FirebaseErrorInfo.networkUserMessageKey,
          isRetryable: true,
        );
      case 'cancelled':
        return FirebaseErrorInfo(
          code: code,
          message: e.message ?? 'Operation cancelled',
          userMessageKey: FirebaseErrorInfo.networkUserMessageKey,
          isRetryable: true,
        );
      default:
        return FirebaseErrorInfo(
          code: code,
          message: e.message ?? 'Unknown Firebase error',
          userMessageKey: FirebaseErrorInfo.defaultUserMessageKey,
          isRetryable: code == 'unknown' || code == 'aborted',
        );
    }
  }

  /// Structured debug log: `[tag] path=... userId=... code=... message=...`
  static void log({
    required String tag,
    required Object error,
    String? firestorePath,
    String? conversationId,
    String? userId,
  }) {
    final info = parse(error);
    debugPrint(
      '[$tag] path=${firestorePath ?? '-'} '
      'conversationId=${conversationId ?? '-'} '
      'userId=${userId ?? '-'} '
      'code=${info.code} '
      'message=${info.message}',
    );
    if (error is FirebaseException && error.stackTrace != null) {
      debugPrint('[$tag] stackTrace=${error.stackTrace}');
    }
  }
}
