import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/game/feedback_controller.dart';

void main() {
  group('FeedbackController', () {
    test('连吃在窗口内累加，超时归零', () {
      final feedback = FeedbackController();
      expect(feedback.registerEat(), 1);
      expect(feedback.registerEat(), 2);
      expect(feedback.registerEat(), 3);

      feedback.tickCombo(FeedbackController.comboWindow);
      expect(feedback.combo, 1);
      expect(feedback.registerEat(), 1);
    });

    test('死亡触发慢动作与闪屏', () {
      final feedback = FeedbackController();
      feedback.registerEat();

      feedback.triggerDeath();
      expect(feedback.isSlowMotion, isTrue);
      expect(feedback.timeScale, FeedbackController.slowMotionScale);
      expect(feedback.flashOpacity, greaterThan(0));
      expect(feedback.combo, 1);

      feedback.updateVisuals(FeedbackController.slowMotionDuration + 0.1);
      expect(feedback.isSlowMotion, isFalse);
      expect(feedback.timeScale, 1.0);
      expect(feedback.flashOpacity, 0);
    });

    test('闪屏随时间线性衰减', () {
      final feedback = FeedbackController();
      feedback.triggerDeath();

      feedback.updateVisuals(FeedbackController.flashDuration / 2);
      expect(
        feedback.flashOpacity,
        closeTo(FeedbackController.flashPeakOpacity / 2, 1e-9),
      );
    });

    test('reset 清空状态', () {
      final feedback = FeedbackController();
      feedback.triggerDeath();
      feedback.registerEat();

      feedback.reset();
      expect(feedback.isSlowMotion, isFalse);
      expect(feedback.flashOpacity, 0);
      expect(feedback.combo, 1);
    });
  });
}
