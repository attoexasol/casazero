// presentation/maintenance/views/sections/add_maintenance_task_dialog.dart
import 'dart:io';
import 'package:casazero/app/theme/app_colors.dart';
import 'package:casazero/app/theme/app_text_styles.dart';
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

  bool get _isFormValid =>
      _titleController.text.isNotEmpty &&
      _selectedCategory.isNotEmpty &&
      _selectedFrequency.isNotEmpty;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
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
    });
  }

  Future<void> _handleCreate() async {
    if (!_isFormValid) return;

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
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 448), // max-w-md
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleInput(),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    _buildFrequencyDropdown(),
                    const SizedBox(height: 16),
                    _buildNotesInput(),
                    const SizedBox(height: 16),
                    _buildFileUpload(),
                  ],
                ),
              ),

              // Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutralLine200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Maintenance Task',
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.neutralInk900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a personal maintenance task to track',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutralInk500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.neutralInk900,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          onChanged: (_) => setState(() {}),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutralInk900,
          ),
          decoration: InputDecoration(
            hintText: 'e.g., Filter replacement',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutralInk400,
            ),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.neutralLine200,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.neutralLine200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.brandSage400,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.neutralInk900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neutralLine200,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCategory.isEmpty ? null : _selectedCategory,
              hint: Text(
                'Select category',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutralInk400,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.neutralInk500,
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutralInk900,
              ),
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              items: _maintenanceCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['value'],
                  child: Text(category['label']!),
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
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.neutralInk900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neutralLine200,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedFrequency.isEmpty ? null : _selectedFrequency,
              hint: Text(
                'Select frequency',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutralInk400,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.neutralInk500,
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutralInk900,
              ),
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              items: _frequencyOptions.map((frequency) {
                return DropdownMenuItem<String>(
                  value: frequency['value'],
                  child: Text(frequency['label']!),
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

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.neutralInk900,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutralInk900,
          ),
          decoration: InputDecoration(
            hintText: 'Add any additional details...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutralInk400,
            ),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.neutralLine200,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.neutralLine200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.brandSage400,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachment (Optional)',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.neutralInk900,
          ),
        ),
        const SizedBox(height: 8),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm50.withOpacity(0.5),
                border: Border.all(
                  color: AppColors.neutralLine200,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedFile != null
                  ? _buildSelectedFile()
                  : _buildFileUploadPlaceholder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadPlaceholder() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.upload_rounded,
          size: 20,
          color: AppColors.neutralInk400,
        ),
        const SizedBox(width: 8),
        Text(
          'Attach file or photo',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutralInk500,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFile() {
    final fileName = _selectedFile!.path.split('/').last;
    final fileSize = _selectedFile!.lengthSync();
    final fileSizeMB = (fileSize / 1024 / 1024).toStringAsFixed(2);

    return Row(
      children: [
        Icon(
          Icons.attach_file_rounded,
          size: 20,
          color: const Color(0xFF6A8F7B),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutralInk900,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$fileSizeMB MB',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.neutralInk500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _removeFile,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.neutralLine200.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.neutralInk700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.neutralLine200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: widget.onClose,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.neutralInk700,
              side: BorderSide(
                color: AppColors.neutralLine200,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.neutralInk700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isFormValid ? _handleCreate : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFormValid
                  ? const Color(0xFF6A8F7B)
                  : AppColors.neutralLine200,
              foregroundColor: _isFormValid
                  ? AppColors.surfaceWhite
                  : AppColors.neutralInk400,
              disabledBackgroundColor: AppColors.neutralLine200,
              disabledForegroundColor: AppColors.neutralInk400,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: _isFormValid
                      ? AppColors.surfaceWhite
                      : AppColors.neutralInk400,
                ),
                const SizedBox(width: 8),
                Text(
                  'Create',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _isFormValid
                        ? AppColors.surfaceWhite
                        : AppColors.neutralInk400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

