import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// 吃食物时的分数飘字层。
class ScorePopupLayer extends Component {
  ScorePopupLayer({required Color color})
      : _paint = TextPaint(
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        super(priority: 6);

  final TextPaint _paint;

  void show(Vector2 position, String text, double rise) {
    final popup = TextComponent(
      text: text,
      textRenderer: _paint,
      anchor: Anchor.center,
      position: position,
      priority: 6,
    );
    popup.add(
      MoveByEffect(
        Vector2(0, -rise),
        EffectController(duration: 0.7, curve: Curves.easeOut),
      ),
    );
    popup.add(RemoveEffect(delay: 0.7));
    add(popup);
  }

  void clear() {
    for (final child in children.toList()) {
      child.removeFromParent();
    }
  }
}
