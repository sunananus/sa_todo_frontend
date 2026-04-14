// lib/features/home/widgets/quick_add_bar.dart
// 底部快速添加栏

import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_container.dart';

class QuickAddBar extends StatefulWidget {
  final Function(String title) onSubmit;

  const QuickAddBar({super.key, required this.onSubmit});

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmit(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);

    return GlassContainer(
      borderRadius: 0,
      showBorder: false,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              // 添加按钮
              GestureDetector(
                onTap: () {
                  setState(() => _isExpanded = !_isExpanded);
                  if (_isExpanded) _focusNode.requestFocus();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isExpanded ? CupertinoIcons.minus : CupertinoIcons.add,
                    color: CupertinoColors.white,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 输入框
              Expanded(
                child: CupertinoTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  placeholder: '快速添加任务...',
                  onSubmitted: (_) => _submit(),
                  textInputAction: TextInputAction.done,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary(brightness),
                  ),
                  placeholderStyle: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary(brightness)
                        .withValues(alpha: 0.5),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface(brightness).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // 发送按钮
              if (_controller.text.isNotEmpty || _isExpanded) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submit,
                  child: Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    color: AppColors.primary(brightness),
                    size: 32,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
