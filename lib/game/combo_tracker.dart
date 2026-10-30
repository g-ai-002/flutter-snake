import 'dart:math' as math;

import '../utils/game_rules.dart';

/// 连击计时与倍率：窗口内连续吃到食物则累加连击。
///
/// 只保存数值，何时结算分数与刷新界面由 [GameProvider] 决定。
class ComboTracker {
  int _combo = 1;
  int _best = 1;
  double _windowRemaining = 0;

  /// 当前连击数，窗口结束后回到 1。
  int get combo => _combo;

  /// 本局出现过的最高连击，用于结算与成就。
  int get best => _best;

  /// 当前连击是否仍在窗口内。
  bool get isActive => _windowRemaining > 0;

  /// 当前得分倍率，封顶 [GameRules.maxComboMultiplier]。
  int get multiplier => math.min(_combo, GameRules.maxComboMultiplier);

  /// 吃到食物：窗口内再次吃到则连击 +1，返回当前连击数。
  int registerEat() {
    _combo = _windowRemaining > 0 ? _combo + 1 : 1;
    _windowRemaining = GameRules.comboWindowSeconds;
    _best = math.max(_best, _combo);
    return _combo;
  }

  /// 推进窗口计时；返回连击是否回落到 1（需要刷新界面）。
  bool update(double dt) {
    if (_windowRemaining <= 0) return false;
    _windowRemaining = math.max(0, _windowRemaining - dt);
    if (_windowRemaining > 0 || _combo == 1) return false;
    _combo = 1;
    return true;
  }

  void reset() {
    _combo = 1;
    _best = 1;
    _windowRemaining = 0;
  }
}
