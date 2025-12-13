import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/outlined_custom_button.dart';

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

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _selectedFileSize = null;
    });
  }

  bool get _canUpload =>
      _selectedFile != null && _selectedDocumentType != null && !_isUploading;

  Future<void> _handleUpload() async {
    if (!_canUpload) return;

    setState(() => _isUploading = true);

    try {
      // Prepare document data
      final documentData = {
        'file': _selectedFile,
        'fileName': _selectedFileName,
        'fileSize': _selectedFileSize,
        'type': _selectedDocumentType,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      // Call the upload callback
      if (widget.onUpload != null) {
        await widget.onUpload!(documentData);
      }

      if (mounted) {
        Get.snackbar(
          'success'.tr,
          'documentUploadSuccess'.tr,
          backgroundColor: AppColors.success,
          colorText: AppColors.surfaceWhite,
        );
        widget.onClose();
      }
    } catch (e) {
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
        constraints: const BoxConstraints(minHeight: 100, maxHeight: 150),
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
          child: FittedBox(
            fit: BoxFit.scaleDown, // 🔥 prevents overflow
            alignment: Alignment.center,
            child: _selectedFile == null
                ? _buildUploadPrompt()
                : _buildSelectedFile(),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPrompt() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.brandSage500.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            size: 32,
            color: AppColors.brandSage500,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'clickToUpload'.tr,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutralInk700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'dragDropHint'.tr,
          style: AppTextStyles.caption.copyWith(color: AppColors.neutralInk400),
        ),
      ],
    );
  }

  Widget _buildSelectedFile() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.brandSage500.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.insert_drive_file,
            color: AppColors.brandSage500,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedFileName ?? '',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutralInk900,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _selectedFileSize ?? '',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.neutralInk500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _removeFile,
          icon: const Icon(Icons.close, size: 20),
          color: AppColors.neutralInk400,
          splashRadius: 20,
        ),
      ],
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
              text: _isUploading ? '' : 'upload'.tr, // hide text if needed
              icon: _isUploading ? null : Icons.upload,
              onPressed: _canUpload ? _handleUpload : null,
              width: 140,
              child: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.surfaceWhite,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
