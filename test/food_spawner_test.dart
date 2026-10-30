import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/game/food_spawner.dart';
import 'package:flutter_snake/models/game_state.dart';
import 'package:flutter_snake/models/level.dart';

void main() {
  group('FoodSpawner', () {
    test('生成位置避开蛇身、墙体与传送门', () {
      final spawner = FoodSpawner(random: Random(3), powerUpChance: 0);
      final layout = LevelLayout(
        walls: <Point>{const Point(0, 0)},
        portals: <Point, Point>{
          const Point(1, 1): const Point(2, 2),
          const Point(2, 2): const Point(1, 1),
        },
      );
      final occupied = <Point>[const Point(3, 3), const Point(4, 3)];

      for (var i = 0; i < 50; i++) {
        final food = spawner.spawn(
          columns: 6,
          rows: 6,
          occupied: occupied,
          layout: layout,
        );
        expect(food.position.x, inInclusiveRange(0, 5));
        expect(food.position.y, inInclusiveRange(0, 5));
        expect(layout.walls.contains(food.position), isFalse);
        expect(layout.portals.containsKey(food.position), isFalse);
        expect(occupied.contains(food.position), isFalse);
      }
    });

    test('相同随机种子生成相同结果', () {
      final first = FoodSpawner(random: Random(42));
      final second = FoodSpawner(random: Random(42));

      for (var i = 0; i < 10; i++) {
        final a = first.spawn(
          columns: 20,
          rows: 20,
          occupied: const <Point>[],
          layout: LevelLayout.empty,
        );
        final b = second.spawn(
          columns: 20,
          rows: 20,
          occupied: const <Point>[],
          layout: LevelLayout.empty,
        );
        expect(a.position, b.position);
        expect(a.type, b.type);
      }
    });

    test('powerUpChance 控制道具出现', () {
      Food spawn(FoodSpawner spawner) => spawner.spawn(
            columns: 20,
            rows: 20,
            occupied: const <Point>[],
            layout: LevelLayout.empty,
          );

      final never = FoodSpawner(random: Random(1), powerUpChance: 0);
      final always = FoodSpawner(random: Random(1), powerUpChance: 1);
      for (var i = 0; i < 20; i++) {
        expect(spawn(never).type, isNull);
        expect(spawn(always).type, isNotNull);
      }
    });

    test('棋盘填满时仍返回界内坐标', () {
      final spawner = FoodSpawner(random: Random(5));
      final occupied = <Point>[
        for (var x = 0; x < 4; x++)
          for (var y = 0; y < 4; y++) Point(x, y),
      ];

      final food = spawner.spawn(
        columns: 4,
        rows: 4,
        occupied: occupied,
        layout: LevelLayout.empty,
      );
      expect(food.position.x, inInclusiveRange(0, 3));
      expect(food.position.y, inInclusiveRange(0, 3));
    });

    test('空棋盘尺寸不抛异常', () {
      final food = FoodSpawner().spawn(
        columns: 0,
        rows: 0,
        occupied: const <Point>[],
        layout: LevelLayout.empty,
      );
      expect(food.position, const Point(0, 0));
    });
  });
}
