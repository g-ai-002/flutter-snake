import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import 'board_layer_component.dart';

/// 吃到食物/道具时在拾取位置炸开的粒子层。
class ParticleBurstComponent extends BoardLayerComponent {
  ParticleBurstComponent({
    required super.provider,
    required this.color,
    super.priority,
  });

  final Color color;
  final math.Random _random = math.Random();
  final List<_Particle> _particles = [];
  final Paint _paint = Paint();

  void burst(Point cell, {Color? color}) {
    final burstColor = color ?? this.color;
    final center = Vector2(
      cell.x * cellSize + cellSize / 2,
      cell.y * cellSize + cellSize / 2,
    );

    for (var i = 0; i < 16; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = cellSize * (1.6 + _random.nextDouble() * 2.8);
      final life = 0.36 + _random.nextDouble() * 0.24;
      _particles.add(
        _Particle(
          position: Vector2(center.x, center.y),
          velocity: Vector2(
            math.cos(angle) * speed,
            math.sin(angle) * speed,
          ),
          remaining: life,
          total: life,
          radius: cellSize * (0.05 + _random.nextDouble() * 0.07),
          color: burstColor,
        ),
      );
    }
  }

  void clear() {
    _particles.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final friction = math.pow(0.12, dt).toDouble();

    for (final particle in _particles) {
      particle.remaining -= dt;
      particle.position = particle.position + particle.velocity * dt;
      particle.velocity = particle.velocity * friction;
    }
    _particles.removeWhere((particle) => particle.remaining <= 0);
  }

  @override
  void render(Canvas canvas) {
    for (final particle in _particles) {
      final life = (particle.remaining / particle.total)
          .clamp(0.0, 1.0)
          .toDouble();
      _paint.color = particle.color.withValues(alpha: 0.85 * life);
      canvas.drawCircle(
        Offset(particle.position.x, particle.position.y),
        particle.radius * (0.6 + 0.4 * life),
        _paint,
      );
    }
  }
}

class _Particle {
  _Particle({
    required this.position,
    required this.velocity,
    required this.remaining,
    required this.total,
    required this.radius,
    required this.color,
  });

  Vector2 position;
  Vector2 velocity;
  double remaining;
  final double total;
  final double radius;
  final Color color;
}
