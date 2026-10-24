import 'package:flutter/material.dart';

import '../../providers/game_provider.dart';

/// 暂停时覆盖在棋盘上的半透明遮罩。
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.provider});

  final GameProvider provider;

  @override
  Widget build(BuildContext context) {
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: provider.togglePause,
                icon: const Icon(Icons.play_arrow),
                label: const Text('继续'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
