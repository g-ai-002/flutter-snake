import 'dart:math';

import '../models/game_state.dart';
import '../models/level.dart';
import '../models/power_up.dart';

/// 在可通行格中随机生成食物与道具。
///
/// 生成位置会避开蛇身、墙体与传送门，保证不会生成在不可达的格子上。
class FoodSpawner {
  FoodSpawner({Random? random, this.powerUpChance = 0.28})
      : _random = random ?? Random();

  final Random _random;

  /// 生成道具（而非普通食物）的概率。
  final double powerUpChance;

  Food spawn({
    required int columns,
    required int rows,
    required List<Point> occupied,
    required LevelLayout layout,
  }) {
    // 先决定类型再决定位置，保持随机序列稳定，便于用固定种子做测试。
    final type = _random.nextDouble() < powerUpChance ? _randomPowerUp() : null;
    if (columns <= 0 || rows <= 0) {
      return Food(const Point(0, 0), type: type);
    }

    final blocked = <Point>{
      ...occupied,
      ...layout.walls,
      ...layout.portals.keys,
    };
    final available = <Point>[
      for (var x = 0; x < columns; x++)
        for (var y = 0; y < rows; y++)
          if (!blocked.contains(Point(x, y))) Point(x, y),
    ];

    if (available.isEmpty) {
      // 棋盘被填满时没有安全格，退回随机格，由碰撞判定结束这一局。
      return Food(
        Point(_random.nextInt(columns), _random.nextInt(rows)),
        type: type,
      );
    }
    return Food(available[_random.nextInt(available.length)], type: type);
  }

  PowerUpType _randomPowerUp() =>
      PowerUpType.values[_random.nextInt(PowerUpType.values.length)];
}
