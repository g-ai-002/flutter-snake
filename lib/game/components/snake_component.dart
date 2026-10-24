import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import 'board_layer_component.dart';

/// 蛇身与蛇头（含朝向眼睛）。
class SnakeComponent extends BoardLayerComponent {
  SnakeComponent({
    required super.provider,
    required this.color,
    super.priority,
  });

  final Color color;

  final Paint _bodyPaint = Paint()..style = PaintingStyle.fill;
  final Paint _eyePaint = Paint()..color = Colors.white;
  final Paint _pupilPaint = Paint()..color = Colors.black;

  @override
  void render(Canvas canvas) {
    final body = provider.state.snake.body;
    for (var i = 0; i < body.length; i++) {
      final point = body[i];
      final isHead = i == body.length - 1;
      final alpha = 0.4 + (0.6 * i / body.length);

      _bodyPaint.color = color.withValues(alpha: alpha);
      final rect = RRect.fromRectAndRadius(
        cellRect(point.x, point.y),
        Radius.circular(isHead ? 6 : 3),
      );
      canvas.drawRRect(rect, _bodyPaint);

      if (isHead) {
        _drawEyes(canvas, point);
      }
    }
  }

  void _drawEyes(Canvas canvas, Point head) {
    final eyeRadius = cellSize * 0.12;
    final pupilRadius = cellSize * 0.06;
    final centerX = head.x * cellSize + cellSize / 2;
    final centerY = head.y * cellSize + cellSize / 2;

    final offsets = _eyeOffsets(provider.state.snake.direction);
    final leftEye = Offset(centerX + offsets[0], centerY + offsets[1]);
    final rightEye = Offset(centerX + offsets[2], centerY + offsets[3]);
    final leftPupil = Offset(centerX + offsets[4], centerY + offsets[5]);
    final rightPupil = Offset(centerX + offsets[6], centerY + offsets[7]);

    canvas.drawCircle(leftEye, eyeRadius, _eyePaint);
    canvas.drawCircle(rightEye, eyeRadius, _eyePaint);
    canvas.drawCircle(leftPupil, pupilRadius, _pupilPaint);
    canvas.drawCircle(rightPupil, pupilRadius, _pupilPaint);
  }

  List<double> _eyeOffsets(Direction dir) {
    final cs = cellSize;
    switch (dir) {
      case Direction.right:
        return [
          cs * 0.2,
          -cs * 0.2,
          cs * 0.2,
          cs * 0.2,
          cs * 0.25,
          -cs * 0.2,
          cs * 0.25,
          cs * 0.2,
        ];
      case Direction.left:
        return [
          -cs * 0.2,
          -cs * 0.2,
          -cs * 0.2,
          cs * 0.2,
          -cs * 0.25,
          -cs * 0.2,
          -cs * 0.25,
          cs * 0.2,
        ];
      case Direction.up:
        return [
          -cs * 0.2,
          -cs * 0.2,
          cs * 0.2,
          -cs * 0.2,
          -cs * 0.2,
          -cs * 0.25,
          cs * 0.2,
          -cs * 0.25,
        ];
      case Direction.down:
        return [
          -cs * 0.2,
          cs * 0.2,
          cs * 0.2,
          cs * 0.2,
          -cs * 0.2,
          cs * 0.25,
          cs * 0.2,
          cs * 0.25,
        ];
    }
  }
}
