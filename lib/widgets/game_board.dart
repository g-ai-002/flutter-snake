import 'package:flutter/material.dart';
import '../models/game_state.dart';

class GameBoard extends StatelessWidget {
  final GameState state;
  final Color snakeColor;
  final Color foodColor;
  final Color gridColor;
  final Color backgroundColor;

  const GameBoard({
    super.key,
    required this.state,
    required this.snakeColor,
    required this.foodColor,
    required this.gridColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final cellW = size.width / state.boardWidth;
        final cellH = size.height / state.boardHeight;
        final cellSize = cellW < cellH ? cellW : cellH;

        return Container(
          color: backgroundColor,
          child: CustomPaint(
            size: Size(cellSize * state.boardWidth, cellSize * state.boardHeight),
            painter: _BoardPainter(
              state: state,
              cellSize: cellSize,
              snakeColor: snakeColor,
              foodColor: foodColor,
              gridColor: gridColor,
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  final GameState state;
  final double cellSize;
  final Color snakeColor;
  final Color foodColor;
  final Color gridColor;

  _BoardPainter({
    required this.state,
    required this.cellSize,
    required this.snakeColor,
    required this.foodColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // 绘制网格
    for (var x = 0; x <= state.boardWidth; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, state.boardHeight * cellSize),
        gridPaint,
      );
    }
    for (var y = 0; y <= state.boardHeight; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(state.boardWidth * cellSize, y * cellSize),
        gridPaint,
      );
    }

    // 绘制食物
    final foodPaint = Paint()..color = foodColor;
    final foodRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        state.food.position.x * cellSize + 1,
        state.food.position.y * cellSize + 1,
        cellSize - 2,
        cellSize - 2,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(foodRect, foodPaint);

    // 绘制蛇身
    final body = state.snake.body;
    for (var i = 0; i < body.length; i++) {
      final p = body[i];
      final isHead = i == body.length - 1;
      final alpha = 0.4 + (0.6 * i / body.length);
      final paint = Paint()
        ..color = snakeColor.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          p.x * cellSize + 1,
          p.y * cellSize + 1,
          cellSize - 2,
          cellSize - 2,
        ),
        Radius.circular(isHead ? 6 : 3),
      );
      canvas.drawRRect(rect, paint);

      // 蛇头眼睛
      if (isHead) {
        _drawEyes(canvas, p, cellSize);
      }
    }
  }

  void _drawEyes(Canvas canvas, Point p, double cellSize) {
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black;
    final eyeR = cellSize * 0.12;
    final pupilR = cellSize * 0.06;
    final cx = p.x * cellSize + cellSize / 2;
    final cy = p.y * cellSize + cellSize / 2;

    Offset leftEye, rightEye, leftPupil, rightPupil;
    switch (state.snake.direction) {
      case Direction.right:
        leftEye = Offset(cx - cellSize * 0.2, cy - cellSize * 0.2);
        rightEye = Offset(cx - cellSize * 0.2, cy + cellSize * 0.2);
        leftPupil = Offset(cx - cellSize * 0.15, cy - cellSize * 0.2);
        rightPupil = Offset(cx - cellSize * 0.15, cy + cellSize * 0.2);
        break;
      case Direction.left:
        leftEye = Offset(cx + cellSize * 0.2, cy - cellSize * 0.2);
        rightEye = Offset(cx + cellSize * 0.2, cy + cellSize * 0.2);
        leftPupil = Offset(cx + cellSize * 0.15, cy - cellSize * 0.2);
        rightPupil = Offset(cx + cellSize * 0.15, cy + cellSize * 0.2);
        break;
      case Direction.up:
        leftEye = Offset(cx - cellSize * 0.2, cy + cellSize * 0.2);
        rightEye = Offset(cx + cellSize * 0.2, cy + cellSize * 0.2);
        leftPupil = Offset(cx - cellSize * 0.2, cy + cellSize * 0.15);
        rightPupil = Offset(cx + cellSize * 0.2, cy + cellSize * 0.15);
        break;
      case Direction.down:
        leftEye = Offset(cx - cellSize * 0.2, cy - cellSize * 0.2);
        rightEye = Offset(cx + cellSize * 0.2, cy - cellSize * 0.2);
        leftPupil = Offset(cx - cellSize * 0.2, cy - cellSize * 0.15);
        rightPupil = Offset(cx + cellSize * 0.2, cy - cellSize * 0.15);
        break;
    }

    canvas.drawCircle(leftEye, eyeR, eyePaint);
    canvas.drawCircle(rightEye, eyeR, eyePaint);
    canvas.drawCircle(leftPupil, pupilR, pupilPaint);
    canvas.drawCircle(rightPupil, pupilR, pupilPaint);
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
