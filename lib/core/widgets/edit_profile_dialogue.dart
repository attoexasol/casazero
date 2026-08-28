import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_shadows.dart';
import '../../core/controllers/message_popup_controller.dart';
import '../../presentation/profile/controllers/profile_controller.dart';
import 'custom_text_field.dart';
import 'custom_button.dart';
import 'outlined_custom_button.dart';
import 'responsive_alert_dialog.dart';

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final ProfileController _profileController = Get.find<ProfileController>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  double? _dialogMaxHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dialogMaxHeight ??= MediaQuery.sizeOf(context).height * 0.72;
  }

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current user data
    final user = _profileController.user.value;
    if (user != null) {
      // Split the userName into first and last name
      final nameParts = user.userName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      _firstNameController = TextEditingController(text: firstName);
      _lastNameController = TextEditingController(text: lastName);
      _emailController = TextEditingController(text: user.email);
      _phoneController = TextEditingController(text: user.phone);
    } else {
      _firstNameController = TextEditingController();
      _lastNameController = TextEditingController();
      _emailController = TextEditingController();
      _phoneController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // Combine first and last name
    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();
    // Email is disabled, so use the original email from user object
    final user = _profileController.user.value;
    final email = user?.email ?? _emailController.text.trim();
    final phone = _phoneController.text.trim();

    // Validate inputs
    if (fullName.isEmpty) {
      MessagePopupController.showError(
        messageKey: 'please_enter_your_name',
        titleKey: 'error',
      );
      return;
    }

    if (email.isEmpty) {
      MessagePopupController.showError(
        messageKey: 'please_enter_email',
        titleKey: 'error',
      );
      return;
    }

    if (phone.isEmpty) {
      MessagePopupController.showError(
        messageKey: 'please_enter_phone_number',
        titleKey: 'error',
      );
      return;
    }

    // Capture navigator before async so we can pop the dialog after success
    final navigator = Navigator.of(context);

    // Call the controller to update user info
    final success = await _profileController.updateUserInfo(
      userName: fullName,
      email: email,
      phone: phone,
    );

    // Close dialog on success - pop in next frame so snackbar doesn't block
    if (success && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          navigator.pop();
        }
      });
    }
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
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: AppShadows.shadowXl,
          ),
          child: Column(
            mainAxisSize:
                ResponsiveAlertDialog.formDialogMainAxisSize(context),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              _buildHeader(),

              // Dialog Content
              ResponsiveAlertDialog.formDialogScrollBody(
                context: context,
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      // First Name Field
                      CustomTextField(
                        label: 'first_name'.tr,
                        controller: _firstNameController,
                        keyboardType: TextInputType.name,
                        backgroundColor: AppColors.neutralLine100,
                        borderColor: AppColors.neutralLine200,
                        textColor: AppColors.neutralInk900,
                        labelColor: AppColors.neutralInk700,
                      ),
                      SizedBox(height: 16.h),

                      // Last Name Field
                      CustomTextField(
                        label: 'last_name'.tr,
                        controller: _lastNameController,
                        keyboardType: TextInputType.name,
                        backgroundColor: AppColors.neutralLine100,
                        borderColor: AppColors.neutralLine200,
                        textColor: AppColors.neutralInk900,
                        labelColor: AppColors.neutralInk700,
                      ),
                      SizedBox(height: 16.h),

                      // Email Field (Disabled - cannot be changed)
                      CustomTextField(
                        label: 'email'.tr,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        backgroundColor: AppColors.neutralLine100,
                        borderColor: AppColors.neutralLine200,
                        textColor: AppColors.neutralInk900,
                        labelColor: AppColors.neutralInk700,
                        enabled: false, // Email field is disabled
                      ),
                      SizedBox(height: 16.h),

                      // Phone Number Field
                      CustomTextField(
                        label: 'phone_number'.tr,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        backgroundColor: AppColors.neutralLine100,
                        borderColor: AppColors.neutralLine200,
                        textColor: AppColors.neutralInk900,
                        labelColor: AppColors.neutralInk700,
                      ),
                    ],
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
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.neutralLine100, width: 1.w),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'edit_profile'.tr,
            style: AppTextStyles.h4.copyWith(color: AppColors.neutralInk900),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            'update_personal_info'.tr,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutralInk500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.neutralLine100, width: 1.w),
        ),
      ),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            child: OutlinedCustomButton(
              text: 'cancel'.tr,
              onPressed: () => Navigator.of(context).pop(),
              borderColor: AppColors.neutralInk300,
              textColor: AppColors.neutralInk700,
            ),
          ),
          SizedBox(width: 10.w),

          // Save Button
          Expanded(
            child: Obx(() {
              return CustomButton(
                text: 'save_changes'.tr,
                onPressed: _handleSave,
                isLoading: _profileController.isSaving.value,
                backgroundColor: AppColors.brandSage500,
                textColor: AppColors.surfaceWhite,
              );
            }),
          ),
        ],
      ),
    );
  }
}
