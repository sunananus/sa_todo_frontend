// lib/core/widgets/app_shell.dart
// 应用外壳 — 底部导航容器

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'glass_bottom_bar.dart';

/// 毛玻璃底部导航栏的 Shell
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // 页面内容
          navigationShell,

          // 毛玻璃底部导航栏
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
              items: const [
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
