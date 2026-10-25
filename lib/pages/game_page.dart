import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/overlays/countdown_overlay.dart';
import '../game/overlays/game_over_overlay.dart';
import '../game/overlays/pause_overlay.dart';
import '../game/power_up_style.dart';
import '../game/snake_game.dart';
import '../models/game_state.dart';
import '../models/level.dart';
import '../models/power_up.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final GlobalKey _pageKey = GlobalKey();
  final FocusNode _gameFocusNode = FocusNode(
    debugLabel: 'snake-game',
    skipTraversal: true,
  );
  SnakeGame? _game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _gameFocusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_game != null) return;

    final provider = context.read<GameProvider>();
    final settings = context.read<SettingsProvider>();
    provider.updateLevel(settings.level);
    provider.updateBoardSize(settings.boardSize);
    provider.updateSpeed(settings.speed);

    final colors = Theme.of(context).colorScheme;
    _game = SnakeGame(
      provider: provider,
      surfaceColor: colors.surface,
      snakeColor: colors.primary,
      foodColor: colors.error,
      gridColor: colors.outline.withValues(alpha: 0.3),
      wallColor: colors.outline,
      portalColor: colors.tertiary,
      skin: settings.skin,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      provider.start();
      _gameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _gameFocusNode.dispose();
    super.dispose();
  }

  void _focusGame() {
    if (!_gameFocusNode.hasFocus) {
      _gameFocusNode.requestFocus();
    }
  }

  void _handleBoardRect(Rect rect) {
    final game = _game;
    final pageBox = _pageKey.currentContext?.findRenderObject();
    if (game == null || pageBox is! RenderBox || !pageBox.hasSize) {
      return;
    }
    game.updateBoardLayout(boardRect: rect, canvasSize: pageBox.size);
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

    return Scaffold(
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
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _focusGame(),
        child: Stack(
          key: _pageKey,
          children: [
            // Flame 画布铺满整个游戏页，棋盘由相机对齐到下面的槽位。
            Positioned.fill(
              child: GameWidget<SnakeGame>(
                game: game,
                focusNode: _gameFocusNode,
                overlayBuilderMap: {
                  SnakeGame.pauseOverlayId: (_, SnakeGame game) => PauseOverlay(
                        provider: game.provider,
                        onResume: () {
                          game.provider.togglePause();
                          _gameFocusNode.requestFocus();
                        },
                      ),
                  SnakeGame.countdownOverlayId: (_, SnakeGame game) =>
                      CountdownOverlay(countdown: game.countdown),
                  SnakeGame.gameOverOverlayId: (_, SnakeGame game) =>
                      GameOverOverlay(
                        provider: game.provider,
                        onRestart: () {
                          game.provider.start();
                          _gameFocusNode.requestFocus();
                        },
                      ),
                },
              ),
            ),
            // HUD 悬浮在画布之上；不接收点击的区域放行给 Flame 手势。
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Consumer<GameProvider>(
                        builder: (context, game, _) {
                          final state = game.state;
                          return Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text(
                                '最高分: ${state.highScore}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                '关卡: ${game.level.label}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
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
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio:
                                    state.boardWidth / state.boardHeight,
                                child: _BoardSlot(
                                  pageKey: _pageKey,
                                  onRect: _handleBoardRect,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            right: 8,
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
                                          .map((effect) =>
                                              _EffectChip(effect: effect))
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
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: Consumer<GameProvider>(
                      builder: (context, game, _) {
                        final status = game.state.status;
                        if (status == GameStatus.playing ||
                            status == GameStatus.paused) {
                          return IgnorePointer(
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  defaultTargetPlatform ==
                                          TargetPlatform.windows
                                      ? '方向键 / WASD 转向 · 空格暂停'
                                      : '点击或滑动屏幕任意位置控制方向',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
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
          ],
        ),
      ),
    );
  }
}

/// 只用于占位的棋盘槽位：把自身在游戏页中的矩形回报给 Flame 相机。
class _BoardSlot extends StatefulWidget {
  const _BoardSlot({required this.pageKey, required this.onRect});

  final GlobalKey pageKey;
  final ValueChanged<Rect> onRect;

  @override
  State<_BoardSlot> createState() => _BoardSlotState();
}

class _BoardSlotState extends State<_BoardSlot> {
  final GlobalKey _slotKey = GlobalKey();
  Rect? _lastRect;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportRect());
    return SizedBox.expand(key: _slotKey);
  }

  void _reportRect() {
    if (!mounted) return;
    final pageBox = widget.pageKey.currentContext?.findRenderObject();
    final slotBox = _slotKey.currentContext?.findRenderObject();
    if (pageBox is! RenderBox || slotBox is! RenderBox) return;
    if (!pageBox.hasSize || !slotBox.hasSize || slotBox.size.isEmpty) return;

    final rect =
        slotBox.localToGlobal(Offset.zero, ancestor: pageBox) & slotBox.size;
    if (rect == _lastRect) return;
    _lastRect = rect;
    widget.onRect(rect);
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
