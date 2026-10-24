import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../models/skin.dart';
import '../power_up_style.dart';
import '../skins/skin_sprites.dart';
import 'board_layer_component.dart';

/// 食物/道具方块。
///
/// 普通食物在贴图皮肤下播放逐帧动画，其余情况保持呼吸圆角方块；
/// 道具始终使用彩色菱形，便于与普通食物区分。
class FoodComponent extends BoardLayerComponent {
  FoodComponent({
    required super.provider,
    required this.color,
    required this.skin,
    required this.sprites,
    super.priority,
  });

  final Color color;
  final SnakeSkin skin;
  final SkinSprites sprites;

  late final Paint _paint = Paint()..color = color;
  final Paint _glowPaint = Paint();
  final Paint _specialPaint = Paint();
  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  final Paint _accentPaint = Paint()..color = Colors.white;
  final Paint _spritePaint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

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
    final frames = sprites.foodFrames;
    final center = Offset(
      food.position.x * cellSize + cellSize / 2,
      food.position.y * cellSize + cellSize / 2,
    );

    _glowPaint.color = baseColor.withValues(alpha: 0.1 + 0.1 * pulse);
    canvas.drawCircle(center, cellSize * (0.34 + 0.08 * pulse), _glowPaint);

    if (type == null) {
      if (skin.usesSprites && frames.isNotEmpty) {
        _drawAnimatedFood(canvas, frames, center, pulse);
      } else {
        _drawVectorFood(canvas, food.position, pulse);
      }
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

  void _drawAnimatedFood(
    Canvas canvas,
    List<ui.Image> frames,
    Offset center,
    double pulse,
  ) {
    final frameIndex =
        (_elapsed * skin.foodAnimationFps).floor() % frames.length;
    final image = frames[frameIndex];
    final size = cellSize * (0.8 + 0.06 * pulse);
    _spritePaint.color = Colors.white;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromCenter(center: center, width: size, height: size),
      _spritePaint,
    );
  }

  void _drawVectorFood(Canvas canvas, Point position, double pulse) {
    final inset = 1 + pulse * 0.9;
    final rect = RRect.fromRectAndRadius(
      cellRect(position.x, position.y, inset: inset),
      Radius.circular(4 + pulse),
    );
    canvas.drawRRect(rect, _paint);
  }
}
