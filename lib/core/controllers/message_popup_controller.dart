import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/custom_message_popup.dart';

/// Centralized controller for showing custom popups
/// Replaces all SnackBar usage across the app
class MessagePopupController {
  /// Show success popup - auto-dismisses after 3 seconds
  static Future<void> showSuccess({
    required String messageKey,
    String titleKey = '',
  }) async {
    Get.dialog(
      CustomMessagePopup(
        titleKey: titleKey,
        messageKey: messageKey,
        messageType: MessageType.success,
      ),
      barrierDismissible: true,
    );
    
    // Auto-dismiss after 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// Show error popup - auto-dismisses after 3 seconds
  static Future<void> showError({
    required String messageKey,
    String titleKey = '',
  }) async {
    Get.dialog(
      CustomMessagePopup(
        titleKey: titleKey,
        messageKey: messageKey,
        messageType: MessageType.error,
      ),
      barrierDismissible: true,
    );
    
    // Auto-dismiss after 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// Show warning popup with OK button
  static void showWarning({
    required String messageKey,
    String titleKey = '',
  }) {
    Get.dialog(
      CustomMessagePopup(
        titleKey: titleKey,
        messageKey: messageKey,
        messageType: MessageType.warning,
      ),
      barrierDismissible: true,
    );
  }

  /// Show info popup.
  /// [autoDismissSeconds] if null or 0: no auto-dismiss (caller closes with Get.back()).
  /// Otherwise auto-dismisses after that many seconds.
  static Future<void> showInfo({
    required String messageKey,
    String titleKey = '',
    int? autoDismissSeconds = 3,
  }) async {
    Get.dialog(
      CustomMessagePopup(
        titleKey: titleKey,
        messageKey: messageKey,
        messageType: MessageType.info,
      ),
      barrierDismissible: true,
    );
    
    if (autoDismissSeconds == null || autoDismissSeconds <= 0) return;
    
    await Future.delayed(Duration(seconds: autoDismissSeconds));
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// Show confirmation popup with Yes/No buttons
  static Future<bool> showConfirmation({
    required String messageKey,
    String titleKey = '',
    String primaryButtonKey = 'yes',
    String secondaryButtonKey = 'no',
    VoidCallback? onPrimary,
    VoidCallback? onSecondary,
  }) async {
    final result = await Get.dialog<bool>(
      CustomMessagePopup(
        titleKey: titleKey,
        messageKey: messageKey,
        messageType: MessageType.confirmation,
        primaryAction: PopupAction(
          labelKey: primaryButtonKey,
          isPrimary: true,
          onPressed: onPrimary,
        ),
        secondaryAction: PopupAction(
          labelKey: secondaryButtonKey,
          isPrimary: false,
          onPressed: onSecondary,
        ),
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  /// Show popup with custom actions (e.g., Cancel/Open, Cancel/Logout)
  static Future<bool?> showCustom({
    required String messageKey,
    required String titleKey,
    required MessageType messageType,
    PopupAction? primaryAction,
    PopupAction? secondaryAction,
    bool barrierDismissible = true,
  }) async {
    final result = await Get.dialog<bool>(
      CustomMessagePopup(
        titleKey: titleKey,
        messageKey: messageKey,
        messageType: messageType,
        primaryAction: primaryAction,
        secondaryAction: secondaryAction,
      ),
      barrierDismissible: barrierDismissible,
    );

    return result;
  }
}
