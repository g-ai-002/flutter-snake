import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/game/combo_tracker.dart';
import 'package:flutter_snake/utils/game_rules.dart';

void main() {
  group('ComboTracker', () {
    test('首次吃到食物连击为 1', () {
      final tracker = ComboTracker();
      expect(tracker.combo, 1);
      expect(tracker.registerEat(), 1);
      expect(tracker.multiplier, 1);
    });

    test('窗口内连续吃到食物累加连击', () {
      final tracker = ComboTracker();
      expect(tracker.registerEat(), 1);
      expect(tracker.registerEat(), 2);
      expect(tracker.registerEat(), 3);
      expect(tracker.best, 3);
      expect(tracker.multiplier, 3);
    });

    test('窗口结束后连击回落到 1', () {
      final tracker = ComboTracker();
      tracker.registerEat();
      tracker.registerEat();
      expect(tracker.update(GameRules.comboWindowSeconds), isTrue);
      expect(tracker.combo, 1);
      expect(tracker.registerEat(), 1);
    });

    test('窗口内推进不触发回落', () {
      final tracker = ComboTracker();
      tracker.registerEat();
      tracker.registerEat();
      expect(tracker.update(GameRules.comboWindowSeconds / 2), isFalse);
      expect(tracker.combo, 2);
      expect(tracker.multiplier, 2);
    });

    test('倍率封顶', () {
      final tracker = ComboTracker();
      for (var i = 0; i < 10; i++) {
        tracker.registerEat();
      }
      expect(tracker.combo, 10);
      expect(tracker.multiplier, GameRules.maxComboMultiplier);
    });

    test('reset 清空连击与最佳记录', () {
      final tracker = ComboTracker();
      tracker.registerEat();
      tracker.registerEat();
      tracker.reset();
      expect(tracker.combo, 1);
      expect(tracker.best, 1);
      expect(tracker.isActive, isFalse);
    });
  });
}
