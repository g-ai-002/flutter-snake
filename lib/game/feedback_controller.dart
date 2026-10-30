import 'dart:math' as math;

/// 死亡闪屏、慢动作与连吃计时等视觉反馈状态。
///
/// 只保存数值与时间轴，具体绘制交给 Flame 组件与 `world.timeScale`。
class FeedbackController {
  static const double flashDuration = 0.3;
  static const double flashPeakOpacity = 0.42;
  static const double slowMotionDuration = 0.45;
  static const double slowMotionScale = 0.35;
  static const double comboWindow = 2.5;

  double _flashRemaining = 0;
  double _slowMotionRemaining = 0;
  int _combo = 1;
  double _comboTimer = 0;

  /// 当前连吃次数，窗口结束后回到 1。
  int get combo => _combo;

  bool get isSlowMotion => _slowMotionRemaining > 0;

  /// 闪屏不透明度，随时间线性衰减到 0。
  double get flashOpacity =>
      _flashRemaining <= 0 ? 0 : flashPeakOpacity * (_flashRemaining / flashDuration);

  /// 世界时间缩放：慢动作期间放慢，其余时间为 1。
  double get timeScale => isSlowMotion ? slowMotionScale : 1.0;

  /// 吃到食物：窗口内连续吃到则连击 +1，返回当前连击数。
  int registerEat() {
    _combo = _comboTimer > 0 ? _combo + 1 : 1;
    _comboTimer = comboWindow;
    return _combo;
  }

  /// 死亡：进入慢动作并开始闪屏，连击归零。
  void triggerDeath() {
    _slowMotionRemaining = slowMotionDuration;
    _flashRemaining = flashDuration;
    _combo = 1;
    _comboTimer = 0;
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

  /// 连吃窗口只在游戏推进时消耗。
  void tickCombo(double dt) {
    if (_comboTimer <= 0) return;
    _comboTimer = math.max(0.0, _comboTimer - dt);
    if (_comboTimer == 0) {
      _combo = 1;
    }
  }

  void reset() {
    _flashRemaining = 0;
    _slowMotionRemaining = 0;
    _combo = 1;
    _comboTimer = 0;
  }
}
