import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/game/food_spawner.dart';
import 'package:flutter_snake/models/achievement.dart';
import 'package:flutter_snake/models/game_mode.dart';
import 'package:flutter_snake/models/game_state.dart';
import 'package:flutter_snake/models/level.dart';
import 'package:flutter_snake/providers/game_provider.dart';
import 'package:flutter_snake/services/stats_service.dart';
import 'package:flutter_snake/utils/game_rules.dart';

import 'fakes/fake_storage.dart';

/// 按队列返回固定位置的食物，其余情况回退到棋盘角落。
class _QueueSpawner extends FoodSpawner {
  _QueueSpawner(List<Point> positions) : _positions = List<Point>.of(positions);

  final List<Point> _positions;

  @override
  Food spawn({
    required int columns,
    required int rows,
    required List<Point> occupied,
    required LevelLayout layout,
  }) {
    if (_positions.isEmpty) {
      return const Food(Point(0, 0));
    }
    return Food(_positions.removeAt(0));
  }
}

GameProvider _createGame(List<Point> food) {
  return GameProvider(
    FakeStorageService.create(),
    foodSpawner: _QueueSpawner(food),
    audioEnabled: false,
  );
}

void main() {
  setUp(() => StatsService.instance.resetForTest());

  group('GameMode', () {
    test('标签与说明', () {
      expect(GameMode.classic.label, '经典');
      expect(GameMode.wrap.label, '穿墙');
      expect(GameMode.timed.label, '限时挑战');
      expect(GameMode.timed.description, contains('60'));
    });

    test('只有穿墙模式越界穿越', () {
      expect(GameMode.wrap.wrapsEdges, isTrue);
      expect(GameMode.classic.wrapsEdges, isFalse);
      expect(GameMode.timed.wrapsEdges, isFalse);
    });

    test('限时模式初始秒数', () {
      expect(GameMode.timed.initialSeconds, GameRules.timedLimitSeconds);
      expect(GameMode.classic.initialSeconds, isNull);
    });
  });

  group('穿墙模式', () {
    test('越过右边界从左侧出现', () {
      final game = _createGame(const [Point(0, 0), Point(0, 0), Point(0, 0)]);
      game.updateMode(GameMode.wrap);
      game.start();
      expect(game.state.mode, GameMode.wrap);

      for (var i = 0; i < 10; i++) {
        game.tick();
      }

      expect(game.isPlaying, isTrue);
      expect(game.state.snake.head, const Point(0, 10));
    });

    test('经典模式撞墙即结束', () {
      final game = _createGame(const [Point(0, 0)]);
      game.start();

      for (var i = 0; i < 10; i++) {
        game.tick();
      }

      expect(game.isOver, isTrue);
      expect(game.state.overReason, GameOverReason.collision);
    });
  });

  group('限时挑战', () {
    test('开局倒计时按真实时间递减', () {
      final game = _createGame(const [Point(0, 0)]);
      game.updateMode(GameMode.timed);
      game.start();

      expect(game.state.mode, GameMode.timed);
      expect(game.state.remainingSeconds, GameRules.timedLimitSeconds);

      game.tickTime(30);
      expect(game.remainingSeconds, closeTo(30, 1e-9));

      game.tickTime(29.5);
      expect(game.isOver, isFalse);
      expect(game.remainingSeconds, closeTo(0.5, 1e-9));
    });

    test('时间耗尽以 timeout 结束并解锁首局成就', () {
      final game = _createGame(const [Point(0, 0)]);
      game.updateMode(GameMode.timed);
      game.start();

      game.tickTime(GameRules.timedLimitSeconds + 1);

      expect(game.isOver, isTrue);
      expect(game.state.overReason, GameOverReason.timeout);
      expect(game.remainingSeconds, 0);
      expect(game.lastUnlocked, contains(AchievementId.firstGame));
      expect(game.stats.gamesPlayed, 1);
    });

    test('吃到食物会加时', () {
      final game = _createGame(const [Point(11, 10), Point(0, 0)]);
      game.updateMode(GameMode.timed);
      game.start();

      game.tickTime(5);
      game.tick();

      expect(game.state.score, 10);
      expect(
        game.remainingSeconds,
        closeTo(
          GameRules.timedLimitSeconds - 5 + GameRules.timedBonusSeconds,
          1e-9,
        ),
      );
    });
  });

  group('连击计分', () {
    test('连续吃到食物按连击倍率加分', () {
      final game = _createGame(const [
        Point(11, 10),
        Point(12, 10),
        Point(0, 0),
      ]);
      game.start();

      game.tick();
      expect(game.state.score, 10);
      expect(game.combo, 1);

      game.tick();
      expect(game.state.score, 30);
      expect(game.combo, 2);
    });

    test('连击窗口过期后倍率回落', () {
      final game = _createGame(const [
        Point(11, 10),
        Point(12, 10),
        Point(13, 10),
      ]);
      game.start();

      game.tick();
      game.tick();
      expect(game.combo, 2);

      game.tickTime(GameRules.comboWindowSeconds + 0.1);
      expect(game.combo, 1);

      game.tick();
      expect(game.state.score, 40);
      expect(game.combo, 1);
    });
  });
}
