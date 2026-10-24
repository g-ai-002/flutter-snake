import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'components/board_component.dart';
import 'components/board_layer_component.dart';
import 'components/death_flash_component.dart';
import 'components/food_component.dart';
import 'components/particle_burst_component.dart';
import 'components/score_popup_layer.dart';
import 'components/snake_component.dart';
import 'snake_world.dart';

const double _worldSize = 400;

/// 基于 Flame 的贪吃蛇游戏。
///
/// 棋盘、食物、蛇、粒子和飘字都放在 [World] 中，由固定分辨率的
/// [CameraComponent] 统一缩放与做缩放/震动特效；游戏规则仍由
/// [GameProvider] 持有。
class SnakeGame extends FlameGame<SnakeWorld> {
  SnakeGame({
    required this.provider,
    required this.surfaceColor,
    required this.snakeColor,
    required this.foodColor,
    required this.gridColor,
  }) : super(
          world: SnakeWorld(),
          camera: CameraComponent.withFixedResolution(
            width: _worldSize,
            height: _worldSize,
          ),
        );

  static const String pauseOverlayId = 'pause';
  static const String countdownOverlayId = 'countdown';
  static const String gameOverOverlayId = 'gameOver';

  final GameProvider provider;
  final Color surfaceColor;
  final Color snakeColor;
  final Color foodColor;
  final Color gridColor;

  /// 开局倒计时：3、2、1、0（0 显示 GO）。
  final ValueNotifier<int> countdown = ValueNotifier<int>(0);

  late final BoardComponent _board;
  late final FoodComponent _food;
  late final SnakeComponent _snake;
  late final ParticleBurstComponent _particles;
  late final DeathFlashComponent _flash;
  late final ScorePopupLayer _scorePopups;
  late final List<BoardLayerComponent> _layers;

  final math.Random _random = math.Random();

  Vector2 _cameraBase = Vector2(_worldSize / 2, _worldSize / 2);
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

  @override
  Future<void> onLoad() async {
    _board = BoardComponent(
      provider: provider,
      backgroundColor: surfaceColor,
      gridColor: gridColor,
    );
    _food = FoodComponent(
      provider: provider,
      color: foodColor,
      priority: 1,
    );
    _snake = SnakeComponent(
      provider: provider,
      color: snakeColor,
      priority: 2,
    );
    _particles = ParticleBurstComponent(
      provider: provider,
      color: foodColor,
      priority: 3,
    );
    _flash = DeathFlashComponent(
      provider: provider,
      priority: 4,
    );
    _scorePopups = ScorePopupLayer(color: snakeColor);

    _layers = <BoardLayerComponent>[
      _board,
      _food,
      _snake,
      _particles,
      _flash,
    ];
    _layoutBoard();

    await world.addAll(<Component>[..._layers, _scorePopups]);

    _cameraBase = Vector2(_worldSize / 2, _worldSize / 2);
    camera.viewfinder.position = _cameraBase;
    camera.viewfinder.zoom = 1;
    _ready = true;
    _snake.snapToCurrent();
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

    if (_comboTimer > 0) {
      _comboTimer = math.max(0.0, _comboTimer - dt);
      if (_comboTimer == 0) {
        _combo = 1;
      }
    }

    final step = provider.state.speedMs / 1000;
    if (step <= 0) {
      return;
    }

    _accumulator += dt;
    var steps = 0;
    while (_accumulator >= step && steps < _maxStepsPerFrame) {
      final oldFood = provider.state.food.position;
      final oldScore = provider.state.score;

      _accumulator -= step;
      steps++;
      _snake.beginStep();
      provider.tick();

      if (provider.state.score > oldScore) {
        _onEat(oldFood);
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
      return;
    }

    overlays.remove(pauseOverlayId);

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
    _cameraBase = Vector2(_worldSize / 2, _worldSize / 2);
    camera.viewfinder.position = _cameraBase;
    camera.viewfinder.zoom = 1;
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

  void _onEat(Point oldFood) {
    _combo = _comboTimer > 0 ? _combo + 1 : 1;
    _comboTimer = _comboWindow;
    final label = _combo > 1 ? '+10  x$_combo' : '+10';
    final position = Vector2(
      (oldFood.x + 0.5) * _worldCellSize,
      (oldFood.y + 0.5) * _worldCellSize,
    );
    _scorePopups.show(position, label, _worldCellSize * 1.4);
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
    camera.viewfinder.zoom = 1 + _zoomStrength * eased;

    if (_shakeRemaining > 0) {
      _shakeRemaining = math.max(0.0, _shakeRemaining - dt);
      final strength =
          _worldSize * 0.012 * (_shakeRemaining / _shakeDuration);
      camera.viewfinder.position = Vector2(
        _cameraBase.x + (_random.nextDouble() * 2 - 1) * strength,
        _cameraBase.y + (_random.nextDouble() * 2 - 1) * strength,
      );
    } else {
      camera.viewfinder.position = _cameraBase;
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
