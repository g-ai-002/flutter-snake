import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/game/power_up_manager.dart';
import 'package:flutter_snake/models/power_up.dart';

void main() {
  group('PowerUpManager 速度', () {
    test('无道具时保持基础间隔', () {
      expect(PowerUpManager().effectiveSpeedMs(200), 200);
    });

    test('加速缩短间隔，减速拉长间隔', () {
      final manager = PowerUpManager();
      manager.activate(PowerUpType.speedUp);
      expect(manager.effectiveSpeedMs(200), 130);

      manager.activate(PowerUpType.slowDown);
      expect(manager.has(PowerUpType.speedUp), isFalse);
      expect(manager.effectiveSpeedMs(200), 300);
    });

    test('加速有下限、减速有上限', () {
      final manager = PowerUpManager();
      manager.activate(PowerUpType.speedUp);
      expect(manager.effectiveSpeedMs(50), 60);

      manager.activate(PowerUpType.slowDown);
      expect(manager.effectiveSpeedMs(1000), 600);
    });
  });

  group('PowerUpManager 护盾', () {
    test('护盾只抵挡一次碰撞', () {
      final manager = PowerUpManager();
      manager.activate(PowerUpType.shield);
      expect(manager.hasShield, isTrue);

      expect(manager.consumeShield(), isTrue);
      expect(manager.hasShield, isFalse);
      expect(manager.has(PowerUpType.shield), isFalse);
      expect(manager.consumeShield(), isFalse);
    });

    test('护盾到期后次数清零', () {
      final manager = PowerUpManager();
      manager.activate(PowerUpType.shield);
      manager.update(PowerUpType.shield.durationSeconds + 0.1);
      expect(manager.hasShield, isFalse);
      expect(manager.consumeShield(), isFalse);
    });
  });

  group('PowerUpManager 计时', () {
    test('按节拍通知，效果到期后移除', () {
      final manager = PowerUpManager();
      manager.activate(PowerUpType.magnet);

      expect(manager.update(0.05), isFalse);
      expect(manager.update(0.2), isTrue);
      expect(manager.has(PowerUpType.magnet), isTrue);

      expect(manager.update(PowerUpType.magnet.durationSeconds), isTrue);
      expect(manager.has(PowerUpType.magnet), isFalse);
      expect(manager.isEmpty, isTrue);
    });

    test('没有效果时不通知', () {
      expect(PowerUpManager().update(1), isFalse);
    });

    test('clear 清空全部状态', () {
      final manager = PowerUpManager();
      manager.activate(PowerUpType.shield);
      manager.activate(PowerUpType.doubleScore);

      manager.clear();
      expect(manager.isEmpty, isTrue);
      expect(manager.hasShield, isFalse);
    });
  });
}
