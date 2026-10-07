import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/game_state.dart';

/// 手势控制层：把整块棋盘区域变成方向控制器。
///
/// - 点击 / 鼠标单击：按点击位置相对区域中心的方向转向；
/// - 滑动 / 鼠标拖拽：按滑动方向转向。
///
/// 键盘方向键由页面单独监听，与此层互补。
class GestureControl extends StatefulWidget {
  final Widget child;
  final void Function(Direction direction) onDirection;

  const GestureControl({
    super.key,
    required this.onDirection,
    required this.child,
  });

  /// 触发一次滑动所需的最小位移（逻辑像素）。
  static const double swipeThreshold = 16;

  /// 点击位置的死区比例，避免在中心附近误触发。
  static const double deadZoneRatio = 0.05;

  /// 由位移向量推断方向：取横纵分量中占优的一轴。
  static Direction directionFromDelta(Offset delta) {
    if (delta.dx.abs() > delta.dy.abs()) {
      return delta.dx > 0 ? Direction.right : Direction.left;
    }
    return delta.dy > 0 ? Direction.down : Direction.up;
  }

  /// 由点击位置推断方向，落在中心死区内时返回 null。
  static Direction? directionFromTap(Offset position, Size size) {
    final delta = position - size.center(Offset.zero);
    if (delta.distance < size.shortestSide * deadZoneRatio) return null;
    return directionFromDelta(delta);
  }

  @override
  State<GestureControl> createState() => _GestureControlState();
}

class _GestureControlState extends State<GestureControl> {
  Offset _dragDelta = Offset.zero;

  void _onTapUp(TapUpDetails details, Size size) {
    final direction =
        GestureControl.directionFromTap(details.localPosition, size);
    if (direction != null) {
      widget.onDirection(direction);
    }
  }

  void _resetDrag() {
    _dragDelta = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _dragDelta += details.delta;
  }

  void _onPanEnd(DragEndDetails details) {
    final delta = _dragDelta;
    _resetDrag();
    if (delta.distance < GestureControl.swipeThreshold) return;
    widget.onDirection(GestureControl.directionFromDelta(delta));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onTapUp: (details) => _onTapUp(details, size),
          onPanStart: (_) => _resetDrag(),
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: _resetDrag,
          child: widget.child,
        );
      },
    );
  }
}
