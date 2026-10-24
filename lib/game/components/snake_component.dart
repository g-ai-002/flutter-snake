import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import 'board_layer_component.dart';

/// 蛇身与蛇头（含朝向眼睛）。
///
/// 逻辑层仍按格推进；渲染时用上一格位置与当前格位置做线性插值，
/// 让蛇在两次 tick 之间平滑滑动，而不是整格跳动。
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
  final Paint _crossPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;

  List<Point> _previousBody = const [];
  double _progress = 1;

  /// 新一局开始时直接对齐当前身体，避免从上一局位置滑过来。
  void snapToCurrent() {
    _previousBody = List<Point>.of(provider.state.snake.body);
    _progress = 1;
  }

  /// 在逻辑推进前记录旧身体，供本格滑动插值使用。
  void beginStep() {
    _previousBody = List<Point>.of(provider.state.snake.body);
    _progress = 0;
  }

  void setProgress(double value) {
    _progress = value.clamp(0.0, 1.0).toDouble();
  }

  @override
  void render(Canvas canvas) {
    final body = provider.state.snake.body;
    if (body.isEmpty) return;

    final from = _previousBody;
    final t = _progress.clamp(0.0, 1.0).toDouble();
    // 吃到食物时身体会多一格：把旧身体整体前移一格插值，
    // 只让新尾巴留在原处，避免增长那一 tick 整条蛇停住。
    final grew = body.length == from.length + 1;

    for (var i = 0; i < body.length; i++) {
      final target = body[i];
      final source = _sourcePoint(from, i, target, grew: grew);
      final topLeft = _interpolatedTopLeft(source, target, t);
      final isHead = i == body.length - 1;
      final alpha = 0.4 + (0.6 * i / body.length);

      _bodyPaint.color = color.withValues(alpha: alpha);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          topLeft.dx + 1,
          topLeft.dy + 1,
          cellSize - 2,
          cellSize - 2,
        ),
        Radius.circular(isHead ? 6 : 3),
      );
      canvas.drawRRect(rect, _bodyPaint);
    }

    final headSource =
        _sourcePoint(from, body.length - 1, body.last, grew: grew);
    final headCenter = _interpolatedCenter(headSource, body.last, t);
    if (provider.state.status == GameStatus.over) {
      _drawDeadEyes(canvas, headCenter);
    } else {
      _drawEyes(canvas, headCenter);
    }
  }

  Point _sourcePoint(
    List<Point> from,
    int index,
    Point fallback, {
    required bool grew,
  }) {
    if (grew) {
      if (index == 0) {
        return fallback;
      }
      final sourceIndex = index - 1;
      if (sourceIndex < from.length) {
        return from[sourceIndex];
      }
    } else if (index < from.length) {
      return from[index];
    }
    if (from.isNotEmpty) {
      return from.last;
    }
    return fallback;
  }

  Offset _interpolatedTopLeft(Point from, Point to, double t) {
    final x = from.x + (to.x - from.x) * t;
    final y = from.y + (to.y - from.y) * t;
    return Offset(x * cellSize, y * cellSize);
  }

  Offset _interpolatedCenter(Point from, Point to, double t) {
    final topLeft = _interpolatedTopLeft(from, to, t);
    return topLeft + Offset(cellSize / 2, cellSize / 2);
  }

  void _drawEyes(Canvas canvas, Offset center) {
    final eyeRadius = cellSize * 0.12;
    final pupilRadius = cellSize * 0.06;
    final offsets = _eyeOffsets(provider.state.snake.direction);
    final leftEye = center + Offset(offsets[0], offsets[1]);
    final rightEye = center + Offset(offsets[2], offsets[3]);
    final leftPupil = center + Offset(offsets[4], offsets[5]);
    final rightPupil = center + Offset(offsets[6], offsets[7]);

    canvas.drawCircle(leftEye, eyeRadius, _eyePaint);
    canvas.drawCircle(rightEye, eyeRadius, _eyePaint);
    canvas.drawCircle(leftPupil, pupilRadius, _pupilPaint);
    canvas.drawCircle(rightPupil, pupilRadius, _pupilPaint);
  }

  void _drawDeadEyes(Canvas canvas, Offset center) {
    final eyeRadius = cellSize * 0.12;
    final offsets = _eyeOffsets(provider.state.snake.direction);
    final leftEye = center + Offset(offsets[0], offsets[1]);
    final rightEye = center + Offset(offsets[2], offsets[3]);

    canvas.drawCircle(leftEye, eyeRadius, _eyePaint);
    canvas.drawCircle(rightEye, eyeRadius, _eyePaint);
    _drawCross(canvas, leftEye, eyeRadius * 0.55);
    _drawCross(canvas, rightEye, eyeRadius * 0.55);
  }

  void _drawCross(Canvas canvas, Offset center, double radius) {
    canvas.drawLine(
      center + Offset(-radius, -radius),
      center + Offset(radius, radius),
      _crossPaint,
    );
    canvas.drawLine(
      center + Offset(radius, -radius),
      center + Offset(-radius, radius),
      _crossPaint,
    );
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
