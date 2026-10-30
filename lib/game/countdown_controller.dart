import 'package:flutter/foundation.dart';

/// 开局倒计时：3、2、1，随后短暂显示 GO（值为 0）。
class CountdownController {
  static const int startValue = 3;
  static const double seconds = 3.0;
  static const double goSeconds = 0.45;

  /// 当前展示值，0 表示 GO。
  final ValueNotifier<int> value = ValueNotifier<int>(0);

  bool _active = false;
  double _remaining = 0;
  double _goRemaining = 0;

  bool get isActive => _active;

  void start() {
    _active = true;
    _remaining = seconds;
    _goRemaining = 0;
    value.value = startValue;
  }

  /// 推进倒计时；返回 true 表示本次推进结束，可以移除遮罩。
  bool update(double dt) {
    if (!_active) return false;

    if (_remaining > 0) {
      _remaining -= dt;
      final next = _remaining.ceil().clamp(1, startValue).toInt();
      if (value.value != next) {
        value.value = next;
      }
      if (_remaining <= 0) {
        _goRemaining = goSeconds;
        value.value = 0;
      }
      return false;
    }

    _goRemaining -= dt;
    if (_goRemaining > 0) return false;
    stop();
    return true;
  }

  void stop() {
    _active = false;
    _remaining = 0;
    _goRemaining = 0;
    value.value = 0;
  }

  void dispose() {
    value.dispose();
  }
}
