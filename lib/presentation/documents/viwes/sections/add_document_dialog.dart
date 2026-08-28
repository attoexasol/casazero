import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../core/controllers/message_popup_controller.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/outlined_custom_button.dart';
import '../../../../core/widgets/responsive_alert_dialog.dart';
import '../../../../data/models/document_category_model.dart';
import '../../controllers/documents_controller.dart';
import '../../models/upload_result.dart';

class AddDocumentDialog extends StatefulWidget {
  final VoidCallback onClose;
  final Function(Map<String, dynamic>)? onUpload;

  const AddDocumentDialog({super.key, required this.onClose, this.onUpload});

  @override
  State<AddDocumentDialog> createState() => _AddDocumentDialogState();
}

class _AddDocumentDialogState extends State<AddDocumentDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final DocumentsController _controller = Get.find<DocumentsController>();

  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedFileSize;
  int? _selectedCategoryId; // Changed from String to int (category ID)
  double? _dialogMaxHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dialogMaxHeight ??= MediaQuery.sizeOf(context).height * 0.72;
  }
  @override
  void initState() {
    super.initState();
    // Ensure categories are loaded when dialog opens
    _ensureCategoriesLoaded();

    // Popup messages are handled directly in _handleUpload
  }

  /// Ensure categories are loaded from API
  /// Uses cached categories if already loaded, otherwise fetches
  Future<void> _ensureCategoriesLoaded() async {
    // If categories are already loaded, no need to fetch again
    if (_controller.categories.isNotEmpty) {
      return;
    }
    
    // If already loading, wait for it
    if (_controller.isLoadingCategories.value) {
      return;
    }
    
    // Fetch categories from API
    await _controller.fetchDocumentCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = result.files.single.size;

        setState(() {
          _selectedFile = file;
          _selectedFileName = fileName;
          _selectedFileSize = _formatFileSize(fileSize);
        });
      }
    } catch (e) {
      if (mounted) {
        MessagePopupController.showError(
          messageKey: 'filePickError',
          titleKey: 'error',
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if the selected file is an image
  bool _isImageFile(String? fileName) {
    if (fileName == null) return false;
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }

  /// Get file type from extension
  String _getFileType(String? fileName) {
    if (fileName == null) return 'unknown'.tr;
    final extension = fileName.toLowerCase().split('.').last;
    return extension.toUpperCase();
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _selectedFileSize = null;
    });
  }

  String _categoryDisplayName(DocumentCategoryModel category) {
    final localeController = Get.find<LocaleController>();
    final isItalian = localeController.isItalian;
    return isItalian
        ? (category.categoryNameIt.isNotEmpty
            ? category.categoryNameIt
            : category.categoryName)
        : category.categoryName;
  }

  bool get _canUpload =>
      _selectedFile != null &&
      _selectedCategoryId != null &&
      _titleController.text.trim().isNotEmpty &&
      !_controller.isUploading.value;

  Future<void> _handleUpload() async {
    if (!_canUpload) {
      return;
    }

    final title = _titleController.text.trim();

    // Call controller upload method - returns UploadResult (NO side effects)
    final UploadResult result = await _controller.uploadDocument(
      documentFile: _selectedFile!,
      documentTitle: title,
      documentCategoryId: _selectedCategoryId!,
      documentDescription: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    // Handle result - popups shown ONLY here in UI layer
    if (result.status == UploadStatus.success) {
      if (widget.onUpload != null) {
        await widget.onUpload!({
          'file': _selectedFile,
          'fileName': _selectedFileName,
          'fileSize': _selectedFileSize,
          'categoryId': _selectedCategoryId,
          'title': title,
          'description': _descriptionController.text.trim(),
        });
      }

      if (!mounted) return;
      widget.onClose();
      _showSuccessPopup();
    } else {
      // ❌ ERROR - Show error popup, keep dialog open
      _showErrorPopup(result.message);
    }
  }

  void _showSuccessPopup() {
    MessagePopupController.showSuccess(
      messageKey: 'documentUploadSuccess',
      titleKey: 'success',
    );
  }

  void _showErrorPopup(String message) {
    MessagePopupController.showError(
      messageKey: message,
      titleKey: 'error',
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFileUploadArea(),
        SizedBox(height: 12.h),
        _buildSupportedFormatsInfo(),
        SizedBox(height: 14.h),
        _buildDocumentTypeDropdown(),
        SizedBox(height: 12.h),
        _buildTitleField(),
        SizedBox(height: 12.h),
        _buildDescriptionField(),
      ],
    );
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
                  child: _buildFormContent(),
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
                  'addDocument'.tr,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.neutralInk900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  'addDocumentSubtitle'.tr,
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
            onPressed: widget.onClose,
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

  Widget _buildFileUploadArea() {
    return GestureDetector(
      onTap: _selectedFile == null ? _pickFile : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 80.h,
          maxHeight: _selectedFile != null && _isImageFile(_selectedFileName)
              ? 220.h
              : 120.h,
        ),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _selectedFile == null
                ? AppColors.surfaceWarm50
                : AppColors.brandSage50,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: _selectedFile == null
                  ? AppColors.neutralLine200
                  : AppColors.brandSage300,
              width: 2.w,
              style: BorderStyle.solid,
            ),
          ),
          child: _selectedFile == null
              ? _buildUploadPrompt()
              : _buildSelectedFile(),
        ),
      ),
    );
  }

  Widget _buildUploadPrompt() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available height (accounting for padding)
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
                    color: AppColors.brandSage500.withValues(alpha: 0.1),
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
                  'clickToUpload'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk700,
                    fontWeight: FontWeight.w500,
                    fontSize: isCompact ? 13.sp : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCompact) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'dragDropHint'.tr,
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

  Widget _buildSelectedFile() {
    final isImage = _isImageFile(_selectedFileName);
    final fileType = _getFileType(_selectedFileName);

    if (isImage && _selectedFile != null) {
      // Show image preview for image files
      return LayoutBuilder(
        builder: (context, constraints) {
          // Calculate available height (accounting for padding)
          final availableHeight = constraints.maxHeight;
          final fileInfoHeight = 60.h;
          final spacing = 12.h;
          final maxImageHeight = availableHeight - fileInfoHeight - spacing;
          final preferredHeight = 200.h;
          final minImageHeight = 120.h;
          final imageHeight = maxImageHeight > preferredHeight
              ? preferredHeight
              : (maxImageHeight > minImageHeight
                  ? maxImageHeight
                  : minImageHeight);

          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image preview with remove button
                  SizedBox(
                    width: double.infinity,
                    height: imageHeight,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.file(
                            _selectedFile!,
                            width: double.infinity,
                            height: imageHeight,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback if image fails to load
                              return _buildFileDetails(fileType);
                            },
                          ),
                        ),
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _removeFile,
                              icon: Icon(
                                Icons.close,
                                size: 18.sp,
                                color: Colors.white,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(
                                minWidth: 32.w,
                                minHeight: 32.h,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: imageHeight < 150.h ? 8.h : 12.h),
                  // File details below image
                  _buildFileInfoRow(),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Show file details for non-image files
      return LayoutBuilder(
        builder: (context, constraints) {
          // Reduce spacing when height is constrained
          final isConstrained = constraints.maxHeight < 110.h;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isConstrained ? 48.w : 56.w,
                    height: isConstrained ? 48.w : 56.w,
                    decoration: BoxDecoration(
                      color: AppColors.brandSage500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      _getFileIcon(fileType),
                      color: AppColors.brandSage500,
                      size: isConstrained ? 24.sp : 28.sp,
                    ),
                  ),
                  SizedBox(width: isConstrained ? 8.w : 12.w),
                  Expanded(
                    child: _buildFileInfoRow(isConstrained: isConstrained),
                  ),
                  IconButton(
                    onPressed: _removeFile,
                    icon: Icon(Icons.close, size: 20.sp),
                    color: AppColors.neutralInk400,
                    splashRadius: 20.r,
                  ),
                ],
              ),
            ],
          );
        },
      );
    }
  }

  /// Build file info row with name, size, and type
  Widget _buildFileInfoRow({bool isConstrained = false}) {
    final fileType = _getFileType(_selectedFileName);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedFileName ?? '',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutralInk900,
            fontWeight: FontWeight.w600,
            fontSize: isConstrained ? 13.sp : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: isConstrained ? 4.h : 6.h),
        Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          children: [
            _buildInfoChip('fileSize'.tr, _selectedFileSize ?? ''),
            _buildInfoChip('fileType'.tr, fileType),
          ],
        ),
      ],
    );
  }

  /// Build file details widget (fallback for non-image files)
  Widget _buildFileDetails(String fileType) {
    return Container(
      width: double.infinity,
      height: 200.h,
      decoration: BoxDecoration(
        color: AppColors.brandSage500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(fileType),
            color: AppColors.brandSage500,
            size: 48.sp,
          ),
          SizedBox(height: 12.h),
          _buildFileInfoRow(),
        ],
      ),
    );
  }

  /// Get icon based on file type
  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Build info chip widget
  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.neutralLine100,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.neutralInk500,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.neutralInk900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedFormatsInfo() {
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
            'supportedFormats'.tr,
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

  Widget _buildDocumentTypeDropdown() {
    return Obx(() {
      // Show loading state
      if (_controller.isLoadingCategories.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'documentCategories'.tr,
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

      // Show error state
      if (_controller.categories.isEmpty && 
          _controller.errorMessage.value.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'documentCategories'.tr,
              style: AppTextStyles.label.copyWith(
                color: AppColors.neutralInk700,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16.sp,
                    color: AppColors.danger,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'failedToFetchCategories'.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _controller.fetchDocumentCategories(),
                    child: Text(
                      'retry'.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      // Show empty state
      if (_controller.categories.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'documentCategories'.tr,
              style: AppTextStyles.label.copyWith(
                color: AppColors.neutralInk700,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.neutralLine100,
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(color: AppColors.neutralLine200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16.sp,
                    color: AppColors.neutralInk400,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'noCategoriesAvailable'.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutralInk500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      // Show categories dropdown
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'documentCategories'.tr,
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
                    value: _selectedCategoryId,
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
                      'selectType'.tr,
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
                      final localeController = Get.find<LocaleController>();
                      final _ = localeController.locale;
                      return _controller.categories.map((category) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _categoryDisplayName(category),
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.neutralInk900,
                            ),
                          ),
                        );
                      }).toList();
                    },
                    items: _controller.categories.map((category) {
                      final localeController = Get.find<LocaleController>();
                      final _ = localeController.locale;
                      final displayName = _categoryDisplayName(category);
                      final isSelected = category.id == _selectedCategoryId;

                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          child: Text(
                            displayName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.neutralInk900,
                              fontSize: 14.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTitleField() {
    return CustomTextField(
      label: 'title'.tr,
      hint: 'documentTitlePlaceholder'.tr,
      controller: _titleController,
      keyboardType: TextInputType.text,
      backgroundColor: AppColors.neutralLine100,
      borderColor: AppColors.neutralLine200,
      textColor: AppColors.neutralInk900,
      labelColor: AppColors.neutralInk700,
    );
  }

  Widget _buildDescriptionField() {
    return CustomTextField(
      label: '${'description'.tr} (${'optional'.tr})',
      hint: 'documentDescPlaceholder'.tr,
      controller: _descriptionController,
      keyboardType: TextInputType.multiline,
      maxLines: 3,
      backgroundColor: AppColors.neutralLine100,
      borderColor: AppColors.neutralLine200,
      textColor: AppColors.neutralInk900,
      labelColor: AppColors.neutralInk700,
    );
  }

  Widget _buildFooter() {
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
              onPressed: widget.onClose,
              borderColor: AppColors.neutralLine200,
              textColor: AppColors.neutralInk700,
              height: 48.h,
              borderRadius: 12.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ListenableBuilder(
              listenable: _titleController,
              builder: (context, _) {
                return Obx(
                  () => CustomButton(
                    text: 'upload'.tr,
                    icon: Icons.cloud_upload_outlined,
                    onPressed: _canUpload && !_controller.isUploading.value
                        ? _handleUpload
                        : null,
                    isLoading: _controller.isUploading.value,
                    backgroundColor: AppColors.brandSage500,
                    textColor: AppColors.surfaceWhite,
                    height: 48.h,
                    borderRadius: 12.r,
                    showShadow: false,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
