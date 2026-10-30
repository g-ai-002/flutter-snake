import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../models/skin.dart';
import '../power_up_style.dart';
import '../skins/skin_sprites.dart';
import '../skins/skin_style.dart';
import 'board_layer_component.dart';

/// 蛇身与蛇头（含朝向眼睛）。
///
/// 逻辑层仍按格推进；渲染时用上一格位置与当前格位置做线性插值，
/// 让蛇在两次 tick 之间平滑滑动。贴图皮肤使用 16×16 精灵，
/// 矢量皮肤沿用圆角方块，霓虹皮肤额外叠加发光描边。
class SnakeComponent extends BoardLayerComponent {
  SnakeComponent({
    required super.provider,
    required this.color,
    required this.skin,
    required this.sprites,
    super.priority,
  });

  final Color color;
  final SnakeSkin skin;
  final SkinSprites sprites;

  final Paint _bodyPaint = Paint()..style = PaintingStyle.fill;
  final Paint _eyePaint = Paint()..color = Colors.white;
  final Paint _pupilPaint = Paint()..color = Colors.black;
  final Paint _crossPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;
  final Paint _auraPaint = Paint();
  final Paint _glowPaint = Paint();
  final Paint _spritePaint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  List<Point> _previousBody = const [];
  double _progress = 1;

  bool get _useSprites => skin.usesSprites && sprites.isReady;

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

      if (_useSprites) {
        _drawSpriteSegment(canvas, body, i, topLeft, alpha);
      } else {
        _drawVectorSegment(canvas, topLeft, isHead, alpha);
      }
    }

    final headSource =
        _sourcePoint(from, body.length - 1, body.last, grew: grew);
    final headCenter = _interpolatedCenter(headSource, body.last, t);
    if (provider.state.status == GameStatus.over) {
      if (_useSprites) {
        _drawSpriteDeadEyes(canvas, headCenter);
      } else {
        _drawDeadEyes(canvas, headCenter);
      }
    } else if (!_useSprites) {
      _drawEyes(canvas, headCenter);
    }
    _drawAuras(canvas, headCenter);
  }

  void _drawVectorSegment(
    Canvas canvas,
    Offset topLeft,
    bool isHead,
    double alpha,
  ) {
    final radius = skin == SnakeSkin.pixel
        ? cellSize * 0.12
        : (isHead ? 6.0 : 3.0);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        topLeft.dx + 1,
        topLeft.dy + 1,
        cellSize - 2,
        cellSize - 2,
      ),
      Radius.circular(radius),
    );

    if (skinUsesNeonGlow(skin)) {
      _glowPaint
        ..color = color.withValues(alpha: alpha * 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cellSize * 0.32);
      canvas.drawRRect(rect, _glowPaint);
    }

    _bodyPaint.color = color.withValues(alpha: alpha);
    canvas.drawRRect(rect, _bodyPaint);
  }

  void _drawSpriteSegment(
    Canvas canvas,
    List<Point> body,
    int index,
    Offset topLeft,
    double alpha,
  ) {
    final isHead = index == body.length - 1;
    final isTail = index == 0;
    final image = isHead
        ? sprites.head
        : (isTail ? sprites.tail ?? sprites.body : sprites.body);
    if (image == null) {
      _drawVectorSegment(canvas, topLeft, isHead, alpha);
      return;
    }

    _drawSprite(
      canvas,
      image,
      topLeft,
      angle: isHead ? _angleForDirection(provider.state.snake.direction) : null,
      alpha: alpha.clamp(0.6, 1.0).toDouble(),
    );
  }

  void _drawSprite(
    Canvas canvas,
    ui.Image image,
    Offset topLeft, {
    double? angle,
    required double alpha,
  }) {
    final inset = cellSize * 0.04;
    final target = Rect.fromLTWH(
      topLeft.dx + inset,
      topLeft.dy + inset,
      cellSize - inset * 2,
      cellSize - inset * 2,
    );
    final source = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    _spritePaint.color = Colors.white.withValues(alpha: alpha);

    if (angle == null || angle == 0) {
      canvas.drawImageRect(image, source, target, _spritePaint);
      return;
    }

    canvas.save();
    canvas.translate(target.center.dx, target.center.dy);
    canvas.rotate(angle);
    canvas.drawImageRect(
      image,
      source,
      Rect.fromCenter(
        center: Offset.zero,
        width: target.width,
        height: target.height,
      ),
      _spritePaint,
    );
    canvas.restore();
  }

  void _drawSpriteDeadEyes(Canvas canvas, Offset center) {
    final eyeRadius = cellSize * 0.1;
    final offsets = _eyeOffsets(provider.state.snake.direction);
    final leftEye = center + _scaled(offsets, 0);
    final rightEye = center + _scaled(offsets, 2);

    canvas.drawCircle(leftEye, eyeRadius, _eyePaint);
    canvas.drawCircle(rightEye, eyeRadius, _eyePaint);
    _drawCross(canvas, leftEye, eyeRadius * 0.5);
    _drawCross(canvas, rightEye, eyeRadius * 0.5);
  }

  double _angleForDirection(Direction direction) {
    switch (direction) {
      case Direction.right:
        return 0;
      case Direction.down:
        return math.pi / 2;
      case Direction.left:
        return math.pi;
      case Direction.up:
        return -math.pi / 2;
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
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    // 传送门会让蛇头跨越大半个棋盘，直接吸附到出口，避免拉出长条。
    if (dx.abs() > 1 || dy.abs() > 1) {
      return Offset(to.x * cellSize, to.y * cellSize);
    }
    return Offset(
      (from.x + dx * t) * cellSize,
      (from.y + dy * t) * cellSize,
    );
  }

  Offset _interpolatedCenter(Point from, Point to, double t) {
    final topLeft = _interpolatedTopLeft(from, to, t);
    return topLeft + Offset(cellSize / 2, cellSize / 2);
  }

  void _drawAuras(Canvas canvas, Offset center) {
    final effects = provider.activeEffects;
    if (effects.isEmpty) return;

    var radius = cellSize * 0.72;
    _auraPaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    for (final effect in effects) {
      _auraPaint.color = powerUpColor(effect.type).withValues(alpha: 0.55);
      canvas.drawCircle(center, radius, _auraPaint);
      radius += cellSize * 0.16;
    }
  }

  void _drawEyes(Canvas canvas, Offset center) {
    final eyeRadius = cellSize * 0.12;
    final pupilRadius = cellSize * 0.06;
    final offsets = _eyeOffsets(provider.state.snake.direction);
    final leftEye = center + _scaled(offsets, 0);
    final rightEye = center + _scaled(offsets, 2);
    final leftPupil = center + _scaled(offsets, 4);
    final rightPupil = center + _scaled(offsets, 6);

    canvas.drawCircle(leftEye, eyeRadius, _eyePaint);
    canvas.drawCircle(rightEye, eyeRadius, _eyePaint);
    canvas.drawCircle(leftPupil, pupilRadius, _pupilPaint);
    canvas.drawCircle(rightPupil, pupilRadius, _pupilPaint);
  }

  void _drawDeadEyes(Canvas canvas, Offset center) {
    final eyeRadius = cellSize * 0.12;
    final offsets = _eyeOffsets(provider.state.snake.direction);
    final leftEye = center + _scaled(offsets, 0);
    final rightEye = center + _scaled(offsets, 2);

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

  /// 各方向的眼部偏移（单位：格），顺序为左眼、右眼、左瞳、右瞳的 x/y。
  static const Map<Direction, List<double>> _eyeTable = {
    Direction.right: [0.2, -0.2, 0.2, 0.2, 0.25, -0.2, 0.25, 0.2],
    Direction.left: [-0.2, -0.2, -0.2, 0.2, -0.25, -0.2, -0.25, 0.2],
    Direction.up: [-0.2, -0.2, 0.2, -0.2, -0.2, -0.25, 0.2, -0.25],
    Direction.down: [-0.2, 0.2, 0.2, 0.2, -0.2, 0.25, 0.2, 0.25],
  };

  List<double> _eyeOffsets(Direction dir) => _eyeTable[dir]!;

  /// 把查表中的格单位偏移换算成像素偏移。
  Offset _scaled(List<double> offsets, int index) {
    return Offset(offsets[index] * cellSize, offsets[index + 1] * cellSize);
  }
}
