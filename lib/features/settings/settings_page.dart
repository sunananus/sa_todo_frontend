// lib/features/settings/settings_page.dart
// 设置页面

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/api/api_client.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _urlController;
  late TextEditingController _tokenController;
  bool _isCheckingHealth = false;
  bool? _healthOk;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _tokenController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _urlController.text =
        prefs.getString(AppConstants.baseUrlKey) ?? AppConstants.defaultBaseUrl;
    _tokenController.text =
        prefs.getString(AppConstants.authTokenKey) ?? '';
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.baseUrlKey, _urlController.text.trim());
    await prefs.setString(
        AppConstants.authTokenKey, _tokenController.text.trim());
  }

  Future<void> _testConnection() async {
    setState(() {
      _isCheckingHealth = true;
      _healthOk = null;
    });
    await _saveSettings();
    final api = ref.read(apiClientProvider);
    final ok = await api.healthCheck();
    if (mounted) {
      setState(() {
        _isCheckingHealth = false;
        _healthOk = ok;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final themeMode = ref.watch(themeProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(brightness),
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              '设置',
              style: AppTextStyles.largeTitleBold
                  .copyWith(color: AppColors.textPrimary(brightness)),
            ),
            backgroundColor:
                AppColors.background(brightness).withValues(alpha: 0.8),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========== 外观 ==========
                  _buildSectionTitle('外观', brightness),
                  const SizedBox(height: 8),
                  GlassCard(
                    child: Column(
                      children: [
                        _buildThemeOption(
                          context,
                          label: '跟随系统',
                          icon: CupertinoIcons.device_phone_portrait,
                          isSelected: themeMode == AppThemeMode.system,
                          onTap: () => ref
                              .read(themeProvider.notifier)
                              .setTheme(AppThemeMode.system),
                        ),
                        _buildDivider(brightness),
                        _buildThemeOption(
                          context,
                          label: '浅色模式',
                          icon: CupertinoIcons.sun_max,
                          isSelected: themeMode == AppThemeMode.light,
                          onTap: () => ref
                              .read(themeProvider.notifier)
                              .setTheme(AppThemeMode.light),
                        ),
                        _buildDivider(brightness),
                        _buildThemeOption(
                          context,
                          label: '深色模式',
                          icon: CupertinoIcons.moon,
                          isSelected: themeMode == AppThemeMode.dark,
                          onTap: () => ref
                              .read(themeProvider.notifier)
                              .setTheme(AppThemeMode.dark),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ========== 同步服务器 ==========
                  _buildSectionTitle('同步服务器', brightness),
                  const SizedBox(height: 8),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '服务器地址',
                          style: AppTextStyles.footnote.copyWith(
                            color: AppColors.textSecondary(brightness),
                          ),
                        ),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _urlController,
                          placeholder: AppConstants.defaultBaseUrl,
                          keyboardType: TextInputType.url,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary(brightness),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface(brightness)
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '认证 Token',
                          style: AppTextStyles.footnote.copyWith(
                            color: AppColors.textSecondary(brightness),
                          ),
                        ),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _tokenController,
                          placeholder: '请输入 Auth Token',
                          obscureText: true,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary(brightness),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface(brightness)
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoButton(
                                color: AppColors.primary(brightness),
                                borderRadius: BorderRadius.circular(10),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                onPressed: _saveSettings,
                                child: const Text('保存配置',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            CupertinoButton(
                              color: AppColors.surface(brightness)
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              onPressed:
                                  _isCheckingHealth ? null : _testConnection,
                              child: _isCheckingHealth
                                  ? const CupertinoActivityIndicator()
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _healthOk == true
                                              ? CupertinoIcons
                                                  .checkmark_circle_fill
                                              : _healthOk == false
                                                  ? CupertinoIcons
                                                      .xmark_circle_fill
                                                  : CupertinoIcons.wifi,
                                          size: 16,
                                          color: _healthOk == true
                                              ? AppColors.success
                                              : _healthOk == false
                                                  ? AppColors.error
                                                  : AppColors.textPrimary(
                                                      brightness),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '测试',
                                          style: TextStyle(
                                            color: AppColors.textPrimary(
                                                brightness),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ========== 关于 ==========
                  _buildSectionTitle('关于', brightness),
                  const SizedBox(height: 8),
                  GlassCard(
                    child: Column(
                      children: [
                        _buildInfoRow('版本', AppConstants.appVersion, brightness),
                        _buildDivider(brightness),
                        _buildInfoRow('架构', 'Local-First + Cloud Sync', brightness),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.footnoteBold.copyWith(
          color: AppColors.textSecondary(brightness),
          textBaseline: TextBaseline.alphabetic,
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.primary(brightness)
                  : AppColors.textSecondary(brightness),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary(brightness),
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                CupertinoIcons.checkmark,
                size: 18,
                color: AppColors.primary(brightness),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.body
                .copyWith(color: AppColors.textPrimary(brightness)),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary(brightness)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Brightness brightness) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 32),
      color: AppColors.separator(brightness).withValues(alpha: 0.3),
    );
  }
}
