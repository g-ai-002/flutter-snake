import 'dart:math' as math;

/// 死亡闪屏与慢动作等视觉反馈状态。
///
/// 只保存数值与时间轴，具体绘制交给 Flame 组件与 `world.timeScale`。
/// 连击状态由 `GameProvider` 持有，因为它同时决定得分。
class FeedbackController {
  static const double flashDuration = 0.3;
  static const double flashPeakOpacity = 0.42;
  static const double slowMotionDuration = 0.45;
  static const double slowMotionScale = 0.35;

  double _flashRemaining = 0;
  double _slowMotionRemaining = 0;

  bool get isSlowMotion => _slowMotionRemaining > 0;

  /// 闪屏不透明度，随时间线性衰减到 0。
  double get flashOpacity => _flashRemaining <= 0
      ? 0
      : flashPeakOpacity * (_flashRemaining / flashDuration);

  /// 世界时间缩放：慢动作期间放慢，其余时间为 1。
  double get timeScale => isSlowMotion ? slowMotionScale : 1.0;

  /// 死亡：进入慢动作并开始闪屏。
  void triggerDeath() {
    _slowMotionRemaining = slowMotionDuration;
    _flashRemaining = flashDuration;
  }

  /// 每帧推进闪屏与慢动作（暂停时主循环停止，自然冻结）。
  void updateVisuals(double dt) {
    if (_flashRemaining > 0) {
      _flashRemaining = math.max(0.0, _flashRemaining - dt);
    }
    if (_slowMotionRemaining > 0) {
      _slowMotionRemaining = math.max(0.0, _slowMotionRemaining - dt);
    }
  }

  void reset() {
    _flashRemaining = 0;
    _slowMotionRemaining = 0;
  }
}
