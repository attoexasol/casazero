import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/custom_message_popup.dart';

/// Centralized controller for showing custom popups
/// Replaces all SnackBar usage across the app
class MessagePopupController {
  // ---------- Internal helper ----------
  static void _closeIfOpen() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // ---------- Success ----------
  /// Show success popup - auto-dismisses after 3 seconds
  static Future<void> showSuccess({
    required String messageKey,
    String titleKey = '',
  }) async {
    _closeIfOpen();

    Get.dialog(
      CustomMessagePopup(
        titleKey: titleKey,
        messageKey: messageKey,
        messageType: MessageType.success,
      ),
      barrierDismissible: true,
    );

    await Future.delayed(const Duration(seconds: 3));
    _closeIfOpen();
  }

  // ---------- Error ----------
  /// Show error popup - auto-dismisses after 3 seconds
  static Future<void> showError({
    required String messageKey,
    String titleKey = '',
  }) async {
    _closeIfOpen();

    Get.dialog(
      CustomMessagePopup(
        titleKey: titleKey,
        messageKey: messageKey,
        messageType: MessageType.error,
      ),
      barrierDismissible: true,
    );

    await Future.delayed(const Duration(seconds: 3));
    _closeIfOpen();
  }

  // ---------- Warning ----------
  /// Show warning popup (no auto dismiss)
  static void showWarning({
    required String messageKey,
    String titleKey = '',
  }) {
    _closeIfOpen();

    Get.dialog(
      CustomMessagePopup(
        titleKey: titleKey,
        messageKey: messageKey,
        messageType: MessageType.warning,
      ),
      barrierDismissible: true,
    );
  }

  // ---------- Info ----------
  /// Show info popup.
  /// If [autoDismissSeconds] is null or 0 → stays open until manually closed.
  static Future<void> showInfo({
    required String messageKey,
    String titleKey = '',
    int? autoDismissSeconds = 3,
  }) async {
    _closeIfOpen();

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
    _closeIfOpen();
  }

  // ---------- Download ----------
  /// Show downloading popup (stays open until closed manually)
  static void showDownloading({
    required String messageKey,
    String titleKey = 'downloading',
  }) {
    _closeIfOpen();

    Get.dialog(
      CustomMessagePopup(
        titleKey: titleKey,
        messageKey: messageKey,
        messageType: MessageType.info,
      ),
      barrierDismissible: false,
    );
  }

  /// Close current popup safely
  static void closePopup() {
    _closeIfOpen();
  }

  // ---------- Confirmation ----------
  /// Show confirmation popup with Yes/No buttons
  static Future<bool> showConfirmation({
    required String messageKey,
    String titleKey = '',
    String primaryButtonKey = 'yes',
    String secondaryButtonKey = 'no',
    VoidCallback? onPrimary,
    VoidCallback? onSecondary,
  }) async {
    _closeIfOpen();

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

  // ---------- Custom ----------
  /// Show popup with custom actions (Cancel/Open, Logout, etc.)
  static Future<bool?> showCustom({
    required String messageKey,
    required String titleKey,
    required MessageType messageType,
    PopupAction? primaryAction,
    PopupAction? secondaryAction,
    bool barrierDismissible = true,
  }) async {
    _closeIfOpen();

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
