import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/game/feedback_controller.dart';

void main() {
  group('FeedbackController', () {
    test('死亡触发慢动作与闪屏', () {
      final feedback = FeedbackController();

      feedback.triggerDeath();
      expect(feedback.isSlowMotion, isTrue);
      expect(feedback.timeScale, FeedbackController.slowMotionScale);
      expect(feedback.flashOpacity, greaterThan(0));

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

      feedback.reset();
      expect(feedback.isSlowMotion, isFalse);
      expect(feedback.flashOpacity, 0);
      expect(feedback.timeScale, 1.0);
    });
  });
}
