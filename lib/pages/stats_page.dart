import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/achievement.dart';
import '../models/game_mode.dart';
import '../models/player_stats.dart';
import '../providers/game_provider.dart';
import '../services/leaderboard_service.dart';

/// 数据统计页：生涯数据、每日挑战进度与排行榜摘要。
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.select<GameProvider, PlayerStats>(
      (game) => game.stats,
    );
    final todayBest = context.select<GameProvider, int>(
      (game) => game.todayBest,
    );
    final playedToday = context.select<GameProvider, bool>(
      (game) => game.playedToday,
    );
    final streak = context.select<GameProvider, int>(
      (game) => game.dailyStreak,
    );
    final dailyBest = context.select<GameProvider, int>(
      (game) => game.dailyBestEver,
    );
    final dailyDays = context.select<GameProvider, int>(
      (game) => game.dailyPlayedDays,
    );
    final dailyRule = context.select<GameProvider, String>(
      (game) =>
          '${game.todayChallenge.weekdayLabel} · ${game.todayChallenge.subtitle}',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _SectionCard(
                  icon: Icons.insights,
                  title: '生涯数据',
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _Metric(label: '总局数', value: '${stats.gamesPlayed}'),
                      _Metric(label: '累计食物', value: '${stats.totalFood}'),
                      _Metric(label: '最高分', value: '${stats.bestScore}'),
                      _Metric(label: '最佳连击', value: 'x${stats.bestCombo}'),
                      _Metric(label: '最长蛇身', value: '${stats.bestLength}'),
                      _Metric(label: '限时最佳', value: '${stats.bestTimedScore}'),
                      _Metric(
                        label: '成就',
                        value:
                            '${AchievementCatalog.unlockedCount(stats)}'
                            '/${AchievementCatalog.all.length}',
                      ),
                      _Metric(
                        label: '已玩模式',
                        value:
                            '${stats.modesPlayed.length}'
                            '/${GameMode.values.length}',
                      ),
                    ],
                  ),
                ),
                _SectionCard(
                  icon: Icons.today,
                  title: '每日挑战',
                  subtitle: '今日规则：$dailyRule',
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _Metric(
                        label: '今日最佳',
                        value: playedToday ? '$todayBest' : '未挑战',
                        accent: playedToday,
                      ),
                      _Metric(label: '连续天数', value: '$streak'),
                      _Metric(label: '历史最佳', value: '$dailyBest'),
                      _Metric(label: '挑战天数', value: '$dailyDays'),
                    ],
                  ),
                ),
                const _SectionCard(
                  icon: Icons.emoji_events,
                  title: '排行榜 Top 5',
                  child: _LeaderboardPreview(),
                ),
                const SizedBox(height: 8),
                Text(
                  '所有数据保存在本机，卸载应用后不会保留。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SizedBox(
      width: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: accent ? colors.primary : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 排行榜前五名；读取失败时给出提示而不是抛错。
class _LeaderboardPreview extends StatelessWidget {
  const _LeaderboardPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return FutureBuilder<List<LeaderboardEntry>>(
      future: LeaderboardService.getEntries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 48,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final entries = snapshot.data;
        if (snapshot.hasError || entries == null || entries.isEmpty) {
          return Text(
            snapshot.hasError ? '排行榜暂不可用' : '暂无记录，先玩一局吧',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          );
        }
        final top = entries.take(5).toList(growable: false);
        return Column(
          children: [
            for (var i = 0; i < top.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == top.length - 1 ? 0 : 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${i + 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: i == 0
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${top[i].score} 分',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(top[i].date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
