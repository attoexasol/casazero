import 'package:casazero/core/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PasswordInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final RxBool isVisible;
  final VoidCallback onToggle;
  final Function(String)? onSubmitted;

  const PasswordInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.isVisible,
    required this.onToggle,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => CustomTextField(
        label: label,
        hint: '••••••••',
        controller: controller,
        obscureText: !isVisible.value,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        borderColor: Colors.white.withValues(alpha: 0.4),
        textColor: const Color(0xFF1A1A1A),

        suffixIcon: IconButton(
          icon: Icon(
            isVisible.value ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
          ),
          onPressed: onToggle,
        ),

        onSubmitted: onSubmitted,
      ),
    );
  }
}
