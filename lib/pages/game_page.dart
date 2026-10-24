import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../game/overlays/countdown_overlay.dart';
import '../game/overlays/game_over_overlay.dart';
import '../game/overlays/pause_overlay.dart';
import '../game/power_up_style.dart';
import '../game/snake_game.dart';
import '../models/game_state.dart';
import '../models/power_up.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gesture_control.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final FocusNode _focusNode = FocusNode();
  final FocusNode _gameFocusNode = FocusNode(
    canRequestFocus: false,
    skipTraversal: true,
  );
  SnakeGame? _game;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_game != null) return;

    final provider = context.read<GameProvider>();
    final settings = context.read<SettingsProvider>();
    provider.updateBoardSize(settings.boardSize);
    provider.updateSpeed(settings.speed);

    final colors = Theme.of(context).colorScheme;
    _game = SnakeGame(
      provider: provider,
      surfaceColor: colors.surface,
      snakeColor: colors.primary,
      foodColor: colors.error,
      gridColor: colors.outline.withValues(alpha: 0.3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      provider.start();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _gameFocusNode.dispose();
    super.dispose();
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final game = context.read<GameProvider>();
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      game.changeDirection(Direction.up);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      game.changeDirection(Direction.down);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      game.changeDirection(Direction.left);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      game.changeDirection(Direction.right);
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      game.togglePause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.read<GameProvider>();
    final game = _game;
    if (game == null) {
      return const SizedBox.shrink();
    }
    final state = provider.state;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<GameProvider>(
            builder: (context, game, _) => Text('得分: ${game.state.score}'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Consumer<GameProvider>(
              builder: (context, game, _) {
                if (!game.isPlaying && !game.isPaused) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: Icon(game.isPaused ? Icons.play_arrow : Icons.pause),
                  tooltip: game.isPaused ? '继续' : '暂停',
                  onPressed: game.togglePause,
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<GameProvider>(
                  builder: (context, game, _) {
                    final state = game.state;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '最高分: ${state.highScore}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (state.status == GameStatus.over)
                          Text(
                            '游戏结束',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureControl(
                        onDirection: provider.changeDirection,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: AspectRatio(
                              aspectRatio: state.boardWidth / state.boardHeight,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: GameWidget<SnakeGame>(
                                  game: game,
                                  focusNode: _gameFocusNode,
                                  autofocus: false,
                                  overlayBuilderMap: {
                                    SnakeGame.pauseOverlayId:
                                        (_, SnakeGame game) => PauseOverlay(
                                              provider: game.provider,
                                            ),
                                    SnakeGame.countdownOverlayId:
                                        (_, SnakeGame game) => CountdownOverlay(
                                              countdown: game.countdown,
                                            ),
                                    SnakeGame.gameOverOverlayId:
                                        (_, SnakeGame game) => GameOverOverlay(
                                              provider: game.provider,
                                            ),
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 16,
                      right: 16,
                      child: IgnorePointer(
                        child: Consumer<GameProvider>(
                          builder: (context, game, _) {
                            final effects = game.activeEffects;
                            if (effects.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Align(
                              alignment: Alignment.topCenter,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                alignment: WrapAlignment.center,
                                children: effects
                                    .map((effect) => _EffectChip(effect: effect))
                                    .toList(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: Consumer<GameProvider>(
                  builder: (context, game, _) {
                    final status = game.state.status;
                    if (status == GameStatus.playing ||
                        status == GameStatus.paused) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            defaultTargetPlatform == TargetPlatform.windows
                                ? '方向键 / 点击或滑动棋盘控制方向'
                                : '点击或滑动棋盘控制方向',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ),
                      );
                    }
                    if (status == GameStatus.idle) {
                      return Center(
                        child: ElevatedButton.icon(
                          onPressed: game.start,
                          icon: const Icon(Icons.replay),
                          label: const Text('重新开始'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(180, 44),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _EffectChip extends StatelessWidget {
  const _EffectChip({required this.effect});

  final ActiveEffect effect;

  @override
  Widget build(BuildContext context) {
    final color = powerUpColor(effect.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(powerUpIcon(effect.type), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${effect.type.label} ${effect.remaining.ceil()}s',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
