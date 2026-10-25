import 'dart:math' as math;

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
  /// 棋盘与页面边缘、HUD 之间的留白。
  static const double _boardMargin = 12;

  /// 竖屏时上下留给 HUD 的高度，保证棋盘严格居中后仍有位置摆信息与提示。
  static const double _portraitReserve = 84;

  /// 横屏时左右留给 HUD 的宽度。
  static const double _landscapeReserve = 160;

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

  /// 居中的正方形棋盘边长：横屏把 HUD 放到左右，竖屏放上下。
  double _boardSide(Size size, bool landscape) {
    final maxSide = landscape
        ? math.min(
            size.height - _boardMargin * 2,
            size.width - _landscapeReserve * 2,
          )
        : math.min(
            size.width - _boardMargin * 2,
            size.height - _portraitReserve * 2,
          );
    return math.max(0, maxSide);
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game == null) {
      return const SizedBox.shrink();
    }

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.biggest;
                  final landscape = size.width > size.height;
                  final side = _boardSide(size, landscape);
                  final boardLeft = (size.width - side) / 2;
                  final boardTop = (size.height - side) / 2;
                  return Stack(
                    children: [
                      Positioned.fromRect(
                        rect: Rect.fromLTWH(boardLeft, boardTop, side, side),
                        child: _BoardSlot(
                          pageKey: _pageKey,
                          onRect: _handleBoardRect,
                        ),
                      ),
                      // 道具效果贴住棋盘上沿。
                      Positioned(
                        top: boardTop + 8,
                        left: boardLeft + 8,
                        width: math.max(0, side - 16),
                        child: IgnorePointer(child: _buildEffects()),
                      ),
                      if (!landscape) ...[
                        Positioned(
                          top: math.max(4, boardTop - 40),
                          left: 16,
                          right: 16,
                          child: IgnorePointer(child: _buildStatus()),
                        ),
                        Positioned(
                          top: boardTop + side + 12,
                          left: 16,
                          right: 16,
                          child: _buildHint(),
                        ),
                      ] else ...[
                        Positioned(
                          left: 12,
                          top: 0,
                          bottom: 0,
                          width: math.max(0, boardLeft - 24),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: IgnorePointer(
                              child: _buildStatus(vertical: true),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 0,
                          bottom: 0,
                          width: math.max(
                            0,
                            size.width - boardLeft - side - 24,
                          ),
                          child: Center(child: _buildHint()),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus({bool vertical = false}) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        final state = game.state;
        final colorScheme = Theme.of(context).colorScheme;
        final items = <Widget>[
          Text(
            '最高分: ${state.highScore}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            '关卡: ${game.level.label}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          if (state.status == GameStatus.over)
            Text(
              '游戏结束',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
        ];
        if (vertical) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: item,
                ),
            ],
          );
        }
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: items,
        );
      },
    );
  }

  Widget _buildHint() {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        final status = game.state.status;
        if (status == GameStatus.playing || status == GameStatus.paused) {
          return SizedBox(
            height: 60,
            child: Center(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    defaultTargetPlatform == TargetPlatform.windows
                        ? '方向键 / WASD 转向 · 空格暂停'
                        : '点击或滑动屏幕任意位置控制方向',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ),
          );
        }
        if (status == GameStatus.idle) {
          return ElevatedButton.icon(
            onPressed: game.start,
            icon: const Icon(Icons.replay),
            label: const Text('重新开始'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(180, 44),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEffects() {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        final effects = game.activeEffects;
        if (effects.isEmpty) {
          return const SizedBox.shrink();
        }
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: effects.map((effect) => _EffectChip(effect: effect)).toList(),
        );
      },
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
