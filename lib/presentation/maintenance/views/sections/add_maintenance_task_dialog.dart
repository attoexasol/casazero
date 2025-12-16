// presentation/maintenance/views/sections/add_maintenance_task_dialog.dart
import 'dart:io';
import 'package:casazero/app/theme/app_colors.dart';
import 'package:casazero/app/theme/app_text_styles.dart';
import 'package:casazero/core/widgets/custom_text_field.dart';
import 'package:casazero/core/widgets/gradient_button.dart';
import 'package:casazero/core/widgets/outlined_custom_button.dart';
import 'package:casazero/presentation/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/maintenance_controller.dart';
import '../../models/maintenance_category_model.dart';

class AddMaintenanceTaskDialog extends StatefulWidget {
  final VoidCallback onClose;

  const AddMaintenanceTaskDialog({super.key, required this.onClose});

  @override
  State<AddMaintenanceTaskDialog> createState() =>
      _AddMaintenanceTaskDialogState();
}

class _AddMaintenanceTaskDialogState extends State<AddMaintenanceTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _lastMaintenanceDateController = TextEditingController();

  int? _selectedCategoryId; // Category ID from API
  String _selectedFrequency = '';
  DateTime? _selectedDueDate;
  DateTime? _selectedLastMaintenanceDate;
  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedFileSize;
  bool _isCreating = false;

  final MaintenanceController _controller = Get.find<MaintenanceController>();
  final HomeController _homeController = Get.find<HomeController>();

  // Frequency options - Matching API format
  final List<Map<String, String>> _frequencyOptions = [
    {'value': 'Weekly', 'label': 'Weekly'},
    {'value': 'Monthly', 'label': 'Monthly'},
    {'value': 'Quarterly', 'label': 'Quarterly'},
    {'value': 'Every 6 months', 'label': 'Every 6 months'},
    {'value': 'Annually', 'label': 'Annually'},
    {'value': 'Custom', 'label': 'Custom'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _dueDateController.dispose();
    _lastMaintenanceDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _selectDueDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? today,
      firstDate: today, // Due date must be >= today
      lastDate: today.add(const Duration(days: 365 * 5)), // 5 years from now
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text = _formatDate(picked);
        // If last maintenance date is after due date, clear it
        if (_selectedLastMaintenanceDate != null &&
            _selectedLastMaintenanceDate!.isAfter(picked)) {
          _selectedLastMaintenanceDate = null;
          _lastMaintenanceDateController.clear();
        }
        // Trigger validation
        _formKey.currentState?.validate();
      });
    }
  }

  Future<void> _selectLastMaintenanceDate() async {
    // Require due date to be selected first
    if (_selectedDueDate == null) {
      Get.snackbar(
        'Info',
        'Please select due date first',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange[700],
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final DateTime today = DateTime.now();
    final DateTime maxDate = _selectedDueDate!; // Use due date as max date
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedLastMaintenanceDate ?? maxDate.subtract(const Duration(days: 30)),
      firstDate: today.subtract(const Duration(days: 365 * 5)), // 5 years ago
      lastDate: maxDate, // Last maintenance date must be <= due date
    );
    if (picked != null) {
      setState(() {
        _selectedLastMaintenanceDate = picked;
        _lastMaintenanceDateController.text = _formatDate(picked);
        // Trigger validation
        _formKey.currentState?.validate();
      });
    }
  }

  String? _validateDueDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Due date is required';
    }
    if (_selectedDueDate == null) {
      return 'Please select a due date';
    }
    final DateTime today = DateTime.now();
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    final DateTime selectedOnly = DateTime(
      _selectedDueDate!.year,
      _selectedDueDate!.month,
      _selectedDueDate!.day,
    );
    if (selectedOnly.isBefore(todayOnly)) {
      return 'Due date must be today or later';
    }
    return null;
  }

  String? _validateLastMaintenanceDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Last maintenance date is required';
    }
    if (_selectedLastMaintenanceDate == null) {
      return 'Please select a last maintenance date';
    }
    if (_selectedDueDate == null) {
      return 'Please select due date first';
    }
    final DateTime dueDateOnly = DateTime(
      _selectedDueDate!.year,
      _selectedDueDate!.month,
      _selectedDueDate!.day,
    );
    final DateTime lastMaintenanceOnly = DateTime(
      _selectedLastMaintenanceDate!.year,
      _selectedLastMaintenanceDate!.month,
      _selectedLastMaintenanceDate!.day,
    );
    if (lastMaintenanceOnly.isAfter(dueDateOnly)) {
      return 'Last maintenance date must be before or equal to due date';
    }
    return null;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get _isFormValid =>
      _titleController.text.isNotEmpty &&
      _selectedCategoryId != null &&
      _selectedFrequency.isNotEmpty &&
      _selectedDueDate != null &&
      _selectedLastMaintenanceDate != null &&
      _homeController.selectedResidence.value != null &&
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
    // Validate form before submission
    if (!_formKey.currentState!.validate()) {
      return; // Form validation failed, don't proceed
    }

    // Get residence ID
    final residence = _homeController.selectedResidence.value;
    if (residence == null) {
      Get.snackbar(
        'Error',
        'Please select a residence',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final success = await _controller.createMaintenanceTask(
        title: _titleController.text.trim(),
        categoryId: _selectedCategoryId!,
        frequency: _selectedFrequency,
        dueDate: _formatDate(_selectedDueDate!),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        lastMaintenanceDate: _formatDate(_selectedLastMaintenanceDate!),
        residenceId: residence.id,
      );

      // Close dialog only on success (snackbar is shown in controller)
      if (success && mounted) {
        widget.onClose();
      }
      // On error, dialog stays open (snackbar shown in controller)
    } catch (e) {
      // Error handling is done in controller, but catch here to prevent crash
      print('Error in dialog: $e');
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title Field
                        _buildTitleField(),
                        const SizedBox(height: 16),

                        // Category Dropdown
                        _buildCategoryDropdown(),
                        const SizedBox(height: 16),

                        // Frequency Dropdown
                        _buildFrequencyDropdown(),
                        const SizedBox(height: 16),

                        // Due Date Field
                        _buildDueDateField(),
                        const SizedBox(height: 16),

                        // Last Maintenance Date Field (Required)
                        _buildLastMaintenanceDateField(),
                        const SizedBox(height: 16),

                        // Notes Field
                        _buildNotesField(),
                        const SizedBox(height: 16),

                        // File Upload Area
                        _buildFileUploadArea(),
                      ],
                    ),
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
      padding: const EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 5),
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
                    'Add Maintenance Task',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutralInk900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create a personal maintenance task to track',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachment(Optional)',
          style: AppTextStyles.label.copyWith(
            color: AppColors.neutralInk700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: _selectedFile == null ? _pickFile : null,
          child: SizedBox(
            width: double.infinity,
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
          ),
        ),
      ],
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
    return Obx(() {
      final categories = _controller.categories;
      
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
              child: DropdownButton<int>(
                value: _selectedCategoryId,
                isExpanded: true,
                hint: Text(
                  categories.isEmpty ? 'Loading categories...' : 'Select category',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk400,
                  ),
                ),
                icon: const Icon(Icons.keyboard_arrow_down),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                borderRadius: BorderRadius.circular(25),
                items: categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(
                      category.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neutralInk900,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: categories.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
              ),
            ),
          ),
        ],
      );
    });
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

  Widget _buildDueDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date',
          style: AppTextStyles.label.copyWith(
            color: AppColors.neutralInk700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          label: '',
          hint: 'Select due date',
          controller: _dueDateController,
          keyboardType: TextInputType.none,
          backgroundColor: AppColors.neutralLine100,
          borderColor: AppColors.neutralLine200,
          textColor: AppColors.neutralInk900,
          labelColor: AppColors.neutralInk700,
          enabled: true,
          readOnly: true,
          onTap: _selectDueDate,
          validator: _validateDueDate,
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today, color: AppColors.brandSage500),
            onPressed: _selectDueDate,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildLastMaintenanceDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last Maintenance Date',
          style: AppTextStyles.label.copyWith(
            color: AppColors.neutralInk700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          label: '',
          hint: 'Select last maintenance date',
          controller: _lastMaintenanceDateController,
          keyboardType: TextInputType.none,
          backgroundColor: AppColors.neutralLine100,
          borderColor: AppColors.neutralLine200,
          textColor: AppColors.neutralInk900,
          labelColor: AppColors.neutralInk700,
          enabled: true,
          readOnly: true,
          onTap: _selectLastMaintenanceDate,
          validator: _validateLastMaintenanceDate,
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today, color: AppColors.brandSage500),
            onPressed: _selectLastMaintenanceDate,
          ),
          onChanged: (_) => setState(() {}),
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
