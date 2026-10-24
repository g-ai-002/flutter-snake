import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../providers/game_provider.dart';

/// 棋盘图层的公共基类，负责统一的棋盘几何信息。
abstract class BoardLayerComponent extends PositionComponent {
  BoardLayerComponent({
    required this.provider,
    super.priority,
  });

  final GameProvider provider;

  /// 单个格子的边长（逻辑像素）。
  double cellSize = 0;

  int get columns => provider.state.boardWidth;
  int get rows => provider.state.boardHeight;

  void layout({
    required Vector2 position,
    required Vector2 size,
    required double cellSize,
  }) {
    this.position = position;
    this.size = size;
    this.cellSize = cellSize;
  }

  Rect cellRect(int x, int y, {double inset = 1}) {
    return Rect.fromLTWH(
      x * cellSize + inset,
      y * cellSize + inset,
      cellSize - inset * 2,
      cellSize - inset * 2,
    );
  }
}
