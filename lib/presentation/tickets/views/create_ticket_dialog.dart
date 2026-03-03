import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/tickets_controller.dart';

/// Create Support Ticket modal dialog. UI matches React ticketdialog.tsx and Figma spec.
/// - Rounded corners 16, background #FAFAF7, border #E6E6E6 1px, max width ~400.
/// - Create Ticket calls controller.handleCreateTicket(), Cancel pops.
class CreateTicketDialog extends StatefulWidget {
  const CreateTicketDialog({super.key});

  @override
  State<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<CreateTicketDialog> {
  static const double _dialogMaxWidth = 400;
  static const double _padding = 20;
  static const double _radius = 16;
  static const Color _dialogBg = Color(0xFFFAFAF7);
  static const Color _dialogBorder = Color(0xFFE6E6E6);
  static const Color _greenActive = AppColors.brandSage600;

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TicketsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<TicketsController>();
    final nt = _ctrl.newTicket;
    _titleController = TextEditingController(text: nt['title'] ?? '');
    _descriptionController = TextEditingController(
      text: nt['description'] ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        decoration: BoxDecoration(
          color: _dialogBg,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _dialogBorder, width: 1),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildForm(),
                const SizedBox(height: 20),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'createSupportTicket'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.CardHeaderText.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.neutralInk900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'createTicketSubtitle'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14,
                color: AppColors.neutralInk500,
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(
              Icons.close,
              size: 20,
              color: AppColors.neutralInk700,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Obx(() {
      final nt = _ctrl.newTicket;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel('categoryLabel'.tr),
          const SizedBox(height: 6),
          _buildDropdown<String>(
            value: nt['category']!.isEmpty ? null : nt['category'],
            hint: 'selectACategory'.tr,
            items: TicketsController.categories,
            labelBuilder: TicketsController.categoryLabel,
            onChanged: (v) => _ctrl.updateNewTicket('category', v ?? ''),
          ),
          // const SizedBox(height: 16),
          // _buildLabel('title'.tr),
          // const SizedBox(height: 6),
          // TextField(
          //   controller: _titleController,
          //   onChanged: (v) => _ctrl.updateNewTicket('title', v),
          //   maxLines: 1,
          //   style: AppTextStyles.bodyMedium.copyWith(
          //     fontSize: 14,
          //     color: AppColors.neutralInk900,
          //   ),
          //   decoration: _underlineDecoration('briefDescriptionOfIssue'.tr),
          // ),
          const SizedBox(height: 16),
          _buildLabel('description'.tr),
          const SizedBox(height: 6),
          TextField(
            controller: _descriptionController,
            onChanged: (v) => _ctrl.updateNewTicket('description', v),
            maxLines: 4,
            minLines: 4,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              color: AppColors.neutralInk900,
            ),
            decoration: _underlineDecoration('provideMoreDetails'.tr),
          ),
          //const SizedBox(height: 8),
          // _buildLabel('priority'.tr),
          // const SizedBox(height: 6),
          // _buildDropdown<String>(
          //   value: nt['priority'],
          //   hint: 'priorityMedium'.tr,
          //   items: TicketsController.priorityValues,
          //   labelBuilder: TicketsController.priorityLabel,
          //   onChanged: (v) => _ctrl.updateNewTicket('priority', v ?? 'medium'),
          // ),
          const SizedBox(height: 16),
          _buildAddPhotosButton(),
        ],
      );
    });
  }

  InputDecoration _underlineDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.neutralInk400,
        fontSize: 14,
      ),
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.neutralLine200),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.neutralLine200),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _greenActive, width: 2),
      ),
      contentPadding: const EdgeInsets.only(bottom: 8),
      isDense: true,
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.neutralInk900,
      ),
    );
  }

  Widget _buildDropdown<T extends String>({
    required T? value,
    required String hint,
    required List<T> items,
    String Function(T)? labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    final effectiveValue = value == null || value.isEmpty ? null : value;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutralLine200)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: effectiveValue as T?,
          isExpanded: true,
          hint: Text(
            hint,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutralInk400,
              fontSize: 14,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: _greenActive),
          underline: const SizedBox(),
          borderRadius: BorderRadius.circular(8),
          dropdownColor: _dialogBg,
          focusColor: _greenActive,
          items: items.map((e) {
            return DropdownMenuItem<T>(
              value: e,
              child: Text(
                labelBuilder != null ? labelBuilder(e) : e,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutralInk900,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAddPhotosButton() {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(
        Icons.image_outlined,
        size: 20,
        color: AppColors.neutralInk700,
      ),
      label: Text(
        'addPhotos'.tr,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.neutralInk900,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.neutralInk900,
        side: const BorderSide(color: AppColors.neutralLine200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _ctrl.handleCreateTicket(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandSage600,
              foregroundColor: AppColors.surfaceWhite,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: Text(
              'createTicket'.tr,
              style: AppTextStyles.button.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.surfaceWhite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceWhite,
              foregroundColor: AppColors.neutralInk900,
              side: const BorderSide(color: AppColors.neutralLine200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              'cancel'.tr,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.neutralInk700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
