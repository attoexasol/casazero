import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_shadows.dart';
import '../../presentation/profile/controllers/profile_controller.dart';
import 'custom_text_field.dart';
import 'custom_button.dart';
import 'outlined_custom_button.dart';

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({Key? key}) : super(key: key);

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final ProfileController _profileController = Get.find<ProfileController>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

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
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    // Validate inputs
    if (fullName.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'please_enter_your_name'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (email.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'please_enter_email'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      Get.snackbar(
        'error'.tr,
        'please_enter_valid_email'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (phone.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'please_enter_phone_number'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    // Call the controller to update user info
    final success = await _profileController.updateUserInfo(
      userName: fullName,
      email: email,
      phone: phone,
    );

    // Close dialog immediately on success
    if (success) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.shadowXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            _buildHeader(),

            // Dialog Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 16),

                    // Email Field
                    CustomTextField(
                      label: 'email'.tr,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      backgroundColor: AppColors.neutralLine100,
                      borderColor: AppColors.neutralLine200,
                      textColor: AppColors.neutralInk900,
                      labelColor: AppColors.neutralInk700,
                    ),
                    const SizedBox(height: 16),

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
            ),

            // Dialog Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.neutralLine100, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'edit_profile'.tr,
            style: AppTextStyles.h4.copyWith(color: AppColors.neutralInk900),
          ),
          const SizedBox(height: 4),
          Text(
            'update_personal_info'.tr,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutralInk500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.neutralLine100, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel Button
          Expanded(
            child: OutlinedCustomButton(
              text: 'cancel'.tr,
              onPressed: () => Navigator.of(context).pop(),
              borderColor: AppColors.neutralInk300,
              textColor: AppColors.neutralInk700,
              height: 44,
            ),
          ),
          const SizedBox(width: 10),

          // Save Button
          Expanded(
            child: Obx(() {
              return CustomButton(
                text: 'save_changes'.tr,
                onPressed: _handleSave,
                isLoading: _profileController.isSaving.value,
                backgroundColor: AppColors.brandSage500,
                textColor: AppColors.surfaceWhite,
                height: 44,
                width: 10,
              );
            }),
          ),
        ],
      ),
    );
  }
}
