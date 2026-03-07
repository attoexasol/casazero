import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

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
    _ctrl.clearPhotos();
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
          const SizedBox(height: 16),
          _buildLabel('title'.tr),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            onChanged: (v) => _ctrl.updateNewTicket('title', v),
            maxLines: 1,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              color: AppColors.neutralInk900,
            ),
            decoration: _underlineDecoration('briefDescriptionOfIssue'.tr),
          ),
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
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
            Flexible(
              child: Text(
                'addOthers'.tr,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _greenActive,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.neutralLine200)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedId,
            isExpanded: true,
            menuMaxHeight: 200,
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
    return Obx(() {
      final photos = _ctrl.attachedPhotos;
      final canAddMore = photos.length < TicketsController.maxPhotos;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: canAddMore ? _showPhotoPickerSheet : null,
            icon: Icon(
              Icons.image_outlined,
              size: 20,
              color: canAddMore ? AppColors.neutralInk700 : AppColors.neutralInk400,
            ),
            label: Text(
              photos.isEmpty
                  ? 'addPhotos'.tr
                  : '${'addPhotos'.tr} (${photos.length}/${TicketsController.maxPhotos})',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: canAddMore ? AppColors.neutralInk900 : AppColors.neutralInk400,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceWhite,
              foregroundColor: AppColors.neutralInk900,
              side: const BorderSide(color: AppColors.neutralLine200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPhotoGrid(photos),
          ],
        ],
      );
    });
  }

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _dialogBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.neutralLine200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: _greenActive),
                title: Text(
                  'takePhoto'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 15,
                    color: AppColors.neutralInk900,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: _greenActive),
                title: Text(
                  'chooseFromGallery'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 15,
                    color: AppColors.neutralInk900,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo != null) {
        _ctrl.addPhoto(File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('photoPickError'.tr),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final remaining = TicketsController.maxPhotos - _ctrl.attachedPhotos.length;
      if (remaining <= 0) return;

      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      for (int i = 0; i < images.length && i < remaining; i++) {
        _ctrl.addPhoto(File(images[i].path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('photoPickError'.tr),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Widget _buildPhotoGrid(List<File> photos) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(photos.length, (index) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                photos[index],
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.neutralLine200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 24,
                    color: AppColors.neutralInk400,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: () => _ctrl.removePhoto(index),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _handleCreateTicket() async {
    if (_ctrl.selectedCategoryId.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('pleaseSelectCategory'.tr),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('pleaseEnterDescription'.tr),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    final success = await _ctrl.handleCreateTicket(context);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ticketCreationFailed'.tr),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Widget _buildFooter(BuildContext context) {
    return Obx(() {
      final isCreating = _ctrl.isCreatingTicket.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCreating ? null : _handleCreateTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandSage600,
                foregroundColor: AppColors.surfaceWhite,
                disabledBackgroundColor: AppColors.brandSage600.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surfaceWhite,
                      ),
                    )
                  : Text(
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
              onPressed: isCreating ? null : () => Navigator.of(context).pop(),
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
    });
  }
}
