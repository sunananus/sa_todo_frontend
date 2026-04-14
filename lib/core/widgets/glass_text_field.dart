// lib/core/widgets/glass_text_field.dart
// 毛玻璃风格输入框

import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final int maxLines;
  final bool autofocus;
  final Widget? prefix;
  final Widget? suffix;

  const GlassTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.maxLines = 1,
    this.autofocus = false,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return CupertinoTextField(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      maxLines: maxLines,
      autofocus: autofocus,
      prefix: prefix,
      suffix: suffix,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      style: AppTextStyles.body.copyWith(
        color: AppColors.textPrimary(brightness),
      ),
      placeholderStyle: AppTextStyles.body.copyWith(
        color: AppColors.textSecondary(brightness).withValues(alpha: 0.6),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.separator(brightness).withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
    );
  }
}
