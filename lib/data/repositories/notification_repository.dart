import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

class NotificationRepository {
  final ApiService _apiService = Get.find();
  final StorageService _storageService = Get.find();

  Future<void> sendChatNotification({
    required int receiverId,
    required int senderId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final payload = <String, dynamic>{
      'receiver_id': receiverId,
      'sender_id': senderId,
      'title': title,
      'body': body,
    };
    if (data != null && data.isNotEmpty) {
      payload['data'] = data;
    }

    debugPrint(
      '[NotificationRepository] sendChatNotification '
      'sender=$senderId receiver=$receiverId',
    );

    await _apiService.post(ApiConstants.SEND_CHAT_NOTIFICATION, data: payload);
  }

  /// Registers / rotates the device FCM token with Laravel.
  ///
  /// Returns `true` when the API reports success; `false` on any failure.
  /// Never throws — callers may fire-and-forget safely.
  Future<bool> updateFcmToken(String fcmToken) async {
    final trimmed = fcmToken.trim();
    final userId = _storageService.getUserData()?['id'];
    final platform = Platform.isIOS
        ? 'ios'
        : (Platform.isAndroid ? 'android' : 'unknown');
    final masked = _maskFcmToken(trimmed);

    try {
      final apiToken = _storageService.getAccessToken();
      if (apiToken == null || apiToken.isEmpty) {
        debugPrint(
          '[FCM Update] skipped — no API token '
          '(userId=$userId platform=$platform)',
        );
        return false;
      }

      if (trimmed.isEmpty) {
        debugPrint(
          '[FCM Update] skipped — empty fcm_token '
          '(userId=$userId platform=$platform)',
        );
        return false;
      }

      debugPrint(
        '[FCM Update] started '
        '(userId=$userId platform=$platform token=$masked)',
      );

      final response = await _apiService.post(
        ApiConstants.UPDATE_FCM_TOKEN,
        data: {
          'token': apiToken,
          'fcm_token': trimmed,
          'platform': platform,
        },
      );

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final status = data['status'];
      final ok = (response.statusCode == 200 || response.statusCode == 201) &&
          (status == true || status == 'true' || status == 1 || status == '1');

      if (ok) {
        debugPrint(
          '[FCM Update] succeeded '
          '(userId=$userId platform=$platform token=$masked)',
        );
        return true;
      }

      debugPrint(
        '[FCM Update] failed '
        '(userId=$userId platform=$platform token=$masked '
        'statusCode=${response.statusCode} message=${data['message']})',
      );
      return false;
    } catch (e) {
      debugPrint(
        '[FCM Update] failed '
        '(userId=$userId platform=$platform token=$masked error=$e)',
      );
      return false;
    }
  }

  static String _maskFcmToken(String token) {
    if (token.isEmpty) return '(empty)';
    if (token.length <= 8) return '$token********';
    return '${token.substring(0, 8)}********';
  }

  Future<void> updateAppStatus({required String appStatus}) async {
    final apiToken = _storageService.getAccessToken();
    if (apiToken == null || apiToken.isEmpty) {
      debugPrint(
        '[NotificationRepository] updateAppStatus skipped — no api token',
      );
      return;
    }

    debugPrint('[NotificationRepository] updateAppStatus status=$appStatus');

    await _apiService.post(
      ApiConstants.UPDATE_APP_STATUS,
      data: {
        'api_token': apiToken,
        'app_status': appStatus,
      },
    );
  }
}
