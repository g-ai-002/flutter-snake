import 'package:flutter/material.dart';

import 'board_layer_component.dart';

/// 游戏结束时的红色闪屏层。
class DeathFlashComponent extends BoardLayerComponent {
  DeathFlashComponent({
    required super.provider,
    super.priority,
  });

  static const Color _flashColor = Color(0xFFFF3B30);

  final Paint _paint = Paint();
  double opacity = 0;

  @override
  void render(Canvas canvas) {
    if (opacity <= 0) return;
    _paint.color =
        _flashColor.withValues(alpha: opacity.clamp(0.0, 1.0).toDouble());
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), _paint);
  }
}
