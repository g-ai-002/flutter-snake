import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/mode_style.dart';
import '../models/achievement.dart';
import '../models/player_stats.dart';
import '../providers/game_provider.dart';
import 'widgets/stat_metric.dart';

/// 成就页：展示解锁进度与累计统计。
class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.select<GameProvider, PlayerStats>((g) => g.stats);
    final unlocked = AchievementCatalog.unlockedCount(stats);
    final total = AchievementCatalog.all.length;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('成就')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SummaryCard(stats: stats, unlocked: unlocked, total: total),
          const SizedBox(height: 16),
          for (final id in AchievementCatalog.all)
            _AchievementTile(id: id, stats: stats),
          const SizedBox(height: 8),
          Text(
            '成就随游戏进度自动解锁，数据保存在本机。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.stats,
    required this.unlocked,
    required this.total,
  });

  final PlayerStats stats;
  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                '已解锁 $unlocked / $total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : unlocked / total,
              minHeight: 6,
              backgroundColor: colors.surface,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              StatMetric(label: '局数', value: '${stats.gamesPlayed}', dense: true),
              StatMetric(label: '最佳连击', value: 'x${stats.bestCombo}', dense: true),
              StatMetric(label: '最长蛇身', value: '${stats.bestLength}', dense: true),
              StatMetric(
                label: '限时最佳',
                value: '${stats.bestTimedScore}',
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.id, required this.stats});

  final AchievementId id;
  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final unlocked = id.isUnlocked(stats);
    final ratio = id.progressRatio(stats);
    final accent = unlocked ? colors.primary : colors.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: unlocked
            ? colors.primaryContainer.withValues(alpha: 0.28)
            : colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? colors.primary.withValues(alpha: 0.35)
              : colors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: unlocked
                  ? colors.primary.withValues(alpha: 0.14)
                  : colors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              unlocked ? achievementIcon(id) : Icons.lock_outline,
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        id.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: unlocked ? colors.onSurface : accent,
                        ),
                      ),
                    ),
                    Text(
                      unlocked ? '已解锁' : id.progressLabel(stats),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: unlocked ? colors.primary : accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  id.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 4,
                    backgroundColor: colors.surface,
                    color: unlocked ? colors.primary : colors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
