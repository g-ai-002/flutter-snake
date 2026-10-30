import 'package:flutter/material.dart';

import '../../models/game_mode.dart';
import '../../models/game_state.dart';
import '../../providers/game_provider.dart';

/// 游戏结束结算遮罩。
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.provider, this.onRestart});

  final GameProvider provider;

  /// 再来一局后的回调，用于把键盘焦点交还棋盘。
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = provider.state;

    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.overReason.label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.mode.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '本局得分',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${state.score}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '最高分 ${state.highScore}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.secondary,
                  ),
                ),
                if (provider.lastUnlocked.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final id in provider.lastUnlocked)
                        Chip(
                          avatar: Icon(
                            Icons.military_tech,
                            size: 16,
                            color: colors.tertiary,
                          ),
                          label: Text(id.title),
                          labelStyle: theme.textTheme.labelSmall,
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                            color: colors.tertiary.withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onRestart ?? provider.start,
                  icon: const Icon(Icons.replay),
                  label: const Text('再来一局'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(180, 44),
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
