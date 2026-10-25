import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// 铺满整个画布的手势层，坐标即画布逻辑像素。
///
/// 它挂在相机的 viewport 上（HUD 空间），因此不受取景器缩放影响，棋盘内外
/// 的触摸都能收到。
class CanvasGestureLayer extends PositionComponent
    with TapCallbacks, DragCallbacks {
  CanvasGestureLayer({
    required this.onTap,
    required this.onSwipe,
    super.priority,
  });

  /// 点击回调，参数为画布坐标。
  final void Function(Offset position) onTap;

  /// 滑动结束回调，参数为画布上的位移。
  final void Function(Offset delta) onSwipe;

  Offset _dragDelta = Offset.zero;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onParentResize(Vector2 maxSize) {
    super.onParentResize(maxSize);
    size = maxSize;
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTap(Offset(event.localPosition.x, event.localPosition.y));
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragDelta = Offset.zero;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _dragDelta += Offset(event.localDelta.x, event.localDelta.y);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final delta = _dragDelta;
    _dragDelta = Offset.zero;
    onSwipe(delta);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragDelta = Offset.zero;
  }
}
