import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/models/game_state.dart';
import 'package:flutter_snake/models/level.dart';
import 'package:flutter_snake/models/power_up.dart';
import 'package:flutter_snake/providers/game_provider.dart';

import 'fakes/fake_storage.dart';

void main() {
  group('关卡布局', () {
    test('所有关卡在 15/20/25 棋盘上都落在界内且传送门双向可达', () {
      for (final type in LevelType.values) {
        for (final size in [15, 20, 25]) {
          final layout = buildLevelLayout(type, size, size);
          for (final wall in layout.walls) {
            expect(
              wall.x,
              inInclusiveRange(0, size - 1),
              reason: '${type.label} 墙格越界',
            );
            expect(
              wall.y,
              inInclusiveRange(0, size - 1),
              reason: '${type.label} 墙格越界',
            );
          }
          expect(
            layout.walls.length,
            lessThan(size * size ~/ 2),
            reason: '${type.label} 障碍过多',
          );
          for (final entry in layout.portals.entries) {
            expect(
              layout.portals[entry.value],
              entry.key,
              reason: '${type.label} 传送门未双向映射',
            );
            expect(layout.walls.contains(entry.key), isFalse);
          }
        }
      }
    });

    test('空旷关卡没有障碍与传送门', () {
      final layout = buildLevelLayout(LevelType.open, 20, 20);
      expect(layout.walls, isEmpty);
      expect(layout.portals, isEmpty);
    });

    test('传送门关卡有 2 对出口', () {
      final layout = buildLevelLayout(LevelType.portals, 20, 20);
      expect(layout.portals.length, 4);
      expect(layout.portals[const Point(17, 10)], const Point(2, 10));
      expect(layout.portals[const Point(10, 17)], const Point(10, 2));
    });

    test('边墙关卡的四边留有缺口', () {
      final layout = buildLevelLayout(LevelType.border, 20, 20);
      expect(layout.isWall(const Point(10, 2)), isFalse);
      expect(layout.isWall(const Point(2, 10)), isFalse);
      expect(layout.isWall(const Point(10, 17)), isFalse);
      expect(layout.isWall(const Point(17, 10)), isFalse);
      expect(layout.isWall(const Point(5, 2)), isTrue);
    });
  });

  group('关卡开局', () {
    test('每个关卡的蛇身与食物都在可通行格', () {
      for (final level in LevelType.values) {
        final game = GameProvider(FakeStorageService(), random: Random(7));
        game.updateLevel(level);
        game.start();
        final state = game.state;
        expect(state.level, level);
        for (final point in state.snake.body) {
          expect(
            state.layout.walls.contains(point),
            isFalse,
            reason: '${level.label} 蛇身落在墙上',
          );
        }
        expect(
          state.layout.walls.contains(state.food.position),
          isFalse,
          reason: '${level.label} 食物落在墙上',
        );
        expect(
          state.layout.portals.containsKey(state.food.position),
          isFalse,
          reason: '${level.label} 食物落在传送门上',
        );
        expect(state.status, GameStatus.playing);
      }
    });
  });

  group('障碍与传送门碰撞', () {
    test('撞墙判定游戏结束', () {
      final game = GameProvider(
        FakeStorageService(),
        random: Random(1),
        audioEnabled: false,
      );
      game.startWithLayout(
        LevelLayout(walls: <Point>{Point(11, 10)}),
      );
      game.tick();
      expect(game.isOver, isTrue);
    });

    test('护盾抵挡一次撞墙', () {
      final game = GameProvider(
        FakeStorageService(),
        random: Random(1),
        audioEnabled: false,
      );
      game.startWithLayout(
        LevelLayout(walls: <Point>{Point(11, 10)}),
      );
      game.activatePowerUp(PowerUpType.shield);
      final head = game.state.snake.head;
      game.tick();
      expect(game.isPlaying, isTrue);
      expect(game.hasShield, isFalse);
      expect(game.state.snake.head, head);
    });

    test('进入传送门后从配对出口出现', () {
      final game = GameProvider(
        FakeStorageService(),
        random: Random(1),
        audioEnabled: false,
      );
      game.startWithLayout(
        LevelLayout(
          portals: <Point, Point>{
            Point(11, 10): Point(2, 10),
            Point(2, 10): Point(11, 10),
          },
        ),
      );
      game.tick();
      expect(game.state.snake.head, const Point(2, 10));
      expect(game.isPlaying, isTrue);
    });
  });
}
