import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/achievement.dart';
import '../models/game_mode.dart';
import '../models/player_stats.dart';
import '../providers/game_provider.dart';
import '../services/leaderboard_service.dart';
import '../services/share_service.dart';
import '../utils/formatters.dart';
import 'daily_calendar_page.dart';
import 'widgets/section_card.dart';
import 'widgets/stat_metric.dart';

/// 数据统计页：生涯数据、每日挑战进度与排行榜摘要。
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.select<GameProvider, PlayerStats>(
      (game) => game.stats,
    );
    final daily = context.select<GameProvider, _DailyStats>((game) {
      final challenge = game.todayChallenge;
      return (
        best: game.todayBest,
        played: game.playedToday,
        streak: game.dailyStreak,
        bestEver: game.dailyBestEver,
        playedDays: game.dailyPlayedDays,
        rule: '${challenge.weekdayLabel} · ${challenge.subtitle}',
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: '分享战绩',
            onPressed: () => _shareCareer(context, stats, daily),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                SectionCard(
                  icon: Icons.insights,
                  title: '生涯数据',
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _metric('总局数', '${stats.gamesPlayed}'),
                      _metric('累计食物', '${stats.totalFood}'),
                      _metric('最高分', '${stats.bestScore}'),
                      _metric('最佳连击', 'x${stats.bestCombo}'),
                      _metric('最长蛇身', '${stats.bestLength}'),
                      _metric('限时最佳', '${stats.bestTimedScore}'),
                      _metric(
                        '成就',
                        '${AchievementCatalog.unlockedCount(stats)}'
                            '/${AchievementCatalog.all.length}',
                      ),
                      _metric(
                        '已玩模式',
                        '${stats.modesPlayed.length}'
                            '/${GameMode.values.length}',
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  icon: Icons.today,
                  title: '每日挑战',
                  subtitle: '今日规则：${daily.rule}',
                  action: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyCalendarPage(),
                      ),
                    ),
                    child: const Text('日历'),
                  ),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _metric(
                        '今日最佳',
                        daily.played ? '${daily.best}' : '未挑战',
                        accent: daily.played,
                      ),
                      _metric('连续天数', '${daily.streak}'),
                      _metric('历史最佳', '${daily.bestEver}'),
                      _metric('挑战天数', '${daily.playedDays}'),
                    ],
                  ),
                ),
                const SectionCard(
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

  static Widget _metric(String label, String value, {bool accent = false}) {
    return StatMetric(label: label, value: value, accent: accent, width: 108);
  }

  /// 把生涯数据整理成纯文本复制到剪贴板。
  static Future<void> _shareCareer(
    BuildContext context,
    PlayerStats stats,
    _DailyStats daily,
  ) async {
    final text = ShareService.buildCareerText(
      stats: stats,
      achievements: AchievementCatalog.unlockedCount(stats),
      achievementTotal: AchievementCatalog.all.length,
      streak: daily.streak,
      dailyBest: daily.bestEver,
    );
    final ok = await ShareService.copy(text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? '战绩已复制到剪贴板' : '复制失败，请稍后再试')));
  }
}

typedef _DailyStats = ({
  int best,
  bool played,
  int streak,
  int bestEver,
  int playedDays,
  String rule,
});

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
                      formatShortDateTime(top[i].date),
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
}
