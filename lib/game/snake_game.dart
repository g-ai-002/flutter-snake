import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'components/board_component.dart';
import 'components/board_layer_component.dart';
import 'components/death_flash_component.dart';
import 'components/food_component.dart';
import 'components/particle_burst_component.dart';
import 'components/snake_component.dart';

/// 基于 Flame 的贪吃蛇游戏。
///
/// 棋盘渲染与游戏循环交给 Flame：每个渲染帧累积 `dt`，达到当前的移动间隔
/// （[GameState.speedMs]）就调用一次 [GameProvider.tick]。游戏规则本身仍由
/// [GameProvider] 持有，便于脱离渲染层做单元测试。
class SnakeGame extends FlameGame {
  SnakeGame({
    required this.provider,
    required this.surfaceColor,
    required this.snakeColor,
    required this.foodColor,
    required this.gridColor,
  });

  /// 暂停遮罩的 Flame overlay 名称。
  static const String pauseOverlayId = 'pause';

  final GameProvider provider;
  final Color surfaceColor;
  final Color snakeColor;
  final Color foodColor;
  final Color gridColor;

  late final BoardComponent _board;
  late final FoodComponent _food;
  late final SnakeComponent _snake;
  late final ParticleBurstComponent _particles;
  late final DeathFlashComponent _flash;
  late final List<BoardLayerComponent> _layers;

  final math.Random _random = math.Random();

  Vector2 _boardOrigin = Vector2(0, 0);
  Vector2 _shakeOffset = Vector2(0, 0);
  double _cellSize = 0;

  bool _ready = false;
  double _accumulator = 0;
  GameStatus _lastStatus = GameStatus.idle;

  double _shakeRemaining = 0;
  double _flashRemaining = 0;

  /// 单帧最多补算的步数，避免应用恢复前台后瞬间连续移动。
  static const int _maxStepsPerFrame = 4;
  static const double _shakeDuration = 0.32;
  static const double _flashDuration = 0.3;

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

    _layers = <BoardLayerComponent>[
      _board,
      _food,
      _snake,
      _particles,
      _flash,
    ];

    await addAll(_layers);
    _ready = true;
    _applyLayout(size);
    _snake.snapToCurrent();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_ready) {
      _applyLayout(size);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready) {
      return;
    }

    _updateFeedback(dt);

    final status = provider.state.status;
    if (status != _lastStatus) {
      _handleStatusChange(status);
    }
    if (status != GameStatus.playing) {
      return;
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
        _particles.burst(oldFood);
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
      overlays.add(pauseOverlayId);
      return;
    }

    overlays.remove(pauseOverlayId);

    if (status == GameStatus.playing) {
      if (previous == GameStatus.idle || previous == GameStatus.over) {
        _resetForNewGame();
      }
      return;
    }

    if (status == GameStatus.over) {
      _accumulator = 0;
      _snake.snapToCurrent();
      _triggerDeath();
      return;
    }

    if (status == GameStatus.idle) {
      _accumulator = 0;
      _snake.snapToCurrent();
    }
  }

  void _resetForNewGame() {
    _accumulator = 0;
    _particles.clear();
    _flash.opacity = 0;
    _flashRemaining = 0;
    _shakeRemaining = 0;
    _shakeOffset = Vector2(0, 0);
    _positionLayers();
    _snake.snapToCurrent();
  }

  void _triggerDeath() {
    _shakeRemaining = _shakeDuration;
    _flashRemaining = _flashDuration;
  }

  void _updateFeedback(double dt) {
    if (_shakeRemaining > 0) {
      _shakeRemaining = math.max(0.0, _shakeRemaining - dt);
      if (_shakeRemaining <= 0) {
        _shakeOffset = Vector2(0, 0);
      } else {
        final strength = _cellSize * 0.18 * (_shakeRemaining / _shakeDuration);
        _shakeOffset = Vector2(
          (_random.nextDouble() * 2 - 1) * strength,
          (_random.nextDouble() * 2 - 1) * strength,
        );
      }
      _positionLayers();
    }

    if (_flashRemaining > 0) {
      _flashRemaining = math.max(0.0, _flashRemaining - dt);
      _flash.opacity = 0.42 * (_flashRemaining / _flashDuration);
    }
  }

  void _applyLayout(Vector2 gameSize) {
    final columns = provider.state.boardWidth;
    final rows = provider.state.boardHeight;
    final cellSize = math.min(gameSize.x / columns, gameSize.y / rows);
    final width = cellSize * columns;
    final height = cellSize * rows;
    final left = (gameSize.x - width) / 2;
    final top = (gameSize.y - height) / 2;

    _boardOrigin = Vector2(left, top);
    _cellSize = cellSize;
    _shakeOffset = Vector2(0, 0);

    for (final layer in _layers) {
      layer.layout(
        position: Vector2(left, top),
        size: Vector2(width, height),
        cellSize: cellSize,
      );
    }
  }

  void _positionLayers() {
    final x = _boardOrigin.x + _shakeOffset.x;
    final y = _boardOrigin.y + _shakeOffset.y;
    for (final layer in _layers) {
      layer.position = Vector2(x, y);
    }
  }
}
