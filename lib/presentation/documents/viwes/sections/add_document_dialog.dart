import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/controllers/message_popup_controller.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/outlined_custom_button.dart';
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

  @override
  void initState() {
    super.initState();
    // Add listener to title controller to update button state
    _titleController.addListener(() {
      setState(() {}); // Rebuild to update _canUpload state
    });
    
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
    if (fileName == null) return 'Unknown';
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
      // ✅ SUCCESS - Show success popup and close dialog
      _showSuccessPopup();
      widget.onClose(); // Close dialog
      
      // Call upload callback if provided
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Dialog Header
              _buildHeader(),

              // Dialog Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // File Upload Area
                      _buildFileUploadArea(),
                      const SizedBox(height: 16),

                      // Supported Formats Info
                      _buildSupportedFormatsInfo(),
                      const SizedBox(height: 20),

                      // Document Type Dropdown
                      _buildDocumentTypeDropdown(),
                      const SizedBox(height: 16),

                      // Title Field
                      _buildTitleField(),
                      const SizedBox(height: 16),

                      // Description Field
                      _buildDescriptionField(),
                    ],
                  ),
                ),
              ),

              // Dialog Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(
        top: 5, // 🔥 extra top padding (matches screenshot)
        bottom: 5,
        left: 5,
        right: 5,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          /// CENTERED TITLE + SUBTITLE
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'addDocument'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutralInk900,
                    ),
                  ),
                  const SizedBox(height: 4), // 🔥 exact spacing from screenshot
                  Text(
                    'Upload a personal document to your collection',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutralInk500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// CLOSE BUTTON — TOP RIGHT
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: widget.onClose,
              icon: Icon(Icons.close, color: AppColors.neutralInk500),
              splashRadius: 22,
            ),
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
          minHeight: 100,
          maxHeight: _selectedFile != null && _isImageFile(_selectedFileName)
              ? 300 // More height for image preview
              : 150,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _selectedFile == null
                ? AppColors.surfaceWarm50
                : AppColors.brandSage50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedFile == null
                  ? AppColors.neutralLine200
                  : AppColors.brandSage300,
              width: 2,
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
                  'clickToUpload'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk700,
                    fontWeight: FontWeight.w500,
                    fontSize: isCompact ? 13 : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 4),
                  Text(
                    'dragDropHint'.tr,
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

  Widget _buildSelectedFile() {
    final isImage = _isImageFile(_selectedFileName);
    final fileType = _getFileType(_selectedFileName);

    if (isImage && _selectedFile != null) {
      // Show image preview for image files
      return LayoutBuilder(
        builder: (context, constraints) {
          // Calculate available height (accounting for padding: 24px top + 24px bottom = 48px)
          final availableHeight = constraints.maxHeight;
          // Reserve space for file info row (approximately 50-60px) and spacing (12px)
          final fileInfoHeight = 60.0;
          final spacing = 12.0;
          final maxImageHeight = availableHeight - fileInfoHeight - spacing;
          // Use adaptive height: prefer 200px, but reduce if needed, minimum 120px
          final imageHeight = maxImageHeight > 200
              ? 200.0
              : (maxImageHeight > 120 ? maxImageHeight : 120.0);

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
                          borderRadius: BorderRadius.circular(12),
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
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _removeFile,
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.white,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: imageHeight < 150 ? 8 : 12),
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
          final isConstrained = constraints.maxHeight < 110;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isConstrained ? 48 : 56,
                    height: isConstrained ? 48 : 56,
                    decoration: BoxDecoration(
                      color: AppColors.brandSage500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getFileIcon(fileType),
                      color: AppColors.brandSage500,
                      size: isConstrained ? 24 : 28,
                    ),
                  ),
                  SizedBox(width: isConstrained ? 8 : 12),
                  Expanded(
                    child: _buildFileInfoRow(isConstrained: isConstrained),
                  ),
                  IconButton(
                    onPressed: _removeFile,
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.neutralInk400,
                    splashRadius: 20,
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
            fontSize: isConstrained ? 13 : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: isConstrained ? 4 : 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildInfoChip('Size', _selectedFileSize ?? ''),
            _buildInfoChip('Type', fileType),
          ],
        ),
      ],
    );
  }

  /// Build file details widget (fallback for non-image files)
  Widget _buildFileDetails(String fileType) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.brandSage500.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getFileIcon(fileType), color: AppColors.brandSage500, size: 48),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutralLine100,
        borderRadius: BorderRadius.circular(8),
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
        Icon(Icons.info_outline, size: 16, color: AppColors.neutralInk400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'supportedFormats'.tr,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.neutralInk500,
            ),
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
              'Document Categories'.tr,
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

      // Show error state
      if (_controller.categories.isEmpty && 
          _controller.errorMessage.value.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Categories'.tr,
              style: AppTextStyles.label.copyWith(
                color: AppColors.neutralInk700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, 
                    size: 16, 
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to load categories',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _controller.fetchDocumentCategories(),
                    child: Text(
                      'Retry',
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
              'Document Categories'.tr,
              style: AppTextStyles.label.copyWith(
                color: AppColors.neutralInk700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neutralLine100,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.neutralLine200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, 
                    size: 16, 
                    color: AppColors.neutralInk400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No categories available',
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
            'Document Categories'.tr,
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedCategoryId,
                isExpanded: true,
                hint: Text(
                  'selectType'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk400,
                  ),
                ),
                icon: const Icon(Icons.keyboard_arrow_down),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                borderRadius: BorderRadius.circular(25),
                items: _controller.categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(
                      category.categoryName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neutralInk900,
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
      height: 60,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: OutlinedCustomButton(
              text: 'cancel'.tr,
              onPressed: widget.onClose,
              width: 100,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => GradientButton(
              text: 'upload'.tr,
              icon: Icons.upload,
              onPressed: _canUpload && !_controller.isUploading.value ? _handleUpload : null,
              isLoading: _controller.isUploading.value,
              width: 140,
            )),
          ),
        ],
      ),
    );
  }
}
