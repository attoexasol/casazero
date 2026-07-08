import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/outlined_custom_button.dart';
import '../../../core/widgets/responsive_alert_dialog.dart';
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
  late TicketsController _ctrl;

  final ImagePicker _imagePicker = ImagePicker();
  double? _dialogMaxHeight;

  double get _photoThumbSize => 72.w;

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
    _ctrl.selectedCategoryId.value = null;
    _ctrl.clearPhotos();
    _ctrl.fetchIssueTypes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogMaxWidth = screenSize.width >= 600
        ? 500.0
        : (screenSize.width - 32.w).clamp(280.w, 500.w);
    final baseMaxHeight =
        _dialogMaxHeight ?? screenSize.height * 0.72;

    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: ResponsiveAlertDialog.formDialogAlignment(context),
      insetPadding: ResponsiveAlertDialog.formDialogInsetPadding(context),
      child: ResponsiveAlertDialog.boundedFormDialogBody(
        context: context,
        maxWidth: dialogMaxWidth,
        preferredMaxHeight: baseMaxHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm50,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.neutralLine200),
            boxShadow: AppShadows.shadowLg,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Column(
              mainAxisSize:
                  ResponsiveAlertDialog.formDialogMainAxisSize(context),
              children: [
                _buildHeader(),
                ResponsiveAlertDialog.formDialogScrollBody(
                  context: context,
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                  child: _buildForm(),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.neutralLine100, width: 1.w),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  'createTicketSubtitle'.tr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutralInk500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, size: 22.sp),
            color: AppColors.neutralInk400,
            splashRadius: 20.r,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
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
        SizedBox(height: 12.h),
        _buildPhotoFormatsInfo(),
        SizedBox(height: 14.h),
        Obx(() => _buildCategoryDropdown()),
        SizedBox(height: 12.h),
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
        SizedBox(height: 12.h),
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
            minHeight: 80.h,
            maxHeight: isEmpty ? 120.h : 200.h,
          ),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isEmpty
                  ? AppColors.surfaceWarm50
                  : AppColors.brandSage50,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isEmpty
                    ? AppColors.neutralLine200
                    : AppColors.brandSage300,
                width: 2.w,
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
        final isCompact = availableHeight < 120.h;
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isCompact ? 48.w : 64.w,
                  height: isCompact ? 48.w : 64.w,
                  decoration: BoxDecoration(
                    color: AppColors.brandSage500.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: isCompact ? 24.sp : 32.sp,
                    color: AppColors.brandSage500,
                  ),
                ),
                SizedBox(height: isCompact ? 8.h : 12.h),
                Text(
                  'addPhotos'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk700,
                    fontWeight: FontWeight.w500,
                    fontSize: isCompact ? 13.sp : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCompact) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'chooseFromGallery'.tr,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutralInk400,
                      fontSize: 11.sp,
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
    final thumbSize = _photoThumbSize;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              ...List<Widget>.generate(photos.length, (index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.file(
                        photos[index],
                        width: thumbSize,
                        height: thumbSize,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: thumbSize,
                          height: thumbSize,
                          decoration: BoxDecoration(
                            color: AppColors.neutralLine200,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 28.sp,
                            color: AppColors.neutralInk400,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -6.h,
                      right: -6.w,
                      child: GestureDetector(
                        onTap: () => _ctrl.removePhoto(index),
                        child: Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 14.sp,
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
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: AppColors.brandSage500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.brandSage300),
                    ),
                    child: Icon(
                      Icons.add,
                      color: AppColors.brandSage500,
                      size: 32.sp,
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
        Icon(
          Icons.info_outline,
          size: 16.sp,
          color: AppColors.neutralInk400,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            '${'addPhotos'.tr} · ${TicketsController.maxPhotos} max',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.neutralInk500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

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
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.neutralLine100,
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(color: AppColors.neutralLine200),
            ),
            child: Center(
              child: SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.brandSage600,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final langCode = Get.locale?.languageCode ?? 'en';
    final dropdownItems = items.map((IssueTypeModel issue) {
      final isSelected = issue.id == selectedId;
      return DropdownMenuItem<int>(
        value: issue.id,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 10.h,
          ),
          child: Text(
            issue.localizedName(langCode),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutralInk900,
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'categoryLabel'.tr,
          style: AppTextStyles.label.copyWith(
            color: AppColors.neutralInk700,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.neutralLine100,
            borderRadius: BorderRadius.circular(25.r),
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
                  itemHeight: 52.h,
                  menuMaxHeight: 280.h,
                  dropdownColor: AppColors.surfaceWhite,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16.r),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.neutralInk700,
                    size: 24.sp,
                  ),
                  hint: Text(
                    'selectACategory'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutralInk400,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk900,
                    fontSize: 14.sp,
                  ),
                  selectedItemBuilder: (context) {
                    return items.map((issue) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          issue.localizedName(langCode),
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.neutralInk900,
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  items: dropdownItems,
                  onChanged: (int? value) {
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

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWarm50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.neutralLine200,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: _greenActive,
                  size: 24.sp,
                ),
                title: Text(
                  'takePhoto'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 15.sp,
                    color: AppColors.neutralInk900,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: _greenActive,
                  size: 24.sp,
                ),
                title: Text(
                  'chooseFromGallery'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 15.sp,
                    color: AppColors.neutralInk900,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              SizedBox(height: 8.h),
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
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              border: Border(
                top: BorderSide(color: AppColors.neutralLine100, width: 1.w),
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
                    height: 48.h,
                    borderRadius: 12.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CustomButton(
                    text: 'createTicket'.tr,
                    icon: Icons.send_rounded,
                    onPressed: canSubmit ? _handleCreateTicket : null,
                    isLoading: isCreating,
                    backgroundColor: AppColors.brandSage500,
                    textColor: AppColors.surfaceWhite,
                    height: 48.h,
                    borderRadius: 12.r,
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
