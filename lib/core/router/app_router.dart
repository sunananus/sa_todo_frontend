// lib/core/router/app_router.dart
// 应用路由配置

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_page.dart';
import '../../features/task_detail/task_detail_page.dart';
import '../../features/today/today_page.dart';
import '../../features/calendar/calendar_page.dart';
import '../../features/statistics/statistics_page.dart';
import '../../features/lists/lists_page.dart';
import '../../features/settings/settings_page.dart';
import '../widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // 主 Shell（底部 Tab）
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: 首页（任务列表）
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomePage(),
              ),
            ),
          ],
        ),
        // Tab 1: 今天
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: TodayPage(),
              ),
            ),
          ],
        ),
        // Tab 2: 日历
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: CalendarPage(),
              ),
            ),
          ],
        ),
        // Tab 3: 统计
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: StatisticsPage(),
              ),
            ),
          ],
        ),
        // Tab 4: 清单
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lists',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ListsPage(),
              ),
            ),
          ],
        ),
        // Tab 5: 设置
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsPage(),
              ),
            ),
          ],
        ),
      ],
    ),

    // 任务详情（独立页面，带跳转动画）
    GoRoute(
      path: '/task/:id',
      pageBuilder: (context, state) {
        final taskId = state.pathParameters['id']!;
        return CupertinoPage(
          child: TaskDetailPage(taskId: taskId),
        );
      },
    ),
  ],
);
