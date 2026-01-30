import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../localization/locale_controller.dart';

/// Message types for different popup styles
enum MessageType { success, error, warning, info, confirmation }

/// Action button configuration
class PopupAction {
  final String labelKey; // Localization key
  final VoidCallback? onPressed;
  final bool isPrimary;

  const PopupAction({
    required this.labelKey,
    this.onPressed,
    this.isPrimary = false,
  });
}

/// Centralized custom popup widget that replaces SnackBars
/// Shows only the buttons needed for each scenario
class CustomMessagePopup extends StatelessWidget {
  final String titleKey;
  final String messageKey;
  final MessageType messageType;
  final PopupAction? primaryAction;
  final PopupAction? secondaryAction;

  const CustomMessagePopup({
    super.key,
    required this.titleKey,
    required this.messageKey,
    required this.messageType,
    this.primaryAction,
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = (screenWidth * 0.78).clamp(260.0, 360.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Obx(() {
          // Rebuild when locale changes so title/message/buttons show in current language (en vs it)
          final _ = Get.find<LocaleController>().locale;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with icon and title
              _buildHeader(),
              const SizedBox(height: 4),

              // Message content (localized)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  6,
                  16,
                  (primaryAction != null || secondaryAction != null) ? 0 : 16,
                ),
                child: Text(
                  messageKey.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              // Action buttons only for confirmation (when primary/secondary provided)
              if (primaryAction != null || secondaryAction != null)
                _buildActions(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    IconData icon;
    Color iconColor;
    String title;

    switch (messageType) {
      case MessageType.success:
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        title = titleKey.isEmpty ? 'success'.tr : titleKey.tr;
        break;
      case MessageType.error:
        icon = Icons.error;
        iconColor = AppColors.danger;
        title = titleKey.isEmpty ? 'error'.tr : titleKey.tr;
        break;
      case MessageType.warning:
        icon = Icons.warning;
        iconColor = AppColors.warning;
        title = titleKey.isEmpty ? 'warning'.tr : titleKey.tr;
        break;
      case MessageType.info:
        icon = Icons.info;
        iconColor = AppColors.info;
        title = titleKey.isEmpty ? 'info'.tr : titleKey.tr;
        break;
      case MessageType.confirmation:
        icon = Icons.help_outline;
        iconColor = AppColors.neutralInk700;
        title = titleKey.isEmpty ? 'confirmation'.tr : titleKey.tr;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.neutralInk900,
                fontSize: 17,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final actions = <Widget>[];

    // Build buttons based on provided actions
    if (secondaryAction != null) {
      actions.add(
        Expanded(
          child: TextButton(
            onPressed: () {
              Get.back(result: false);
              secondaryAction?.onPressed?.call();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              secondaryAction!.labelKey.tr,
              style: AppTextStyles.button.copyWith(
                color: AppColors.neutralInk700,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    if (primaryAction != null) {
      actions.add(
        SizedBox(
          height: 40,
          width: 90,
          child: ElevatedButton(
            onPressed: () {
              Get.back(result: true);
              primaryAction?.onPressed?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getPrimaryButtonColor(),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              primaryAction!.labelKey.tr,
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    // Buttons only for confirmation; never show OK for info/error/success/warning
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

      child: Row(
        children: actions.length > 1
            ? [const Spacer(), ...actions]
            : [const Spacer(), ...actions, const Spacer()],
      ),
    );
  }

  Color _getPrimaryButtonColor() {
    switch (messageType) {
      case MessageType.success:
        return AppColors.success;
      case MessageType.error:
        return AppColors.danger;
      case MessageType.warning:
        return AppColors.warning;
      case MessageType.info:
        return AppColors.info;
      case MessageType.confirmation:
        return AppColors.brandSage500;
    }
  }
}
