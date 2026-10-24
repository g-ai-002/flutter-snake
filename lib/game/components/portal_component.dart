import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import 'board_layer_component.dart';

/// 传送门：成对旋转的圆环，提示棋盘上的穿越点。
class PortalComponent extends BoardLayerComponent {
  PortalComponent({
    required super.provider,
    required this.color,
    super.priority,
  });

  final Color color;

  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _corePaint = Paint();
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
    final portals = provider.state.layout.portals;
    if (portals.isEmpty) return;

    final drawn = <Point>{};
    for (final entry in portals.entries) {
      if (drawn.contains(entry.key)) continue;
      drawn.add(entry.key);
      drawn.add(entry.value);
      _drawPortal(canvas, entry.key, 1);
      _drawPortal(canvas, entry.value, -1);
    }
  }

  void _drawPortal(Canvas canvas, Point point, double spin) {
    final center = Offset(
      (point.x + 0.5) * cellSize,
      (point.y + 0.5) * cellSize,
    );
    final pulse = 0.5 + 0.5 * math.sin(_elapsed * 3 + spin);

    _glowPaint
      ..color = color.withValues(alpha: 0.16 + 0.1 * pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cellSize * 0.22);
    canvas.drawCircle(center, cellSize * 0.4, _glowPaint);

    for (var i = 0; i < 3; i++) {
      final radius = cellSize * (0.18 + i * 0.09);
      final start = _elapsed * 2.2 * spin + i * 1.1;
      _ringPaint
        ..color = color.withValues(alpha: 0.9 - i * 0.22)
        ..strokeWidth = math.max(0.8, cellSize * 0.06);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        math.pi * 1.25,
        false,
        _ringPaint,
      );
    }

    _corePaint.color = color.withValues(alpha: 0.35 + 0.2 * pulse);
    canvas.drawCircle(center, cellSize * 0.08, _corePaint);
  }
}
