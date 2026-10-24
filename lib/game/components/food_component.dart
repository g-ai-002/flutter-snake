import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'board_layer_component.dart';

/// 食物方块，带轻微的呼吸脉冲与光晕。
class FoodComponent extends BoardLayerComponent {
  FoodComponent({
    required super.provider,
    required this.color,
    super.priority,
  });

  final Color color;

  late final Paint _paint = Paint()..color = color;
  final Paint _glowPaint = Paint();

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
    final food = provider.state.food.position;
    final pulse = 0.5 + 0.5 * math.sin(_elapsed * 6);
    final center = Offset(
      food.x * cellSize + cellSize / 2,
      food.y * cellSize + cellSize / 2,
    );

    _glowPaint.color = color.withValues(alpha: 0.1 + 0.1 * pulse);
    canvas.drawCircle(center, cellSize * (0.34 + 0.08 * pulse), _glowPaint);

    final inset = 1 + pulse * 0.9;
    final rect = RRect.fromRectAndRadius(
      cellRect(food.x, food.y, inset: inset),
      Radius.circular(4 + pulse),
    );
    canvas.drawRRect(rect, _paint);
  }
}
