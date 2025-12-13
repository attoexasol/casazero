// presentation/maintenance/views/sections/add_maintenance_task_dialog.dart
import 'dart:io';
import 'package:casazero/app/theme/app_colors.dart';
import 'package:casazero/app/theme/app_text_styles.dart';
import 'package:casazero/core/widgets/custom_text_field.dart';
import 'package:casazero/core/widgets/gradient_button.dart';
import 'package:casazero/core/widgets/outlined_custom_button.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../../controllers/maintenance_controller.dart';

class AddMaintenanceTaskDialog extends StatefulWidget {
  final VoidCallback onClose;

  const AddMaintenanceTaskDialog({
    super.key,
    required this.onClose,
  });

  @override
  State<AddMaintenanceTaskDialog> createState() =>
      _AddMaintenanceTaskDialogState();
}

class _AddMaintenanceTaskDialogState extends State<AddMaintenanceTaskDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = '';
  String _selectedFrequency = '';
  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedFileSize;
  bool _isCreating = false;

  final MaintenanceController _controller = Get.find<MaintenanceController>();

  // Categories - Matching React exactly
  final List<Map<String, String>> _maintenanceCategories = [
    {'value': 'appliances', 'label': 'Appliances'},
    {'value': 'hvac', 'label': 'HVAC'},
    {'value': 'plumbing', 'label': 'Plumbing'},
    {'value': 'electrical', 'label': 'Electrical'},
    {'value': 'cleaning', 'label': 'Cleaning'},
    {'value': 'other', 'label': 'Other'},
  ];

  // Frequency options - Matching React exactly
  final List<Map<String, String>> _frequencyOptions = [
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'quarterly', 'label': 'Quarterly'},
    {'value': 'biannually', 'label': 'Every 6 months'},
    {'value': 'annually', 'label': 'Annually'},
    {'value': 'custom', 'label': 'Custom'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get _isFormValid =>
      _titleController.text.isNotEmpty &&
      _selectedCategory.isNotEmpty &&
      _selectedFrequency.isNotEmpty &&
      !_isCreating;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
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
      print('Error picking file: $e');
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to pick file',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger,
          colorText: AppColors.surfaceWhite,
        );
      }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _selectedFileSize = null;
    });
  }

  Future<void> _handleCreate() async {
    if (!_isFormValid) return;

    setState(() => _isCreating = true);

    try {
      await _controller.createMaintenanceTask(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        frequency: _selectedFrequency,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        attachment: _selectedFile,
      );

      if (mounted) {
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to create maintenance task',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger,
          colorText: AppColors.surfaceWhite,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
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
            color: AppColors.surfaceWhite,
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

                      // Title Field
                      _buildTitleField(),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      _buildCategoryDropdown(),
                      const SizedBox(height: 16),

                      // Frequency Dropdown
                      _buildFrequencyDropdown(),
                      const SizedBox(height: 16),

                      // Notes Field
                      _buildNotesField(),
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
        top: 18,
        bottom: 14,
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
        alignment: Alignment.center,
        children: [
          /// CENTERED TITLE + SUBTITLE
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Maintenance Task',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutralInk900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create a personal maintenance task to track',
                style: TextStyle(fontSize: 12, color: AppColors.neutralInk500),
              ),
            ],
          ),

          const Spacer(),

          /// CLOSE BUTTON — TOP RIGHT
          Positioned(
            right: 10,
            top: 10,
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
            fit: BoxFit.scaleDown,
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
          'Click to upload',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutralInk700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Drag and drop file here',
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
            'Supported formats: PDF, JPG, JPEG, PNG',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.neutralInk500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return CustomTextField(
      label: 'Title',
      hint: 'e.g., Filter replacement',
      controller: _titleController,
      keyboardType: TextInputType.text,
      backgroundColor: AppColors.neutralLine100,
      borderColor: AppColors.neutralLine200,
      textColor: AppColors.neutralInk900,
      labelColor: AppColors.neutralInk700,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
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
              value: _selectedCategory.isEmpty ? null : _selectedCategory,
              isExpanded: true,
              hint: Text(
                'Select category',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutralInk400,
                ),
              ),
              icon: const Icon(Icons.keyboard_arrow_down),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(25),
              items: _maintenanceCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['value'],
                  child: Text(
                    category['label']!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutralInk900,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? '';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
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
              value: _selectedFrequency.isEmpty ? null : _selectedFrequency,
              isExpanded: true,
              hint: Text(
                'Select frequency',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutralInk400,
                ),
              ),
              icon: const Icon(Icons.keyboard_arrow_down),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(25),
              items: _frequencyOptions.map((frequency) {
                return DropdownMenuItem<String>(
                  value: frequency['value'],
                  child: Text(
                    frequency['label']!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutralInk900,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value ?? '';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return CustomTextField(
      label: 'Notes (Optional)',
      hint: 'Add any additional details...',
      controller: _notesController,
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
              text: 'Cancel',
              onPressed: widget.onClose,
              width: 100,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GradientButton(
              text: _isCreating ? '' : 'Create',
              icon: _isCreating ? null : Icons.add,
              onPressed: _isFormValid ? _handleCreate : null,
              width: 140,
              isLoading: _isCreating,
            ),
          ),
        ],
      ),
    );
  }
}
