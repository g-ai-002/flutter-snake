import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../power_up_style.dart';
import 'board_layer_component.dart';

/// 食物/道具方块：普通食物为圆角方块，道具为彩色菱形。
class FoodComponent extends BoardLayerComponent {
  FoodComponent({
    required super.provider,
    required this.color,
    super.priority,
  });

  final Color color;

  late final Paint _paint = Paint()..color = color;
  final Paint _glowPaint = Paint();
  final Paint _specialPaint = Paint();
  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  final Paint _accentPaint = Paint()..color = Colors.white;

  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (provider.isPlaying) {
      _elapsed += dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final food = provider.state.food;
    final type = food.type;
    final baseColor = type == null ? color : powerUpColor(type);
    final pulse = 0.5 + 0.5 * math.sin(_elapsed * 6);
    final center = Offset(
      food.position.x * cellSize + cellSize / 2,
      food.position.y * cellSize + cellSize / 2,
    );

    _glowPaint.color = baseColor.withValues(alpha: 0.1 + 0.1 * pulse);
    canvas.drawCircle(center, cellSize * (0.34 + 0.08 * pulse), _glowPaint);

    if (type == null) {
      final inset = 1 + pulse * 0.9;
      final rect = RRect.fromRectAndRadius(
        cellRect(food.position.x, food.position.y, inset: inset),
        Radius.circular(4 + pulse),
      );
      canvas.drawRRect(rect, _paint);
      return;
    }

    final size = cellSize * (0.32 + 0.04 * pulse);
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size, center.dy)
      ..close();
    _specialPaint.color = baseColor;
    canvas.drawPath(path, _specialPaint);

    _accentPaint.color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(center, cellSize * 0.07, _accentPaint);

    _ringPaint.color = baseColor.withValues(alpha: 0.35 + 0.2 * pulse);
    canvas.drawCircle(center, cellSize * (0.44 + 0.04 * pulse), _ringPaint);
  }
}
