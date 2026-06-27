// presentation/maintenance/views/sections/add_maintenance_task_dialog.dart
import 'dart:io';
import 'package:casazero/app/theme/app_colors.dart';
import 'package:casazero/app/theme/app_text_styles.dart';
import 'package:casazero/core/controllers/message_popup_controller.dart';
import 'package:casazero/core/widgets/custom_text_field.dart';
import 'package:casazero/core/widgets/gradient_button.dart';
import 'package:casazero/core/widgets/outlined_custom_button.dart';
import 'package:casazero/presentation/home/controllers/home_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/utils/accessibility.dart';
import '../../../../core/widgets/responsive_alert_dialog.dart';
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
  bool _isCreating = false;

  // File upload state (stored locally in dialog, matching Document dialog pattern)
  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedFileSize;

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

  /// Pick file using the same approach as Document dialog
  /// This matches the working Document dialog implementation exactly
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
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
          messageKey: 'failed_to_pick_file',
          titleKey: 'error',
        );
      }
    }
  }

  /// Format file size for display (matching Document dialog)
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Remove selected file (matching Document dialog)
  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _selectedFileSize = null;
    });
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
      MessagePopupController.showInfo(
        messageKey: 'please_select_due_date_first',
        titleKey: 'info',
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


  bool get _isFormValid =>
      _titleController.text.isNotEmpty &&
      _selectedCategoryId != null &&
      _selectedFrequency.isNotEmpty &&
      _selectedDueDate != null &&
      _selectedLastMaintenanceDate != null &&
      _homeController.selectedResidence.value != null &&
      !_isCreating;


  Future<void> _handleCreate() async {
    // Validate form before submission
    if (!_formKey.currentState!.validate()) {
      return; // Form validation failed, don't proceed
    }

    // Get residence ID
    final residence = _homeController.selectedResidence.value;
    if (residence == null) {
      MessagePopupController.showError(
        messageKey: 'please_select_residence',
        titleKey: 'error',
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

      // Close dialog only on success (popup is shown in controller)
      if (success && mounted) {
        widget.onClose();
      }
      // On error, dialog stays open (popup shown in controller)
    } catch (e, stackTrace) {
      // Error handling is done in controller, but catch here to prevent crash
      print('❌ Error in dialog: $e');
      print('❌ Stack trace: $stackTrace');
    } finally {
      // Always reset creating state, even on error
      // Check mounted to prevent setState after disposal
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final screenSize = MediaQuery.sizeOf(context);
    final dialogMaxWidth = screenSize.width >= 600
        ? 500.0
        : (screenSize.width - 32.w).clamp(280.w, 500.w);
    final preferredMaxHeight = screenSize.height * 0.9;

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final verticalMargin =
                ResponsiveAlertDialog.overlayFormVerticalMargin(context);
            final maxDialogHeight =
                ResponsiveAlertDialog.overlayFormMaxHeightFromConstraints(
              constraints,
              preferredMaxHeight: preferredMaxHeight,
              verticalMargin: verticalMargin,
            );

            return Align(
              alignment: ResponsiveAlertDialog.overlayFormAlignment(context),
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: verticalMargin,
                ),
                constraints: BoxConstraints(
                  maxWidth: dialogMaxWidth,
                  maxHeight: maxDialogHeight,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm100,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Dialog Header
                    _buildHeader(),

                    // Dialog Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24.w),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title Field
                              _buildTitleField(),
                              SizedBox(height: 16.h),

                              // Category Dropdown
                              _buildCategoryDropdown(),
                              SizedBox(height: 16.h),

                              // Frequency Dropdown
                              _buildFrequencyDropdown(),
                              SizedBox(height: 16.h),

                              // Due Date Field
                              _buildDueDateField(),
                              SizedBox(height: 16.h),

                              // Last Maintenance Date Field (Required)
                              _buildLastMaintenanceDateField(),
                              SizedBox(height: 16.h),

                              // Notes Field
                              _buildNotesField(),
                              SizedBox(height: 16.h),

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
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 5.h, bottom: 5.h, left: 5.w, right: 5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Stack(
        children: [
          /// CENTERED TITLE + SUBTITLE
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 48.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add Maintenance Task',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutralInk900,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Create a personal maintenance task to track',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.neutralInk500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
              constraints: Accessibility.iconButtonConstraints,
              onPressed: widget.onClose,
              icon: Icon(
                Icons.close,
                color: AppColors.neutralInk500,
                size: 22.sp,
              ),
              splashRadius: 22.r,
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
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),

        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _selectedFile == null ? _pickFile : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 100.h,
                maxHeight: 150.h,
              ),
              child: Container(
                padding: EdgeInsets.all(24.w),
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
                    : Center(child: _buildSelectedFile()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadPrompt() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available height (accounting for container padding: 24px top + 24px bottom = 48px)
        // Container has minHeight: 100, so available content height is 100 - 48 = 52px minimum
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
                  'Click to upload',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk700,
                    fontWeight: FontWeight.w500,
                    fontSize: isCompact ? 13.sp : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (!isCompact) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Drag and drop file here',
                    style: AppTextStyles.caption.copyWith(color: AppColors.neutralInk400),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: AppColors.brandSage500.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.insert_drive_file,
            color: AppColors.brandSage500,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 12.w),
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
              SizedBox(height: 2.h),
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
          icon: Icon(Icons.close, size: 20.sp),
          color: AppColors.neutralInk400,
          splashRadius: 20.r,
          constraints: Accessibility.iconButtonConstraints,
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedCategoryId,
                isExpanded: true,
                hint: Text(
                  categories.isEmpty ? 'Loading categories...' : 'Select category',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutralInk400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                icon: Icon(Icons.keyboard_arrow_down, size: 24.sp),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                borderRadius: BorderRadius.circular(25.r),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFrequency.isEmpty ? null : _selectedFrequency,
              isExpanded: true,
              hint: Text(
                'Select frequency',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutralInk400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              icon: Icon(Icons.keyboard_arrow_down, size: 24.sp),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              borderRadius: BorderRadius.circular(25.r),
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
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
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
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm50,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedCustomButton(
              text: 'Cancel',
              onPressed: widget.onClose,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: GradientButton(
              text: _isCreating ? '' : 'Create',
              icon: _isCreating ? null : Icons.add,
              onPressed: _isFormValid ? _handleCreate : null,
              isLoading: _isCreating,
            ),
          ),
        ],
      ),
    );
  }
}
