import 'dart:math';

import '../models/power_up.dart';

/// 道具效果的激活、互斥、计时与护盾次数。
///
/// 只负责规则本身，不触碰界面与音频；何时通知界面由 [GameProvider] 决定。
class PowerUpManager {
  /// 倒计时刷新节拍：避免每帧都通知界面。
  static const double _notifyInterval = 0.2;

  final Map<PowerUpType, ActiveEffect> _effects = {};
  int _shieldCharges = 0;
  double _notifyTimer = 0;

  Iterable<ActiveEffect> get effects => _effects.values;
  bool get isEmpty => _effects.isEmpty;
  bool get hasShield => _shieldCharges > 0;

  bool has(PowerUpType type) => _effects.containsKey(type);

  /// 叠加加速/减速后的移动间隔（毫秒）。
  int effectiveSpeedMs(int baseMs) {
    if (has(PowerUpType.speedUp)) {
      return max(60, (baseMs * 0.65).round());
    }
    if (has(PowerUpType.slowDown)) {
      return min(600, (baseMs * 1.5).round());
    }
    return baseMs;
  }

  /// 激活道具；加速与减速互斥，后拾取的覆盖先前的。
  void activate(PowerUpType type) {
    if (type == PowerUpType.speedUp) {
      _effects.remove(PowerUpType.slowDown);
    } else if (type == PowerUpType.slowDown) {
      _effects.remove(PowerUpType.speedUp);
    }
    _effects[type] = ActiveEffect(
      type: type,
      total: type.durationSeconds,
    );
    if (type == PowerUpType.shield) {
      _shieldCharges = 1;
    }
    _notifyTimer = 0;
  }

  /// 消耗一次护盾；返回是否真的挡住了这次碰撞。
  bool consumeShield() {
    if (_shieldCharges <= 0) return false;
    _shieldCharges = 0;
    _effects.remove(PowerUpType.shield);
    _notifyTimer = 0;
    return true;
  }

  void clear() {
    _effects.clear();
    _shieldCharges = 0;
    _notifyTimer = 0;
  }

  /// 推进效果计时；返回是否需要通知界面（有失效或到了刷新节拍）。
  bool update(double dt) {
    if (_effects.isEmpty) return false;

    var changed = false;
    for (final effect in _effects.values.toList()) {
      effect.remaining -= dt;
      if (effect.remaining <= 0) {
        _effects.remove(effect.type);
        if (effect.type == PowerUpType.shield) {
          _shieldCharges = 0;
        }
        changed = true;
      }
    }

    _notifyTimer += dt;
    if (!changed && _notifyTimer < _notifyInterval) {
      return false;
    }
    _notifyTimer = 0;
    return true;
  }
}
