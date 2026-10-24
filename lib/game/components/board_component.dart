import 'package:flutter/material.dart';

import 'board_layer_component.dart';

/// 棋盘背景与网格线。
class BoardComponent extends BoardLayerComponent {
  BoardComponent({
    required super.provider,
    required this.backgroundColor,
    required this.gridColor,
    super.priority,
  });

  final Color backgroundColor;
  final Color gridColor;

  late final Paint _backgroundPaint = Paint()..color = backgroundColor;
  late final Paint _gridPaint = Paint()
    ..color = gridColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), _backgroundPaint);

    for (var x = 0; x <= columns; x++) {
      final dx = x * cellSize;
      canvas.drawLine(Offset(dx, 0), Offset(dx, height), _gridPaint);
    }
    for (var y = 0; y <= rows; y++) {
      final dy = y * cellSize;
      canvas.drawLine(Offset(0, dy), Offset(width, dy), _gridPaint);
    }
  }
}
