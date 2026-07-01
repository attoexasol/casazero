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
