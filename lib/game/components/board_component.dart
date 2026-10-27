import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'board_layer_component.dart';

/// 棋盘背景、网格线与外边框。
///
/// 棋盘尺寸与配色在一局内不变，因此把静态部分录制为 [ui.Picture] 缓存，
/// 逐帧只回放绘制指令，不再重复画几十条网格线。
class BoardComponent extends BoardLayerComponent {
  BoardComponent({
    required super.provider,
    required this.backgroundColor,
    required this.gridColor,
    required this.borderColor,
    super.priority,
  });

  final Color backgroundColor;
  final Color gridColor;
  final Color borderColor;

  late final Paint _backgroundPaint = Paint()..color = backgroundColor;
  late final Paint _gridPaint = Paint()
    ..color = gridColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  late final Paint _borderPaint = Paint()
    ..color = borderColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  ui.Picture? _picture;
  double _cachedWidth = -1;
  double _cachedHeight = -1;
  double _cachedCellSize = -1;
  int _cachedColumns = -1;
  int _cachedRows = -1;

  bool get _needsRebuild =>
      _picture == null ||
      _cachedWidth != width ||
      _cachedHeight != height ||
      _cachedCellSize != cellSize ||
      _cachedColumns != columns ||
      _cachedRows != rows;

  @override
  void render(Canvas canvas) {
    if (_needsRebuild) {
      _picture?.dispose();
      _picture = _buildPicture();
      _cachedWidth = width;
      _cachedHeight = height;
      _cachedCellSize = cellSize;
      _cachedColumns = columns;
      _cachedRows = rows;
    }
    canvas.drawPicture(_picture!);
  }

  ui.Picture _buildPicture() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _paintBoard(canvas);
    return recorder.endRecording();
  }

  void _paintBoard(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), _backgroundPaint);

    for (var x = 0; x <= columns; x++) {
      final dx = x * cellSize;
      canvas.drawLine(Offset(dx, 0), Offset(dx, height), _gridPaint);
    }
    for (var y = 0; y <= rows; y++) {
      final dy = y * cellSize;
      canvas.drawLine(Offset(0, dy), Offset(width, dy), _gridPaint);
    }

    canvas.drawRect(Rect.fromLTWH(1, 1, width - 2, height - 2), _borderPaint);
  }

  @override
  void onRemove() {
    _picture?.dispose();
    _picture = null;
    super.onRemove();
  }
}
