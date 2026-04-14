// lib/app.dart
// CupertinoApp 配置 — 主题 + 路由

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    // 根据 themeMode 决定实际的 Brightness
    Brightness resolveBrightness() {
      switch (themeMode) {
        case AppThemeMode.light:
          return Brightness.light;
        case AppThemeMode.dark:
          return Brightness.dark;
        case AppThemeMode.system:
          return MediaQuery.platformBrightnessOf(context);
      }
    }

    final brightness = resolveBrightness();
    final theme =
        brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;

    return CupertinoApp.router(
      title: 'SA Todo',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: appRouter,
    );
  }
}
