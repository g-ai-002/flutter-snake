import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import 'achievements_page.dart';
import 'game_page.dart';
import 'leaderboard_page.dart';
import 'settings_page.dart';
import 'stats_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highScore = context.select<GameProvider, int>(
      (g) => g.state.highScore,
    );
    final unlocked = context.select<GameProvider, int>(
      (g) => g.unlockedAchievementCount,
    );
    final daily = context.select<GameProvider, _DailySnapshot>((g) {
      final challenge = g.todayChallenge;
      return (
        weekday: challenge.weekdayLabel,
        rule: challenge.subtitle,
        best: g.todayBest,
        streak: g.dailyStreak,
        played: g.playedToday,
      );
    });
    final darkMode = context.select<SettingsProvider, bool>((s) => s.darkMode);
    final boardSizeLabel = context.select<SettingsProvider, String>(
      (s) => s.boardSizeLabel,
    );
    final speedLabel = context.select<SettingsProvider, String>(
      (s) => s.speedLabel,
    );
    final levelLabel = context.select<SettingsProvider, String>(
      (s) => s.levelLabel,
    );
    final skinLabel = context.select<SettingsProvider, String>(
      (s) => s.skinLabel,
    );
    final modeLabel = context.select<SettingsProvider, String>(
      (s) => s.modeLabel,
    );
    final settings = context.read<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(darkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: darkMode ? '切换浅色模式' : '切换深色模式',
            onPressed: () => settings.toggleDarkMode(!darkMode),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(0, constraints.maxHeight - 48),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sports_esports,
                        size: 80,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '贪吃蛇',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '经典街机游戏',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 200,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GamePage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text(
                            '开始游戏',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DailyChallengeCard(daily: daily),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 42,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LeaderboardPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.emoji_events, size: 18),
                              label: const Text('排行榜'),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            height: 42,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AchievementsPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.military_tech, size: 18),
                              label: Text('成就 $unlocked'),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            height: 42,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const StatsPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.insights, size: 18),
                              label: const Text('数据'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '最高分: $highScore',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colorScheme.secondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '模式: $modeLabel  |  关卡: $levelLabel',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '皮肤: $skinLabel  |  棋盘: $boardSizeLabel',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '速度: $speedLabel',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _DailySnapshot = ({
  String weekday,
  String rule,
  int best,
  int streak,
  bool played,
});

/// 每日挑战入口：展示今日排期、今日最佳与连续天数。
class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.daily});

  final _DailySnapshot daily;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final played = daily.played;

    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final challenge = context.read<GameProvider>().todayChallenge;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GamePage(dailyChallenge: challenge),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.today, size: 18, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '每日挑战 · ${daily.weekday}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (daily.streak > 0)
                    Text(
                      '连续 ${daily.streak} 天',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                daily.rule,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    played ? '今日最佳 ${daily.best}' : '今日尚未挑战',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
