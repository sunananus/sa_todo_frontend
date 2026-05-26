// lib/app.dart
// CupertinoApp 配置 — 主题 + 路由

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    // 监听小组件点击事件（仅 iOS/Android）
    if (Platform.isIOS || Platform.isAndroid) {
      HomeWidget.widgetClicked.listen((uri) {
        if (uri != null && uri.host == 'quickadd') {
          appRouter.go('/?action=quickadd');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final brightness = themeMode == AppThemeMode.system
        ? MediaQuery.platformBrightnessOf(context)
        : (themeMode == AppThemeMode.dark ? Brightness.dark : Brightness.light);
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
