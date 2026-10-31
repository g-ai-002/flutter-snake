import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import 'board_layer_component.dart';

/// 关卡障碍物：按格绘制带高光的围墙砖块。
///
/// 一局内墙体与格子尺寸都不变，因此整片墙录制为 [ui.Picture] 缓存，
/// 逐帧只回放绘制指令，避免每帧重画上百块砖。
class WallComponent extends BoardLayerComponent {
  WallComponent({
    required super.provider,
    required this.color,
    super.priority,
  });

  final Color color;

  final Paint _fillPaint = Paint();
  final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _highlightPaint = Paint()
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;

  ui.Picture? _picture;
  double _cachedCellSize = -1;
  Set<Point>? _cachedWalls;

  @override
  void render(Canvas canvas) {
    final walls = provider.state.layout.walls;
    if (walls.isEmpty) return;

    if (_picture == null ||
        _cachedCellSize != cellSize ||
        !identical(_cachedWalls, walls)) {
      _picture?.dispose();
      _picture = _buildPicture(walls);
      _cachedCellSize = cellSize;
      _cachedWalls = walls;
    }
    canvas.drawPicture(_picture!);
  }

  ui.Picture _buildPicture(Set<Point> walls) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final radius = Radius.circular(cellSize * 0.18);
    _fillPaint.color = color.withValues(alpha: 0.9);
    _borderPaint.color = Colors.black.withValues(alpha: 0.28);
    _highlightPaint.color = Colors.white.withValues(alpha: 0.28);

    for (final point in walls) {
      final rect = RRect.fromRectAndRadius(
        cellRect(point.x, point.y, inset: 0.6),
        radius,
      );
      canvas.drawRRect(rect, _fillPaint);
      canvas.drawRRect(rect, _borderPaint);

      final left = point.x * cellSize + cellSize * 0.22;
      final top = point.y * cellSize + cellSize * 0.22;
      canvas.drawLine(
        Offset(left, top),
        Offset(left + cellSize * 0.4, top),
        _highlightPaint,
      );
    }
    return recorder.endRecording();
  }

  @override
  void onRemove() {
    _picture?.dispose();
    _picture = null;
    super.onRemove();
  }
}
