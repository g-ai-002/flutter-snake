import 'package:flutter/material.dart';

import 'board_layer_component.dart';

/// 关卡障碍物：按格绘制带高光的围墙砖块。
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

  @override
  void render(Canvas canvas) {
    final walls = provider.state.layout.walls;
    if (walls.isEmpty) return;

    for (final point in walls) {
      final rect = RRect.fromRectAndRadius(
        cellRect(point.x, point.y, inset: 0.6),
        Radius.circular(cellSize * 0.18),
      );
      _fillPaint.color = color.withValues(alpha: 0.9);
      canvas.drawRRect(rect, _fillPaint);

      _borderPaint.color = Colors.black.withValues(alpha: 0.28);
      canvas.drawRRect(rect, _borderPaint);

      final left = point.x * cellSize + cellSize * 0.22;
      final top = point.y * cellSize + cellSize * 0.22;
      _highlightPaint.color = Colors.white.withValues(alpha: 0.28);
      canvas.drawLine(
        Offset(left, top),
        Offset(left + cellSize * 0.4, top),
        _highlightPaint,
      );
    }
  }
}
