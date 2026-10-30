import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'board_camera.dart';

/// 相机装置：把世界里的棋盘对齐到页面上的棋盘槽位，并叠加缩放脉冲与抖动。
///
/// 只关心相机参数，不感知游戏状态；何时脉冲、何时抖动由 [SnakeGame] 决定。
class CameraRig {
  CameraRig({
    required this.camera,
    required this.worldSize,
  });

  final CameraComponent camera;

  /// 世界棋盘边长（世界单位）。
  final double worldSize;

  static const double zoomPulseDuration = 0.28;
  static const double shakeDuration = 0.45;
  static const double _defaultZoomStrength = 0.025;
  static const double _shakeRatio = 0.012;

  final math.Random _random = math.Random();
  final Vector2 _base = Vector2.zero();

  Size _canvasSize = Size.zero;
  Rect _boardRect = Rect.zero;
  double _baseZoom = 1;
  double _zoomPulse = 0;
  double _zoomStrength = _defaultZoomStrength;
  double _shakeRemaining = 0;

  /// 页面上的棋盘槽位（画布坐标）。
  Rect get boardRect => _boardRect;

  bool get isReady => !_boardRect.isEmpty && !_canvasSize.isEmpty;

  void updateLayout({required Rect boardRect, required Size canvasSize}) {
    if (_boardRect == boardRect && _canvasSize == canvasSize) {
      return;
    }
    _boardRect = boardRect;
    _canvasSize = canvasSize;
    applyBase();
  }

  void resize(Size canvasSize) {
    if (_canvasSize == canvasSize) return;
    _canvasSize = canvasSize;
    applyBase();
  }

  /// 复位到无脉冲、无抖动的基准视图。
  void applyBase() {
    if (!isReady) return;
    final layout = _layoutFor();
    _baseZoom = layout.zoom;
    _base.setFrom(layout.position);
    camera.viewfinder.zoom = _baseZoom;
    camera.viewfinder.position = _base.clone();
  }

  /// 触发一次缩放脉冲（吃到食物、死亡）。
  void pulse({double strength = 0.06}) {
    _zoomPulse = 1;
    _zoomStrength = strength;
  }

  /// 触发一次相机抖动（死亡）。
  void shake() {
    _shakeRemaining = shakeDuration;
  }

  void update(double dt) {
    if (!isReady) return;

    _zoomPulse = math.max(0.0, _zoomPulse - dt / zoomPulseDuration);
    if (_shakeRemaining > 0) {
      _shakeRemaining = math.max(0.0, _shakeRemaining - dt);
    }

    final eased = 1 - (1 - _zoomPulse) * (1 - _zoomPulse);
    final zoom = _baseZoom * (1 + _zoomStrength * eased);
    _base.setFrom(_layoutFor(zoom).position);
    camera.viewfinder.zoom = zoom;
    camera.viewfinder.position = _shakenPosition();
  }

  void reset() {
    _zoomPulse = 0;
    _zoomStrength = _defaultZoomStrength;
    _shakeRemaining = 0;
    applyBase();
  }

  Vector2 _shakenPosition() {
    final strength = worldSize * _shakeRatio * (_shakeRemaining / shakeDuration);
    if (strength <= 0) return _base.clone();
    return Vector2(
      _base.x + (_random.nextDouble() * 2 - 1) * strength,
      _base.y + (_random.nextDouble() * 2 - 1) * strength,
    );
  }

  BoardCameraLayout _layoutFor([double? zoom]) {
    if (!isReady) {
      return BoardCameraLayout(zoom: _baseZoom, position: _base.clone());
    }
    return cameraLayoutForBoard(
      canvasSize: _canvasSize,
      boardRect: _boardRect,
      worldBoardRect: Rect.fromLTWH(0, 0, worldSize, worldSize),
      zoom: zoom,
    );
  }
}
