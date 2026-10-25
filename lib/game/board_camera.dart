import 'dart:ui';

import 'package:flame/components.dart';

/// 相机布局：让世界里的棋盘区域正好落在画布上的目标矩形内。
class BoardCameraLayout {
  const BoardCameraLayout({
    required this.zoom,
    required this.position,
  });

  /// 世界单位到画布逻辑像素的缩放。
  final double zoom;

  /// 取景器中心对应的世界坐标。
  final Vector2 position;
}

/// 计算把 [worldBoardRect] 映射到画布 [boardRect] 所需的相机参数。
///
/// [zoom] 不传时按宽度比例自适应；传入时用于缩放脉冲等场景，位置仍保证
/// 棋盘中心不动。
BoardCameraLayout cameraLayoutForBoard({
  required Size canvasSize,
  required Rect boardRect,
  required Rect worldBoardRect,
  double? zoom,
}) {
  final scale = zoom ?? (boardRect.width / worldBoardRect.width);
  final canvasCenter = Offset(canvasSize.width / 2, canvasSize.height / 2);
  final delta = boardRect.center - canvasCenter;
  return BoardCameraLayout(
    zoom: scale,
    position: Vector2(
      worldBoardRect.center.dx - delta.dx / scale,
      worldBoardRect.center.dy - delta.dy / scale,
    ),
  );
}
