import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/game/countdown_controller.dart';

void main() {
  group('CountdownController', () {
    test('从 3 递减到 GO 后结束', () {
      final countdown = CountdownController();
      countdown.start();

      expect(countdown.isActive, isTrue);
      expect(countdown.value.value, 3);

      countdown.update(1);
      expect(countdown.value.value, 2);

      countdown.update(1);
      expect(countdown.value.value, 1);

      countdown.update(1);
      expect(countdown.value.value, 0);
      expect(countdown.isActive, isTrue);

      expect(countdown.update(CountdownController.goSeconds + 0.01), isTrue);
      expect(countdown.isActive, isFalse);
      expect(countdown.value.value, 0);

      countdown.dispose();
    });

    test('未开始时推进不生效', () {
      final countdown = CountdownController();
      expect(countdown.update(1), isFalse);
      expect(countdown.isActive, isFalse);

      countdown.dispose();
    });

    test('stop 立即复位', () {
      final countdown = CountdownController();
      countdown.start();
      countdown.stop();

      expect(countdown.isActive, isFalse);
      expect(countdown.value.value, 0);
      expect(countdown.update(1), isFalse);

      countdown.dispose();
    });
  });
}
