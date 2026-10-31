import 'package:flutter/material.dart';

import '../../providers/game_provider.dart';

/// 暂停时覆盖在棋盘上的半透明遮罩。
///
/// 除继续游戏外，还提供重新开始与返回主页，避免玩家只能先继续再退出。
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.provider,
    this.onResume,
    this.onRestart,
    this.onExit,
  });

  final GameProvider provider;

  /// 继续游戏后的回调，用于把键盘焦点交还棋盘。
  final VoidCallback? onResume;

  /// 重新开始本局（每日挑战会重开同一天）。
  final VoidCallback? onRestart;

  /// 返回主页。
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_outline,
                size: 44,
                color: Colors.white70,
              ),
              const SizedBox(height: 8),
              Text(
                '已暂停',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onResume ?? provider.togglePause,
                icon: const Icon(Icons.play_arrow),
                label: const Text('继续'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(180, 44),
                ),
              ),
              if (onRestart != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay),
                  label: const Text('重新开始'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(180, 44),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                ),
              ],
              if (onExit != null) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onExit,
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('返回主页'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
