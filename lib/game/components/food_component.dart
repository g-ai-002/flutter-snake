import 'package:flutter/material.dart';

import 'board_layer_component.dart';

/// 食物方块。
class FoodComponent extends BoardLayerComponent {
  FoodComponent({
    required super.provider,
    required this.color,
    super.priority,
  });

  final Color color;

  late final Paint _paint = Paint()..color = color;

  @override
  void render(Canvas canvas) {
    final food = provider.state.food.position;
    final rect = RRect.fromRectAndRadius(
      cellRect(food.x, food.y),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, _paint);
  }
}
