import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/outlined_custom_button.dart';
import '../../controllers/documents_controller.dart';

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

  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedFileSize;
  String? _selectedDocumentType;
  bool _isUploading = false;

  // Document types matching React version
  final List<Map<String, String>> _documentTypes = [
    {'value': 'ownership_legal', 'label': 'ownershipLegal'},
    {'value': 'technical_building', 'label': 'technicalBuilding'},
    {'value': 'energy_environmental', 'label': 'energyEnvironmental'},
    {'value': 'compliance_safety', 'label': 'complianceSafety'},
    {
      'value': 'administrative_maintenance',
      'label': 'administrativeMaintenance',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Add listener to title controller to update button state
    _titleController.addListener(() {
      setState(() {}); // Rebuild to update _canUpload state
    });
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
        Get.snackbar(
          'error'.tr,
          'filePickError'.tr,
          backgroundColor: AppColors.danger,
          colorText: AppColors.surfaceWhite,
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
      _selectedDocumentType != null &&
      _titleController.text.trim().isNotEmpty &&
      !_isUploading;

  Future<void> _handleUpload() async {
    print('🔵 [AddDocumentDialog] _handleUpload() called');
    print('🔵 [AddDocumentDialog] _canUpload: $_canUpload');
    print('🔵 [AddDocumentDialog] File: ${_selectedFile != null ? _selectedFile!.path : "null"}');
    print('🔵 [AddDocumentDialog] Type: $_selectedDocumentType');
    print('🔵 [AddDocumentDialog] Title: ${_titleController.text.trim()}');
    
    if (!_canUpload) {
      print('❌ [AddDocumentDialog] Cannot upload - validation failed');
      return;
    }

    setState(() => _isUploading = true);
    print('⏳ [AddDocumentDialog] Starting upload...');

    try {
      // Get the document title (already validated by _canUpload)
      final title = _titleController.text.trim();

      // Get DocumentsController
      print('📞 [AddDocumentDialog] Getting DocumentsController...');
      final documentsController = Get.find<DocumentsController>();
      print('✅ [AddDocumentDialog] DocumentsController found');

      // Call the upload method
      final result = await documentsController.uploadDocument(
        documentFile: _selectedFile!,
        documentTitle: title,
        documentType: _selectedDocumentType!,
        documentDescription: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          // Show success toast
          Get.snackbar(
            '',
            result['message'] ?? 'documentUploadSuccess'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.brandSage600,
            colorText: AppColors.surfaceWhite,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            borderRadius: 12,
            duration: const Duration(seconds: 2),
            icon: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            shouldIconPulse: false,
            isDismissible: true,
          );

          // Close dialog on success
          widget.onClose();

          // Call the upload callback if provided (for any additional handling)
          if (widget.onUpload != null) {
            await widget.onUpload!({
              'file': _selectedFile,
              'fileName': _selectedFileName,
              'fileSize': _selectedFileSize,
              'type': _selectedDocumentType,
              'title': title,
              'description': _descriptionController.text.trim(),
            });
          }
        } else {
          Get.snackbar(
            'error'.tr,
            result['error'] ?? 'documentUploadError'.tr,
            backgroundColor: AppColors.danger,
            colorText: AppColors.surfaceWhite,
          );
        }
      }
    } catch (e) {
      print('❌ [AddDocumentDialog] Error uploading: $e');
      if (mounted) {
        Get.snackbar(
          'error'.tr,
          'documentUploadError'.tr,
          backgroundColor: AppColors.danger,
          colorText: AppColors.surfaceWhite,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
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
                    style: TextStyle(fontSize: 12, color: AppColors.neutralInk500),
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
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
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
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview with remove button
          SizedBox(
            width: double.infinity,
            height: 200,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedFile!,
                    width: double.infinity,
                    height: 200,
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
                      icon: const Icon(Icons.close, size: 18, color: Colors.white),
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
          const SizedBox(height: 12),
          // File details below image
          _buildFileInfoRow(),
        ],
      );
    } else {
      // Show file details for non-image files
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.brandSage500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getFileIcon(fileType),
                  color: AppColors.brandSage500,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFileInfoRow(),
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
    }
  }

  /// Build file info row with name, size, and type
  Widget _buildFileInfoRow() {
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
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
          Icon(
            _getFileIcon(fileType),
            color: AppColors.brandSage500,
            size: 48,
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'documentType'.tr,
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
            child: DropdownButton<String>(
              value: _selectedDocumentType,
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
              items: _documentTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(
                    type['label']!.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutralInk900,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDocumentType = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return CustomTextField(
      label: '${'title'.tr} (${'optional'.tr})',
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
            child: GradientButton(
              text: 'upload'.tr,
              icon: Icons.upload,
              onPressed: _canUpload ? _handleUpload : null,
              isLoading: _isUploading,
              width: 140,
            ),
          ),
        ],
      ),
    );
  }
}
