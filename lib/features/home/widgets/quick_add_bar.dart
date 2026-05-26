// lib/features/home/widgets/quick_add_bar.dart
// 底部快速添加栏

import 'package:flutter/cupertino.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_container.dart';

class QuickAddBar extends StatefulWidget {
  final Function(String title) onSubmit;
  final bool initialExpanded;

  const QuickAddBar({
    super.key,
    required this.onSubmit,
    this.initialExpanded = false,
  });

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
    _isExpanded = widget.initialExpanded;
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    if (_isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
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
        child: AnimatedSize(
          duration: AppConstants.animNormal,
          curve: Curves.easeInOut,
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
              AnimatedSwitcher(
                duration: AppConstants.animFast,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: (_controller.text.isNotEmpty || _isExpanded)
                    ? Padding(
                        key: const ValueKey('send'),
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: _submit,
                          child: Icon(
                            CupertinoIcons.arrow_up_circle_fill,
                            color: AppColors.primary(brightness),
                            size: 32,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
