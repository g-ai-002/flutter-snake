import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'components/board_component.dart';
import 'components/board_layer_component.dart';
import 'components/food_component.dart';
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

  final GameProvider provider;
  final Color surfaceColor;
  final Color snakeColor;
  final Color foodColor;
  final Color gridColor;

  late final BoardComponent _board;
  late final FoodComponent _food;
  late final SnakeComponent _snake;

  bool _ready = false;
  double _accumulator = 0;
  GameStatus _lastStatus = GameStatus.idle;

  /// 单帧最多补算的步数，避免应用恢复前台后瞬间连续移动。
  static const int _maxStepsPerFrame = 4;

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

    await addAll([_board, _food, _snake]);
    _ready = true;
    _applyLayout(size);
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

    final status = provider.state.status;
    if (status != _lastStatus) {
      _lastStatus = status;
      _accumulator = 0;
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
      _accumulator -= step;
      steps++;
      provider.tick();
      if (!provider.isPlaying) {
        _accumulator = 0;
        return;
      }
    }
    if (_accumulator >= step) {
      _accumulator = 0;
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

    for (final layer in <BoardLayerComponent>[_board, _food, _snake]) {
      layer.layout(
        position: Vector2(left, top),
        size: Vector2(width, height),
        cellSize: cellSize,
      );
    }
  }
}
