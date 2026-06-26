import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/outlined_custom_button.dart';
import '../controllers/tickets_controller.dart';
import '../models/issue_type_model.dart';

/// Create Support Ticket modal dialog. Shell UI matches [AddDocumentDialog].
/// Create Ticket calls controller.handleCreateTicket(), Cancel pops.
class CreateTicketDialog extends StatefulWidget {
  const CreateTicketDialog({super.key});

  @override
  State<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<CreateTicketDialog> {
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
  double? _dialogMaxHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dialogMaxHeight ??= MediaQuery.sizeOf(context).height * 0.72;
  }

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
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight:
              _dialogMaxHeight ?? MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neutralLine200),
              boxShadow: AppShadows.shadowLg,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: _buildForm(),
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.neutralLine100, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'createSupportTicket'.tr,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.neutralInk900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'createTicketSubtitle'.tr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutralInk500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 22),
            color: AppColors.neutralInk400,
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPhotoUploadArea(),
        const SizedBox(height: 12),
        _buildPhotoFormatsInfo(),
        const SizedBox(height: 14),
        Obx(() => _buildCategoryDropdown()),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'title'.tr,
          hint: 'briefDescriptionOfIssue'.tr,
          controller: _titleController,
          onChanged: (v) => _ctrl.updateNewTicket('title', v),
          keyboardType: TextInputType.text,
          backgroundColor: AppColors.neutralLine100,
          borderColor: AppColors.neutralLine200,
          textColor: AppColors.neutralInk900,
          labelColor: AppColors.neutralInk700,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'description'.tr,
          hint: 'provideMoreDetails'.tr,
          controller: _descriptionController,
          onChanged: (v) => _ctrl.updateNewTicket('description', v),
          keyboardType: TextInputType.multiline,
          maxLines: 3,
          backgroundColor: AppColors.neutralLine100,
          borderColor: AppColors.neutralLine200,
          textColor: AppColors.neutralInk900,
          labelColor: AppColors.neutralInk700,
        ),
      ],
    );
  }

  Widget _buildPhotoUploadArea() {
    return Obx(() {
      final photos = _ctrl.attachedPhotos;
      final canAddMore = photos.length < TicketsController.maxPhotos;
      final isEmpty = photos.isEmpty;

      return GestureDetector(
        onTap: isEmpty && canAddMore ? _showPhotoPickerSheet : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 80,
            maxHeight: isEmpty ? 120 : 200,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isEmpty
                  ? AppColors.surfaceWarm50
                  : AppColors.brandSage50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEmpty
                    ? AppColors.neutralLine200
                    : AppColors.brandSage300,
                width: 2,
              ),
            ),
            child: isEmpty
                ? _buildPhotoUploadPrompt()
                : _buildPhotoUploadSelected(photos, canAddMore),
          ),
        ),
      );
    });
  }

  Widget _buildPhotoUploadPrompt() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isCompact = availableHeight < 120;
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isCompact ? 48 : 64,
                  height: isCompact ? 48 : 64,
                  decoration: BoxDecoration(
                    color: AppColors.brandSage500.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: isCompact ? 24 : 32,
                    color: AppColors.brandSage500,
                  ),
                ),
                SizedBox(height: isCompact ? 8 : 12),
                Text(
                  'addPhotos'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk700,
                    fontWeight: FontWeight.w500,
                    fontSize: isCompact ? 13 : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 4),
                  Text(
                    'chooseFromGallery'.tr,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutralInk400,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoUploadSelected(List<File> photos, bool canAddMore) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...List<Widget>.generate(photos.length, (index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        photos[index],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.neutralLine200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 28,
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
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              if (canAddMore)
                GestureDetector(
                  onTap: _showPhotoPickerSheet,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.brandSage500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.brandSage300),
                    ),
                    child: Icon(
                      Icons.add,
                      color: AppColors.brandSage500,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoFormatsInfo() {
    return Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: AppColors.neutralInk400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${'addPhotos'.tr} · ${TicketsController.maxPhotos} max',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.neutralInk500,
            ),
          ),
        ),
      ],
    );
  }

  static const int _addOthersSentinel = -9999;

  Widget _buildCategoryDropdown() {
    final isLoading = _ctrl.isLoadingIssueTypes.value;
    final items = _ctrl.issueTypes;
    final selectedId = _ctrl.selectedCategoryId.value;

    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'categoryLabel'.tr,
            style: AppTextStyles.label.copyWith(
              color: AppColors.neutralInk700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.neutralLine100,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.neutralLine200),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandSage600),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_isAddingNewType) {
      return _buildInlineAddIssueTypeFields();
    }

    final langCode = Get.locale?.languageCode ?? 'en';
    final dropdownItems = items.map((IssueTypeModel issue) {
      final isSelected = issue.id == selectedId;
      return DropdownMenuItem<int>(
        value: issue.id,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          child: Text(
            issue.localizedName(langCode),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutralInk900,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }).toList();

    dropdownItems.add(
      DropdownMenuItem<int>(
        value: _addOthersSentinel,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
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
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'categoryLabel'.tr,
          style: AppTextStyles.label.copyWith(
            color: AppColors.neutralInk700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.neutralLine100,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.neutralLine200),
          ),
          child: ButtonTheme(
            alignedDropdown: true,
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: AppColors.surfaceWhite,
                highlightColor: AppColors.brandSage50,
                hoverColor: AppColors.brandSage50,
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedId,
                  isExpanded: true,
                  itemHeight: 52,
                  menuMaxHeight: 280,
                  dropdownColor: AppColors.surfaceWhite,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.neutralInk700,
                    size: 24,
                  ),
                  hint: Text(
                    'selectACategory'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutralInk400,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk900,
                    fontSize: 14,
                  ),
                  selectedItemBuilder: (context) {
                    final selectedBuilders = items.map((issue) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          issue.localizedName(langCode),
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.neutralInk900,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList();

                    selectedBuilders.add(
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'addOthers'.tr,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _greenActive,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );

                    return selectedBuilders;
                  },
                  items: dropdownItems,
                  onChanged: (int? value) {
                    if (value == _addOthersSentinel) {
                      setState(() => _isAddingNewType = true);
                      return;
                    }
                    _ctrl.selectedCategoryId.value = value;
                    final match = items.firstWhereOrNull((e) => e.id == value);
                    _ctrl.updateNewTicket(
                      'category',
                      match?.localizedName(langCode) ?? '',
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineAddIssueTypeFields() {
    return Form(
      key: _addTypeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            label: 'issueTypeEnglish'.tr,
            hint: 'enterIssueTypeEnglish'.tr,
            controller: _issueTypeEnController,
            labelColor: AppColors.neutralInk700,
            backgroundColor: AppColors.neutralLine100,
            borderColor: AppColors.neutralLine200,
            textColor: AppColors.neutralInk900,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'fieldRequired'.tr : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'issueTypeItalian'.tr,
            hint: 'enterIssueTypeItalian'.tr,
            controller: _issueTypeItController,
            labelColor: AppColors.neutralInk700,
            backgroundColor: AppColors.neutralLine100,
            borderColor: AppColors.neutralLine200,
            textColor: AppColors.neutralInk900,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'fieldRequired'.tr : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedCustomButton(
                  text: 'cancel'.tr,
                  onPressed: () {
                    _issueTypeEnController.clear();
                    _issueTypeItController.clear();
                    setState(() => _isAddingNewType = false);
                  },
                  borderColor: AppColors.neutralLine200,
                  textColor: AppColors.neutralInk700,
                  height: 48,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'add'.tr,
                  onPressed: _isSubmittingNewType ? null : _handleAddIssueType,
                  isLoading: _isSubmittingNewType,
                  backgroundColor: AppColors.brandSage500,
                  textColor: AppColors.surfaceWhite,
                  height: 48,
                  borderRadius: 12,
                  showShadow: false,
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

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWarm50,
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
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: _greenActive,
                ),
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
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: _greenActive,
                ),
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
      final remaining =
          TicketsController.maxPhotos - _ctrl.attachedPhotos.length;
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

  Widget _buildFooter() {
    return ListenableBuilder(
      listenable: _descriptionController,
      builder: (context, _) {
        return Obx(() {
          final isCreating = _ctrl.isCreatingTicket.value;
          final canSubmit = _ctrl.selectedCategoryId.value != null &&
              _descriptionController.text.trim().isNotEmpty &&
              !isCreating;

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              border: Border(
                top: BorderSide(color: AppColors.neutralLine100, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedCustomButton(
                    text: 'cancel'.tr,
                    onPressed: isCreating
                        ? null
                        : () => Navigator.of(context).pop(),
                    borderColor: AppColors.neutralLine200,
                    textColor: AppColors.neutralInk700,
                    height: 48,
                    borderRadius: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'createTicket'.tr,
                    icon: Icons.send_rounded,
                    onPressed: canSubmit ? _handleCreateTicket : null,
                    isLoading: isCreating,
                    backgroundColor: AppColors.brandSage500,
                    textColor: AppColors.surfaceWhite,
                    height: 48,
                    borderRadius: 12,
                    showShadow: false,
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
