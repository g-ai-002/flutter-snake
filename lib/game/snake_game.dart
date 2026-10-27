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
import 'board_camera.dart';
import 'components/board_component.dart';
import 'components/board_layer_component.dart';
import 'components/death_flash_component.dart';
import 'components/food_component.dart';
import 'components/particle_burst_component.dart';
import 'components/portal_component.dart';
import 'components/score_popup_layer.dart';
import 'components/snake_component.dart';
import 'components/wall_component.dart';
import 'input/canvas_gesture_layer.dart';
import 'input/direction_input.dart';
import 'power_up_style.dart';
import 'skins/skin_sprites.dart';
import 'skins/skin_style.dart';
import 'snake_world.dart';

const double _worldSize = 400;

/// 基于 Flame 的贪吃蛇游戏。
///
/// 棋盘、食物、蛇、粒子和飘字都放在 [World] 中，相机把 400×400 的世界棋盘
/// 对齐到 Flutter 侧给出的棋盘槽位；画布铺满整个游戏页，棋盘以外的区域由
/// 悬浮的 Flutter HUD 覆盖。游戏规则仍由 [GameProvider] 持有。
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
        );

  static const String pauseOverlayId = 'pause';
  static const String countdownOverlayId = 'countdown';
  static const String gameOverOverlayId = 'gameOver';

  final GameProvider provider;
  final Color surfaceColor;
  final Color snakeColor;
  final Color foodColor;
  final Color gridColor;
  final Color wallColor;
  final Color portalColor;
  final SnakeSkin skin;

  /// 开局倒计时：3、2、1、0（0 显示 GO）。
  final ValueNotifier<int> countdown = ValueNotifier<int>(0);

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

  final math.Random _random = math.Random();

  Vector2 _cameraBase = Vector2(_worldSize / 2, _worldSize / 2);
  Size _canvasSize = Size.zero;
  Rect _boardRect = Rect.zero;
  double _baseZoom = 1;
  double _worldCellSize = 0;

  bool _ready = false;
  double _accumulator = 0;
  GameStatus _lastStatus = GameStatus.idle;

  double _zoomPulse = 0;
  double _zoomStrength = 0.025;
  double _shakeRemaining = 0;
  double _flashRemaining = 0;
  double _slowMotionRemaining = 0;

  bool _countdownActive = false;
  double _countdownRemaining = 0;
  double _goRemaining = 0;

  bool _gameOverOverlayPending = false;
  double _gameOverOverlayDelay = 0;

  int _combo = 1;
  double _comboTimer = 0;

  static const int _maxStepsPerFrame = 4;
  static const double _zoomDuration = 0.28;
  static const double _shakeDuration = 0.45;
  static const double _flashDuration = 0.3;
  static const double _slowMotionDuration = 0.45;
  static const double _slowMotionScale = 0.35;
  static const double _comboWindow = 2.5;
  static const double _countdownSeconds = 3.0;

  @override
  Color backgroundColor() => surfaceColor;

  Color get _snakeTint => snakeSkinColor(skin) ?? snakeColor;

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

    final key = event.logicalKey;
    Direction? direction;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW) {
      direction = Direction.up;
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      direction = Direction.down;
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      direction = Direction.left;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      direction = Direction.right;
    }
    if (direction != null) {
      provider.changeDirection(direction);
      return KeyEventResult.handled;
    }

    if (isDown &&
        (key == LogicalKeyboardKey.space ||
            key == LogicalKeyboardKey.keyP ||
            key == LogicalKeyboardKey.escape)) {
      provider.togglePause();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Future<void> onLoad() async {
    final snakeTint = snakeSkinColor(skin) ?? snakeColor;
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
      color: snakeTint,
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
    _scorePopups = ScorePopupLayer(color: snakeTint);

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

    _canvasSize = Size(size.x, size.y);
    _applyCamera();
    _ready = true;
    _snake.snapToCurrent();
    provider.addListener(_handleProviderChange);
  }

  @override
  void onRemove() {
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
    _canvasSize = Size(size.x, size.y);
    _applyCamera();
  }

  /// Flutter 侧把棋盘槽位的页面矩形同步过来，相机据此把世界棋盘画在槽位里。
  void updateBoardLayout({required Rect boardRect, required Size canvasSize}) {
    if (_boardRect == boardRect && _canvasSize == canvasSize) {
      return;
    }
    _boardRect = boardRect;
    _canvasSize = canvasSize;
    _applyCamera();
  }

  /// 点击画布任意位置：按点击点相对棋盘中心的方向转向。
  void handleTap(Offset position) {
    if (_boardRect.isEmpty) {
      return;
    }
    final direction = directionFromTap(
      position - _boardRect.topLeft,
      _boardRect.size,
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

  void _applyCamera() {
    if (_boardRect.isEmpty || _canvasSize.isEmpty) {
      return;
    }
    final layout = _layoutFor();
    _baseZoom = layout.zoom;
    _cameraBase = layout.position;
    camera.viewfinder.zoom = _baseZoom;
    camera.viewfinder.position = _cameraBase;
  }

  BoardCameraLayout _layoutFor([double? zoom]) {
    if (_boardRect.isEmpty || _canvasSize.isEmpty) {
      return BoardCameraLayout(zoom: _baseZoom, position: _cameraBase.clone());
    }
    return cameraLayoutForBoard(
      canvasSize: _canvasSize,
      boardRect: _boardRect,
      worldBoardRect: const Rect.fromLTWH(0, 0, _worldSize, _worldSize),
      zoom: zoom,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready) {
      return;
    }

    _updateSlowMotion(dt);
    final visualDt = _slowMotionRemaining > 0 ? dt * _slowMotionScale : dt;
    _updateCamera(visualDt);
    _updateFeedback(visualDt);
    _updateGameOverOverlay(dt);

    final status = provider.state.status;
    if (status != _lastStatus) {
      _handleStatusChange(status);
    }
    if (status != GameStatus.playing) {
      return;
    }

    if (_countdownActive) {
      _updateCountdown(dt);
      provider.unlockDirection();
      return;
    }

    provider.updateEffects(dt);

    if (_comboTimer > 0) {
      _comboTimer = math.max(0.0, _comboTimer - dt);
      if (_comboTimer == 0) {
        _combo = 1;
      }
    }

    final step = provider.effectiveSpeedMs / 1000;
    if (step <= 0) {
      return;
    }

    _accumulator += dt;
    var steps = 0;
    while (_accumulator >= step && steps < _maxStepsPerFrame) {
      final oldFood = provider.state.food;
      final oldScore = provider.state.score;
      final hadShield = provider.hasShield;
      final previousHead = provider.state.snake.head;

      _accumulator -= step;
      steps++;
      _snake.beginStep();
      provider.tick();

      final newHead = provider.state.snake.head;
      if ((newHead.x - previousHead.x).abs() > 1 ||
          (newHead.y - previousHead.y).abs() > 1) {
        _onPortalJump(previousHead, newHead);
      }
      if (hadShield && !provider.hasShield && provider.isPlaying) {
        _onShieldBreak(provider.state.snake.head);
      }
      if (provider.state.score > oldScore) {
        _onEat(oldFood, provider.state.score - oldScore);
      }
      if (!provider.isPlaying) {
        _accumulator = 0;
        _handleStatusChange(provider.state.status);
        return;
      }
    }
    if (_accumulator >= step) {
      _accumulator = 0;
    }

    _snake.setProgress(_accumulator / step);
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
      _countdownActive = false;
      countdown.value = 0;
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
    _flashRemaining = 0;
    _shakeRemaining = 0;
    _zoomPulse = 0;
    _zoomStrength = 0.025;
    _slowMotionRemaining = 0;
    world.timeScale = 1.0;
    _applyCamera();
    _snake.snapToCurrent();
    _combo = 1;
    _comboTimer = 0;
    _countdownActive = false;
    countdown.value = 0;
    _gameOverOverlayPending = false;
    overlays.remove(gameOverOverlayId);
    overlays.remove(countdownOverlayId);
  }

  void _startCountdown() {
    _countdownActive = true;
    _countdownRemaining = _countdownSeconds;
    _goRemaining = 0;
    countdown.value = 3;
    overlays.add(countdownOverlayId, priority: 10);
  }

  void _updateCountdown(double dt) {
    if (_countdownRemaining > 0) {
      _countdownRemaining -= dt;
      final value = _countdownRemaining.ceil().clamp(1, 3).toInt();
      if (countdown.value != value) {
        countdown.value = value;
      }
      if (_countdownRemaining <= 0) {
        _goRemaining = 0.45;
        countdown.value = 0;
      }
      return;
    }

    _goRemaining -= dt;
    if (_goRemaining <= 0) {
      _countdownActive = false;
      overlays.remove(countdownOverlayId);
    }
  }

  void _triggerDeath() {
    _countdownActive = false;
    countdown.value = 0;
    overlays.remove(countdownOverlayId);
    _accumulator = 0;
    _snake.snapToCurrent();
    _combo = 1;
    _comboTimer = 0;
    _slowMotionRemaining = _slowMotionDuration;
    world.timeScale = _slowMotionScale;
    _zoomPulse = 1;
    _zoomStrength = 0.06;
    _shakeRemaining = _shakeDuration;
    _flashRemaining = _flashDuration;
    _gameOverOverlayPending = true;
    _gameOverOverlayDelay = 0.55;
  }

  void _onEat(Food food, int gain) {
    _combo = _comboTimer > 0 ? _combo + 1 : 1;
    _comboTimer = _comboWindow;
    final type = food.type;
    final pickupColor = type == null ? _snakeTint : powerUpColor(type);
    final baseLabel = type == null ? '+$gain' : '+$gain ${type.shortLabel}';
    final label = _combo > 1 ? '$baseLabel x$_combo' : baseLabel;
    final position = Vector2(
      (food.position.x + 0.5) * _worldCellSize,
      (food.position.y + 0.5) * _worldCellSize,
    );
    _scorePopups.show(
      position,
      label,
      _worldCellSize * 1.4,
      color: pickupColor,
    );
    _particles.burst(food.position, color: pickupColor);
  }

  void _onShieldBreak(Point head) {
    final color = powerUpColor(PowerUpType.shield);
    final position = Vector2(
      (head.x + 0.5) * _worldCellSize,
      (head.y + 0.5) * _worldCellSize,
    );
    _particles.burst(head, color: color);
    _scorePopups.show(
      position,
      'SHIELD',
      _worldCellSize * 1.2,
      color: color,
    );
  }

  void _onPortalJump(Point from, Point to) {
    _particles.burst(from, color: portalColor);
    _particles.burst(to, color: portalColor);
  }

  void _updateSlowMotion(double dt) {
    if (_slowMotionRemaining <= 0) {
      if (world.timeScale != 1.0) {
        world.timeScale = 1.0;
      }
      return;
    }
    _slowMotionRemaining = math.max(0.0, _slowMotionRemaining - dt);
    world.timeScale = _slowMotionRemaining > 0 ? _slowMotionScale : 1.0;
  }

  void _updateCamera(double dt) {
    _zoomPulse = math.max(0.0, _zoomPulse - dt / _zoomDuration);
    final eased = 1 - (1 - _zoomPulse) * (1 - _zoomPulse);
    final zoom = _baseZoom * (1 + _zoomStrength * eased);
    final base = _layoutFor(zoom).position;
    _cameraBase = base;
    camera.viewfinder.zoom = zoom;

    if (_shakeRemaining > 0) {
      _shakeRemaining = math.max(0.0, _shakeRemaining - dt);
      final strength =
          _worldSize * 0.012 * (_shakeRemaining / _shakeDuration);
      camera.viewfinder.position = Vector2(
        base.x + (_random.nextDouble() * 2 - 1) * strength,
        base.y + (_random.nextDouble() * 2 - 1) * strength,
      );
    } else {
      camera.viewfinder.position = base;
    }
  }

  void _updateFeedback(double dt) {
    if (_flashRemaining > 0) {
      _flashRemaining = math.max(0.0, _flashRemaining - dt);
      _flash.opacity = 0.42 * (_flashRemaining / _flashDuration);
    }
  }

  void _updateGameOverOverlay(double dt) {
    if (!_gameOverOverlayPending) {
      return;
    }
    _gameOverOverlayDelay -= dt;
    if (_gameOverOverlayDelay <= 0) {
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
