// lib/core/widgets/app_shell.dart
// 应用外壳 — 响应式导航容器

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import 'glass_bottom_bar.dart';
import 'glass_sidebar.dart';

/// 毛玻璃导航 Shell（桌面端侧边栏 / 移动端底部栏）
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  static const _tabs = [
    GlassTabItem(
      icon: CupertinoIcons.list_bullet,
      activeIcon: CupertinoIcons.list_bullet,
      label: '任务',
    ),
    GlassTabItem(
      icon: CupertinoIcons.chart_bar,
      activeIcon: CupertinoIcons.chart_bar_fill,
      label: '统计',
    ),
    GlassTabItem(
      icon: CupertinoIcons.folder,
      activeIcon: CupertinoIcons.folder_fill,
      label: '清单',
    ),
    GlassTabItem(
      icon: CupertinoIcons.gear,
      activeIcon: CupertinoIcons.gear_solid,
      label: '设置',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= AppConstants.kDesktopBreakpoint;

        if (isDesktop) {
          // 桌面端：左侧边栏 + 右侧内容
          return CupertinoPageScaffold(
            child: Row(
              children: [
                GlassSidebar(
                  currentIndex: navigationShell.currentIndex,
                  onTap: (index) => navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  ),
                  items: _tabs,
                ),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        // 移动端：底部导航栏
        return CupertinoPageScaffold(
          child: Stack(
            children: [
              navigationShell,
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GlassBottomBar(
                  currentIndex: navigationShell.currentIndex,
                  onTap: (index) => navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  ),
                  items: _tabs,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
