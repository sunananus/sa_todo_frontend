// lib/features/home/widgets/quick_add_bar.dart
// 底部快速添加栏

import 'package:flutter/cupertino.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/utils/natural_language_parser.dart';
import '../../../core/utils/parsed_task.dart';

class QuickAddBar extends StatefulWidget {
  final Function(String title, ParsedTask parsed) onSubmit;
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
      if (mounted) {
        setState(() {});
        _onTextChanged(_controller.text);
      }
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

  ParsedTask? _parsed;

  void _onTextChanged(String text) {
    if (text.trim().isNotEmpty) {
      setState(() => _parsed = NaturalLanguageParser.parse(text));
    } else {
      setState(() => _parsed = null);
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      final parsed = NaturalLanguageParser.parse(text);
      widget.onSubmit(parsed.title, parsed);
      _controller.clear();
      setState(() => _parsed = null);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 解析预览
              if (_parsed != null && _controller.text.isNotEmpty)
                _buildParsedPreview(brightness),
              Padding(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParsedPreview(Brightness brightness) {
    final parsed = _parsed!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (parsed.dueDate != null)
            _buildChip(
              CupertinoIcons.calendar,
              '${parsed.dueDate!.month}/${parsed.dueDate!.day}',
              AppColors.primary(brightness),
            ),
          if (parsed.priority > 0)
            _buildChip(
              CupertinoIcons.flag,
              ['低', '中', '高'][parsed.priority - 1],
              AppColors.priorityColor(parsed.priority),
            ),
          if (parsed.recurrenceRule != null)
            _buildChip(
              CupertinoIcons.repeat,
              _recurrenceLabel(parsed.recurrenceRule!),
              AppColors.textSecondary(brightness),
            ),
          for (final tag in parsed.tags)
            _buildChip(CupertinoIcons.tag, '#$tag', AppColors.primary(brightness)),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption2.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _recurrenceLabel(String rule) {
    switch (rule) {
      case 'daily': return '每天';
      case 'weekly': return '每周';
      case 'monthly': return '每月';
      case 'yearly': return '每年';
      default: return rule;
    }
  }
}
