// lib/features/statistics/statistics_page.dart
// 数据统计页面

import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/repositories/task_repository.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final tasksAsync = ref.watch(taskRepositoryProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(brightness),
      child: tasksAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (tasks) {
          final completed = tasks.where((t) => t.isCompleted).length;
          final pending = tasks.where((t) => !t.isCompleted).length;

          // 计算本周统计
          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          final weeklyStats = <String, int>{};
          for (int i = 0; i < 7; i++) {
            final day = weekAgo.add(Duration(days: i + 1));
            final key = '${day.month}/${day.day}';
            weeklyStats[key] = tasks.where((t) {
              if (t.completedAt == null) return false;
              final c = t.completedAt!.toLocal();
              return c.year == day.year && c.month == day.month && c.day == day.day;
            }).length;
          }

          return CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text(
                  '数据统计',
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
                    children: [
                      // 概览卡片
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: CupertinoIcons.checkmark_alt_circle_fill,
                              label: '已完成',
                              value: '$completed',
                              color: AppColors.success,
                            ).animate().fadeIn(duration: AppConstants.animNormal).slideY(begin: 0.15, end: 0, duration: AppConstants.animNormal, curve: Curves.easeOut),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: CupertinoIcons.clock,
                              label: '待办中',
                              value: '$pending',
                              color: AppColors.primary(brightness),
                            ).animate().fadeIn(delay: 60.ms, duration: AppConstants.animNormal).slideY(begin: 0.15, end: 0, delay: 60.ms, duration: AppConstants.animNormal, curve: Curves.easeOut),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: CupertinoIcons.chart_bar_alt_fill,
                              label: '总计',
                              value: '${completed + pending}',
                              color: AppColors.warning,
                            ).animate().fadeIn(delay: 120.ms, duration: AppConstants.animNormal).slideY(begin: 0.15, end: 0, delay: 120.ms, duration: AppConstants.animNormal, curve: Curves.easeOut),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 连续打卡
                      Row(
                        children: [
                          Expanded(
                            child: FutureBuilder<int>(
                              future: ref.read(taskRepositoryProvider.notifier).currentStreak,
                              builder: (ctx, snap) => _StatCard(
                                icon: CupertinoIcons.flame_fill,
                                label: '当前连续',
                                value: '${snap.data ?? 0} 天',
                                color: AppColors.error,
                              ),
                            ),
                          ).animate().fadeIn(delay: 140.ms, duration: AppConstants.animNormal).slideY(begin: 0.15, end: 0, delay: 140.ms, duration: AppConstants.animNormal, curve: Curves.easeOut),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FutureBuilder<int>(
                              future: ref.read(taskRepositoryProvider.notifier).longestStreak,
                              builder: (ctx, snap) => _StatCard(
                                icon: CupertinoIcons.star_fill,
                                label: '最长连续',
                                value: '${snap.data ?? 0} 天',
                                color: AppColors.warning,
                              ),
                            ),
                          ).animate().fadeIn(delay: 200.ms, duration: AppConstants.animNormal).slideY(begin: 0.15, end: 0, delay: 200.ms, duration: AppConstants.animNormal, curve: Curves.easeOut),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 优先级分布
                      FutureBuilder<Map<String, int>>(
                        future: ref.read(taskRepositoryProvider.notifier).getPriorityDistribution(),
                        builder: (ctx, snap) {
                          final dist = snap.data ?? {};
                          final total = dist.values.fold(0, (a, b) => a + b);
                          if (total == 0) return const SizedBox.shrink();
                          return GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '优先级分布',
                                  style: AppTextStyles.headline.copyWith(
                                    color: AppColors.textPrimary(brightness),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...dist.entries.map((e) {
                                  final colors = {
                                    '高': AppColors.error,
                                    '中': AppColors.warning,
                                    '低': AppColors.success,
                                    '无': AppColors.textSecondary(brightness),
                                  };
                                  final ratio = total > 0 ? e.value / total : 0.0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 28,
                                          child: Text(
                                            e.key,
                                            style: AppTextStyles.footnote.copyWith(
                                              color: AppColors.textSecondary(brightness),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (ctx, constraints) => Container(
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: AppColors.separator(brightness).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  width: constraints.maxWidth * ratio,
                                                  decoration: BoxDecoration(
                                                    color: colors[e.key] ?? AppColors.textSecondary(brightness),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 24,
                                          child: Text(
                                            '${e.value}',
                                            textAlign: TextAlign.right,
                                            style: AppTextStyles.caption1.copyWith(
                                              color: AppColors.textPrimary(brightness),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ).animate().fadeIn(delay: 220.ms, duration: AppConstants.animNormal).slideY(begin: 0.1, end: 0, delay: 220.ms, duration: AppConstants.animNormal, curve: Curves.easeOut);
                        },
                      ),

                      const SizedBox(height: 20),

                      // 本周完成趋势
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '本周完成趋势',
                              style: AppTextStyles.headline.copyWith(
                                color: AppColors.textPrimary(brightness),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 200,
                              child: weeklyStats.isEmpty
                                  ? Center(
                                      child: Text(
                                        '暂无数据',
                                        style: AppTextStyles.footnote.copyWith(
                                          color:
                                              AppColors.textSecondary(brightness),
                                        ),
                                      ),
                                    )
                                  : BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        maxY: _getMaxY(weeklyStats),
                                        barTouchData: BarTouchData(
                                          touchTooltipData: BarTouchTooltipData(
                                            getTooltipColor: (_) =>
                                                AppColors.surface(brightness),
                                            getTooltipItem: (group, groupIndex,
                                                rod, rodIndex) {
                                              return BarTooltipItem(
                                                '${rod.toY.toInt()} 项',
                                                AppTextStyles.caption1.copyWith(
                                                  color: AppColors.textPrimary(
                                                      brightness),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                final keys =
                                                    weeklyStats.keys.toList();
                                                if (value.toInt() < keys.length) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(top: 8),
                                                    child: Text(
                                                      keys[value.toInt()],
                                                      style: AppTextStyles.caption2
                                                          .copyWith(
                                                        color:
                                                            AppColors.textSecondary(
                                                                brightness),
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return const SizedBox();
                                              },
                                            ),
                                          ),
                                          leftTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        gridData: const FlGridData(show: false),
                                        barGroups: _buildBarGroups(
                                            weeklyStats, brightness),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 180.ms, duration: AppConstants.animNormal).slideY(begin: 0.1, end: 0, delay: 180.ms, duration: AppConstants.animNormal, curve: Curves.easeOut),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _getMaxY(Map<String, int> stats) {
    final maxVal = stats.values.fold(0, (a, b) => a > b ? a : b);
    return (maxVal + 2).toDouble();
  }

  List<BarChartGroupData> _buildBarGroups(
      Map<String, int> stats, Brightness brightness) {
    final entries = stats.entries.toList();
    return List.generate(entries.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: entries[i].value.toDouble(),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.primary(brightness),
                AppColors.primary(brightness).withValues(alpha: 0.6),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.title2.copyWith(
              color: AppColors.textPrimary(brightness),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.textSecondary(brightness),
            ),
          ),
        ],
      ),
    );
  }
}
