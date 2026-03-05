import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/tickets_controller.dart';
import '../models/issue_type_model.dart';

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
  late final TextEditingController _issueTypeEnController;
  late final TextEditingController _issueTypeItController;
  late TicketsController _ctrl;

  bool _isAddingNewType = false;
  bool _isSubmittingNewType = false;
  final _addTypeFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<TicketsController>();
    final nt = _ctrl.newTicket;
    _titleController = TextEditingController(text: nt['title'] ?? '');
    _descriptionController = TextEditingController(
      text: nt['description'] ?? '',
    );
    _issueTypeEnController = TextEditingController();
    _issueTypeItController = TextEditingController();
    _ctrl.selectedCategoryId.value = null;
    _ctrl.fetchIssueTypes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _issueTypeEnController.dispose();
    _issueTypeItController.dispose();
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
          _buildCategoryDropdown(),
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

  static const int _addOthersSentinel = -9999;

  Widget _buildCategoryDropdown() {
    final isLoading = _ctrl.isLoadingIssueTypes.value;
    final items = _ctrl.issueTypes;
    final selectedId = _ctrl.selectedCategoryId.value;

    if (isLoading) {
      return Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.neutralLine200)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _greenActive),
            ),
            const SizedBox(width: 12),
            Text(
              'loading'.tr,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutralInk400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_isAddingNewType) {
      return _buildInlineAddIssueTypeFields();
    }

    final langCode = Get.locale?.languageCode ?? 'en';
    final dropdownItems = items.map((IssueTypeModel issue) {
      return DropdownMenuItem<int>(
        value: issue.id,
        child: Text(
          issue.localizedName(langCode),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutralInk900,
            fontSize: 14,
          ),
        ),
      );
    }).toList();

    dropdownItems.add(
      DropdownMenuItem<int>(
        value: _addOthersSentinel,
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline, size: 18, color: _greenActive),
            const SizedBox(width: 8),
            Text(
              'addOthers'.tr,
              style: AppTextStyles.bodyMedium.copyWith(
                color: _greenActive,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutralLine200)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedId,
          isExpanded: true,
          hint: Text(
            'selectACategory'.tr,
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
          items: dropdownItems,
          onChanged: (int? value) {
            if (value == _addOthersSentinel) {
              setState(() => _isAddingNewType = true);
              return;
            }
            _ctrl.selectedCategoryId.value = value;
            final match = items.firstWhereOrNull((e) => e.id == value);
            _ctrl.updateNewTicket('category', match?.localizedName(langCode) ?? '');
          },
        ),
      ),
    );
  }

  Widget _buildInlineAddIssueTypeFields() {
    return Form(
      key: _addTypeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel('issueTypeEnglish'.tr),
          const SizedBox(height: 6),
          TextFormField(
            controller: _issueTypeEnController,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              color: AppColors.neutralInk900,
            ),
            decoration: _underlineDecoration('enterIssueTypeEnglish'.tr),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'fieldRequired'.tr : null,
          ),
          const SizedBox(height: 12),
          _buildLabel('issueTypeItalian'.tr),
          const SizedBox(height: 6),
          TextFormField(
            controller: _issueTypeItController,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              color: AppColors.neutralInk900,
            ),
            decoration: _underlineDecoration('enterIssueTypeItalian'.tr),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'fieldRequired'.tr : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _issueTypeEnController.clear();
                    _issueTypeItController.clear();
                    setState(() => _isAddingNewType = false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neutralInk700,
                    side: const BorderSide(color: AppColors.neutralLine200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'cancel'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutralInk700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmittingNewType ? null : _handleAddIssueType,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _greenActive,
                    foregroundColor: AppColors.surfaceWhite,
                    disabledBackgroundColor: _greenActive.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmittingNewType
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.surfaceWhite,
                          ),
                        )
                      : Text(
                          'add'.tr,
                          style: AppTextStyles.button.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.surfaceWhite,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddIssueType() async {
    if (!_addTypeFormKey.currentState!.validate()) return;
    if (_isSubmittingNewType) return;

    setState(() => _isSubmittingNewType = true);

    try {
      final result = await _ctrl.createIssueType(
        issueType: _issueTypeEnController.text.trim(),
        issueTypeIt: _issueTypeItController.text.trim(),
      );

      if (result != null) {
        _ctrl.selectedCategoryId.value = result.id;
        final langCode = Get.locale?.languageCode ?? 'en';
        _ctrl.updateNewTicket('category', result.localizedName(langCode));
        _issueTypeEnController.clear();
        _issueTypeItController.clear();
        setState(() {
          _isAddingNewType = false;
          _isSubmittingNewType = false;
        });
      } else {
        setState(() => _isSubmittingNewType = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('failedToCreateIssueType'.tr),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmittingNewType = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failedToCreateIssueType'.tr),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
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
