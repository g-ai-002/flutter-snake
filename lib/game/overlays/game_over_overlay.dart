import 'package:flutter/material.dart';

import '../../providers/game_provider.dart';

/// 游戏结束结算遮罩。
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.provider});

  final GameProvider provider;

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
                  '游戏结束',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
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
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: provider.start,
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
