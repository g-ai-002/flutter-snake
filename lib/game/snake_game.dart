import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_state.dart';
import '../models/power_up.dart';
import '../models/skin.dart';
import '../providers/game_provider.dart';
import 'camera_rig.dart';
import 'components/board_component.dart';
import 'components/board_layer_component.dart';
import 'components/death_flash_component.dart';
import 'components/food_component.dart';
import 'components/particle_burst_component.dart';
import 'components/portal_component.dart';
import 'components/score_popup_layer.dart';
import 'components/snake_component.dart';
import 'components/wall_component.dart';
import 'countdown_controller.dart';
import 'feedback_controller.dart';
import 'input/canvas_gesture_layer.dart';
import 'input/direction_input.dart';
import 'power_up_style.dart';
import 'skins/skin_sprites.dart';
import 'skins/skin_style.dart';
import 'snake_world.dart';

const double _worldSize = 400;

/// 基于 Flame 的贪吃蛇游戏。
///
/// 棋盘、食物、蛇、粒子和飘字都放在 [World] 中，[CameraRig] 把 400×400 的
/// 世界棋盘对齐到 Flutter 侧给出的棋盘槽位；画布铺满整个游戏页，棋盘以外的
/// 区域由悬浮的 Flutter HUD 覆盖。游戏规则仍由 [GameProvider] 持有，
/// 视觉反馈与倒计时分别交给 [FeedbackController] 与 [CountdownController]。
class SnakeGame extends FlameGame<SnakeWorld> with KeyboardEvents {
  SnakeGame({
    required this.provider,
    required this.surfaceColor,
    required this.snakeColor,
    required this.foodColor,
    required this.gridColor,
    required this.wallColor,
    required this.portalColor,
    required this.skin,
  }) : super(
          world: SnakeWorld(),
          camera: CameraComponent(),
        ) {
    _camera = CameraRig(camera: camera, worldSize: _worldSize);
  }

  static const String pauseOverlayId = 'pause';
  static const String countdownOverlayId = 'countdown';
  static const String gameOverOverlayId = 'gameOver';

  static const int _maxStepsPerFrame = 4;
  static const double _gameOverOverlayDelay = 0.55;

  final GameProvider provider;
  final Color surfaceColor;
  final Color snakeColor;
  final Color foodColor;
  final Color gridColor;
  final Color wallColor;
  final Color portalColor;
  final SnakeSkin skin;

  late final CameraRig _camera;
  final FeedbackController _feedback = FeedbackController();
  final CountdownController _countdown = CountdownController();

  /// 开局倒计时：3、2、1、0（0 显示 GO）。
  ValueNotifier<int> get countdown => _countdown.value;

  late final Color _snakeTint = snakeSkinColor(skin) ?? snakeColor;

  late final BoardComponent _board;
  late final WallComponent _walls;
  late final PortalComponent _portals;
  late final FoodComponent _food;
  late final SnakeComponent _snake;
  late final ParticleBurstComponent _particles;
  late final DeathFlashComponent _flash;
  late final ScorePopupLayer _scorePopups;
  late final CanvasGestureLayer _gestures;
  late final List<BoardLayerComponent> _layers;

  SkinSprites _sprites = SkinSprites.empty;

  double _worldCellSize = 0;
  bool _ready = false;
  double _accumulator = 0;
  GameStatus _lastStatus = GameStatus.idle;

  bool _gameOverOverlayPending = false;
  double _gameOverOverlayTimer = 0;

  @override
  Color backgroundColor() => surfaceColor;

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isDown = event is KeyDownEvent;
    final isRepeat = event is KeyRepeatEvent;
    if (!isDown && !isRepeat) {
      return KeyEventResult.ignored;
    }

    final direction = _directionFor(event.logicalKey);
    if (direction != null) {
      provider.changeDirection(direction);
      return KeyEventResult.handled;
    }

    if (isDown &&
        (event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.keyP ||
            event.logicalKey == LogicalKeyboardKey.escape)) {
      provider.togglePause();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Direction? _directionFor(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      return Direction.up;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      return Direction.down;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      return Direction.left;
    }
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      return Direction.right;
    }
    return null;
  }

  @override
  Future<void> onLoad() async {
    final foodTint = snakeSkinFoodColor(skin) ?? foodColor;
    if (skin.usesSprites) {
      _sprites = await SkinSprites.load(this, skin);
    }

    _board = BoardComponent(
      provider: provider,
      backgroundColor: surfaceColor,
      gridColor: gridColor,
      borderColor: wallColor,
    );
    _walls = WallComponent(
      provider: provider,
      color: wallColor,
      priority: 1,
    );
    _portals = PortalComponent(
      provider: provider,
      color: portalColor,
      priority: 2,
    );
    _food = FoodComponent(
      provider: provider,
      color: foodTint,
      skin: skin,
      sprites: _sprites,
      priority: 3,
    );
    _snake = SnakeComponent(
      provider: provider,
      color: _snakeTint,
      skin: skin,
      sprites: _sprites,
      priority: 4,
    );
    _particles = ParticleBurstComponent(
      provider: provider,
      color: foodTint,
      priority: 5,
    );
    _flash = DeathFlashComponent(
      provider: provider,
      priority: 6,
    );
    _scorePopups = ScorePopupLayer(color: _snakeTint);

    _layers = <BoardLayerComponent>[
      _board,
      _walls,
      _portals,
      _food,
      _snake,
      _particles,
      _flash,
    ];
    _layoutBoard();

    await world.addAll(<Component>[..._layers, _scorePopups]);

    _gestures = CanvasGestureLayer(
      onTap: handleTap,
      onSwipe: handleSwipe,
    );
    camera.viewport.add(_gestures);

    _camera.resize(Size(size.x, size.y));
    _camera.applyBase();
    _ready = true;
    _snake.snapToCurrent();
    provider.addListener(_handleProviderChange);
  }

  @override
  void onRemove() {
    _countdown.dispose();
    detachProvider();
    super.onRemove();
  }

  /// 断开对 provider 的监听；GameWidget 销毁时显式调用一次。
  void detachProvider() {
    provider.removeListener(_handleProviderChange);
  }

  /// 暂停后主循环已停，必须靠 provider 通知才能收到「继续」并重启。
  void _handleProviderChange() {
    if (!_ready) return;
    if (provider.state.status == GameStatus.playing) {
      resumeEngine();
    }
    _handleStatusChange(provider.state.status);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _camera.resize(Size(size.x, size.y));
  }

  /// Flutter 侧把棋盘槽位的页面矩形同步过来，相机据此把世界棋盘画在槽位里。
  void updateBoardLayout({required Rect boardRect, required Size canvasSize}) {
    _camera.updateLayout(boardRect: boardRect, canvasSize: canvasSize);
  }

  /// 点击画布任意位置：按点击点相对棋盘中心的方向转向。
  void handleTap(Offset position) {
    final boardRect = _camera.boardRect;
    if (boardRect.isEmpty) {
      return;
    }
    final direction = directionFromTap(
      position - boardRect.topLeft,
      boardRect.size,
    );
    if (direction != null) {
      provider.changeDirection(direction);
    }
  }

  /// 画布上的滑动：按位移方向转向。
  void handleSwipe(Offset delta) {
    if (delta.distance < swipeThreshold) {
      return;
    }
    provider.changeDirection(directionFromDelta(delta));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready) {
      return;
    }

    _feedback.updateVisuals(dt);
    world.timeScale = _feedback.timeScale;
    _flash.opacity = _feedback.flashOpacity;

    final visualDt =
        _feedback.isSlowMotion ? dt * FeedbackController.slowMotionScale : dt;
    _camera.update(visualDt);
    _updateGameOverOverlay(dt);

    final status = provider.state.status;
    if (status != _lastStatus) {
      _handleStatusChange(status);
    }
    if (status != GameStatus.playing) {
      return;
    }

    if (_countdown.isActive) {
      if (_countdown.update(dt)) {
        overlays.remove(countdownOverlayId);
      }
      provider.unlockDirection();
      return;
    }

    provider.updateEffects(dt);
    _feedback.tickCombo(dt);

    final step = provider.effectiveSpeedMs / 1000;
    if (step <= 0) {
      return;
    }

    _accumulator += dt;
    var steps = 0;
    while (_accumulator >= step && steps < _maxStepsPerFrame) {
      _accumulator -= step;
      steps++;
      if (!_step()) {
        return;
      }
    }
    if (_accumulator >= step) {
      _accumulator = 0;
    }

    _snake.setProgress(_accumulator / step);
  }

  /// 推进一步游戏逻辑；返回 false 表示本帧不再继续推进。
  bool _step() {
    final oldFood = provider.state.food;
    final oldScore = provider.state.score;
    final hadShield = provider.hasShield;
    final previousHead = provider.state.snake.head;

    _snake.beginStep();
    provider.tick();

    final newHead = provider.state.snake.head;
    if ((newHead.x - previousHead.x).abs() > 1 ||
        (newHead.y - previousHead.y).abs() > 1) {
      _onPortalJump(previousHead, newHead);
    }
    if (hadShield && !provider.hasShield && provider.isPlaying) {
      _onShieldBreak(newHead);
    }
    if (provider.state.score > oldScore) {
      _onEat(oldFood, provider.state.score - oldScore);
    }
    if (!provider.isPlaying) {
      _accumulator = 0;
      _handleStatusChange(provider.state.status);
      return false;
    }
    return true;
  }

  void _handleStatusChange(GameStatus status) {
    final previous = _lastStatus;
    if (status == previous) {
      return;
    }
    _lastStatus = status;

    if (status == GameStatus.paused) {
      overlays.add(pauseOverlayId, priority: 20);
      // 暂停后画面完全静止，停掉主循环省下每帧的整屏重绘。
      pauseEngine();
      return;
    }

    overlays.remove(pauseOverlayId);
    resumeEngine();

    if (status == GameStatus.playing) {
      if (previous == GameStatus.idle || previous == GameStatus.over) {
        _resetForNewGame();
        _startCountdown();
      }
      return;
    }

    if (status == GameStatus.over) {
      _triggerDeath();
      return;
    }

    if (status == GameStatus.idle) {
      _countdown.stop();
      overlays.remove(countdownOverlayId);
      overlays.remove(gameOverOverlayId);
      _snake.snapToCurrent();
    }
  }

  void _resetForNewGame() {
    _accumulator = 0;
    _particles.clear();
    _scorePopups.clear();
    _flash.opacity = 0;
    _feedback.reset();
    world.timeScale = 1.0;
    _camera.reset();
    _snake.snapToCurrent();
    _countdown.stop();
    _gameOverOverlayPending = false;
    overlays.remove(gameOverOverlayId);
    overlays.remove(countdownOverlayId);
  }

  void _startCountdown() {
    _countdown.start();
    overlays.add(countdownOverlayId, priority: 10);
  }

  void _triggerDeath() {
    _countdown.stop();
    overlays.remove(countdownOverlayId);
    _accumulator = 0;
    _snake.snapToCurrent();
    _feedback.triggerDeath();
    world.timeScale = _feedback.timeScale;
    _camera.pulse();
    _camera.shake();
    _gameOverOverlayPending = true;
    _gameOverOverlayTimer = _gameOverOverlayDelay;
  }

  void _onEat(Food food, int gain) {
    final combo = _feedback.registerEat();
    final type = food.type;
    final pickupColor = type == null ? _snakeTint : powerUpColor(type);
    final baseLabel = type == null ? '+$gain' : '+$gain ${type.shortLabel}';
    final label = combo > 1 ? '$baseLabel x$combo' : baseLabel;
    _scorePopups.show(
      _cellCenter(food.position),
      label,
      _worldCellSize * 1.4,
      color: pickupColor,
    );
    _particles.burst(food.position, color: pickupColor);
  }

  void _onShieldBreak(Point head) {
    final color = powerUpColor(PowerUpType.shield);
    _particles.burst(head, color: color);
    _scorePopups.show(
      _cellCenter(head),
      'SHIELD',
      _worldCellSize * 1.2,
      color: color,
    );
  }

  void _onPortalJump(Point from, Point to) {
    _particles.burst(from, color: portalColor);
    _particles.burst(to, color: portalColor);
  }

  Vector2 _cellCenter(Point cell) {
    return Vector2(
      (cell.x + 0.5) * _worldCellSize,
      (cell.y + 0.5) * _worldCellSize,
    );
  }

  void _updateGameOverOverlay(double dt) {
    if (!_gameOverOverlayPending) {
      return;
    }
    _gameOverOverlayTimer -= dt;
    if (_gameOverOverlayTimer <= 0) {
      _gameOverOverlayPending = false;
      overlays.add(gameOverOverlayId, priority: 20);
    }
  }

  void _layoutBoard() {
    final columns = provider.state.boardWidth;
    final rows = provider.state.boardHeight;
    final cellSize = math.min(_worldSize / columns, _worldSize / rows);
    final width = cellSize * columns;
    final height = cellSize * rows;
    final left = (_worldSize - width) / 2;
    final top = (_worldSize - height) / 2;
    _worldCellSize = cellSize;

    for (final layer in _layers) {
      layer.layout(
        position: Vector2(left, top),
        size: Vector2(width, height),
        cellSize: cellSize,
      );
    }
  }
}
