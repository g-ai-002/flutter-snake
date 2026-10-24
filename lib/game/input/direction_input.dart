import 'dart:ui';

import '../../models/game_state.dart';

/// 触发一次滑动所需的最小位移（逻辑像素）。
const double swipeThreshold = 16;

/// 点击位置的死区比例，避免在中心附近误触发。
const double tapDeadZoneRatio = 0.05;

/// 由位移向量推断方向：取横纵分量中占优的一轴。
Direction directionFromDelta(Offset delta) {
  if (delta.dx.abs() > delta.dy.abs()) {
    return delta.dx > 0 ? Direction.right : Direction.left;
  }
  return delta.dy > 0 ? Direction.down : Direction.up;
}

/// 由点击位置推断方向，落在中心死区内时返回 null。
Direction? directionFromTap(Offset position, Size size) {
  final delta = position - size.center(Offset.zero);
  if (delta.distance < size.shortestSide * tapDeadZoneRatio) return null;
  return directionFromDelta(delta);
}
