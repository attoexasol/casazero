import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLength;
  final TextAlign textAlign;
  final int? maxLines;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? labelColor;
  final bool enabled;

  const CustomTextField({
    Key? key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.labelColor,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: labelColor ?? AppColors.surfaceWhite.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          maxLength: maxLength,
          maxLines: maxLines,
          textAlign: textAlign,
          enabled: enabled,
          readOnly: !enabled,
          style: AppTextStyles.bodyMedium.copyWith(
            color: enabled
                ? (textColor ?? AppColors.neutralInk900)
                : AppColors.neutralInk400,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutralInk400,
            ),
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            counterText: '',
            filled: true,
            fillColor: enabled
                ? (backgroundColor ?? AppColors.surfaceWhite.withOpacity(0.9))
                : AppColors.neutralLine100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(
                color: enabled
                    ? (borderColor ?? AppColors.surfaceWhite.withOpacity(0.4))
                    : AppColors.neutralLine200,
                width: 1,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(
                color: AppColors.neutralLine200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(
                color: AppColors.brandSage500,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: AppColors.danger, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: AppColors.danger, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
