import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/overlays/countdown_overlay.dart';
import '../game/overlays/game_over_overlay.dart';
import '../game/overlays/pause_overlay.dart';
import '../game/snake_game.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import 'widgets/game_hud.dart';

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

  /// 开局提示的展示时长。
  static const Duration _hintDuration = Duration(seconds: 6);

  final GlobalKey _pageKey = GlobalKey();
  final FocusNode _gameFocusNode = FocusNode(
    debugLabel: 'snake-game',
    skipTraversal: true,
  );
  SnakeGame? _game;
  Timer? _hintTimer;
  bool _showHint = false;

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
      _showHintFor(_hintDuration);
      _gameFocusNode.requestFocus();
    });
  }

  /// 只在进入新一局时短暂展示玩法提示。
  void _showHintFor(Duration duration) {
    _hintTimer?.cancel();
    if (mounted) {
      setState(() => _showHint = true);
    }
    _hintTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() => _showHint = false);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _game?.detachProvider();
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

  void _resumeGame(SnakeGame game) {
    game.provider.togglePause();
    _gameFocusNode.requestFocus();
  }

  void _restartGame(SnakeGame game) {
    game.provider.start();
    _gameFocusNode.requestFocus();
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
          builder: (context, provider, _) => Text('得分: ${provider.state.score}'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<GameProvider>(
            builder: (context, provider, _) {
              if (!provider.isPlaying && !provider.isPaused) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(provider.isPaused ? Icons.play_arrow : Icons.pause),
                tooltip: provider.isPaused ? '继续' : '暂停',
                onPressed: provider.togglePause,
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
                        onResume: () => _resumeGame(game),
                      ),
                  SnakeGame.countdownOverlayId: (_, SnakeGame game) =>
                      CountdownOverlay(countdown: game.countdown),
                  SnakeGame.gameOverOverlayId: (_, SnakeGame game) =>
                      GameOverOverlay(
                        provider: game.provider,
                        onRestart: () => _restartGame(game),
                      ),
                },
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.biggest;
                  final landscape = size.width > size.height;
                  final side = _boardSide(size, landscape);
                  return GameHud(
                    pageKey: _pageKey,
                    canvasSize: size,
                    boardRect: Rect.fromLTWH(
                      (size.width - side) / 2,
                      (size.height - side) / 2,
                      side,
                      side,
                    ),
                    landscape: landscape,
                    showHint: _showHint,
                    onBoardRect: _handleBoardRect,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
