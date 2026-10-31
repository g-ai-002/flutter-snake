import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_snake/game/food_spawner.dart';
import 'package:flutter_snake/models/game_mode.dart';
import 'package:flutter_snake/models/game_state.dart';
import 'package:flutter_snake/models/level.dart';
import 'package:flutter_snake/models/power_up.dart';
import 'package:flutter_snake/providers/game_provider.dart';
import 'package:flutter_snake/services/stats_service.dart';
import 'package:flutter_snake/utils/game_rules.dart';

import 'fakes/fake_storage.dart';

/// 按队列返回固定食物，队列耗尽后回退到角落。
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

GameProvider _game(FakeStorageService storage, List<Point> food) {
  return GameProvider(
    storage,
    foodSpawner: _QueueSpawner(food),
    audioEnabled: false,
  );
}

void main() {
  setUp(() => StatsService.instance.resetForTest());

  group('开局布局', () {
    test('start 按当前棋盘尺寸生成蛇身与居中蛇头', () {
      final game = _game(FakeStorageService.create(), const [Point(5, 5)]);
      game.updateBoardSize(15);
      game.start();

      final state = game.state;
      expect(state.boardWidth, 15);
      expect(state.boardHeight, 15);
      expect(state.snake.head, const Point(7, 7));
      expect(state.snake.body, hasLength(3));
      for (final point in state.snake.body) {
        expect(point.x, inInclusiveRange(0, 14));
        expect(point.y, inInclusiveRange(0, 14));
      }
      expect(state.food.position, const Point(5, 5));
    });

    test('出生行始终清空，避免开局撞墙', () {
      final game = _game(FakeStorageService.create(), const [Point(0, 0)]);
      game.updateLevel(LevelType.cross);
      game.start();

      final state = game.state;
      for (var x = 7; x <= 14; x++) {
        expect(
          state.layout.isWall(Point(x, 10)),
          isFalse,
          reason: '出生通道 ($x, 10) 不应有墙',
        );
      }
    });
  });

  group('计分与记录', () {
    test('双倍分道具让食物得分翻倍', () {
      final game = _game(FakeStorageService.create(), const [
        Point(11, 10),
        Point(0, 0),
      ]);
      game.start();
      game.activatePowerUp(PowerUpType.doubleScore);
      game.tick();

      expect(game.state.score, GameRules.baseFoodScore * 2);
    });

    test('刷新最高分立即写入存储', () {
      final storage = FakeStorageService.create();
      final game = _game(storage, const [Point(11, 10), Point(0, 0)]);
      game.start();
      game.tick();

      expect(game.state.score, GameRules.baseFoodScore);
      expect(game.state.highScore, GameRules.baseFoodScore);
      expect(storage.highScore, GameRules.baseFoodScore);
    });

    test('结算后状态为 over 且统计局数 +1', () {
      final game = _game(FakeStorageService.create(), const [Point(0, 0)]);
      game.start();
      for (var i = 0; i < 10; i++) {
        game.tick();
      }

      expect(game.isOver, isTrue);
      expect(game.state.status, GameStatus.over);
      expect(game.stats.gamesPlayed, 1);
    });
  });

  group('暂停与计时', () {
    test('暂停时 tickTime 不推进限时倒计时', () {
      final game = _game(FakeStorageService.create(), const [Point(0, 0)]);
      game.updateMode(GameMode.timed);
      game.start();
      game.pause();

      final remaining = game.state.remainingSeconds;
      game.tickTime(5);

      expect(game.state.remainingSeconds, remaining);
    });
  });
}
