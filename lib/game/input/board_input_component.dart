import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../components/board_layer_component.dart';
import 'direction_input.dart';

/// 覆盖整块棋盘的 Flame 输入层：点击按方位转向，滑动按方向转向。
class BoardInputComponent extends BoardLayerComponent
    with TapCallbacks, DragCallbacks {
  BoardInputComponent({required super.provider, super.priority});

  Vector2 _dragDelta = Vector2.zero();

  @override
  void onTapUp(TapUpEvent event) {
    final direction = directionFromTap(
      Offset(event.localPosition.x, event.localPosition.y),
      Size(width, height),
    );
    if (direction != null) {
      provider.changeDirection(direction);
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    _dragDelta = Vector2.zero();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _dragDelta += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    final delta = _dragDelta;
    _dragDelta = Vector2.zero();
    if (delta.length < swipeThreshold) return;
    provider.changeDirection(
      directionFromDelta(Offset(delta.x, delta.y)),
    );
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    _dragDelta = Vector2.zero();
  }
}
