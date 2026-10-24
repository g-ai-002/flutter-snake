import 'game_state.dart';

/// 关卡类型：决定棋盘上生成的障碍物与传送门。
enum LevelType { open, border, pillars, cross, maze, portals }

extension LevelTypeInfo on LevelType {
  String get label {
    switch (this) {
      case LevelType.open:
        return '空旷';
      case LevelType.border:
        return '边墙';
      case LevelType.pillars:
        return '立柱阵';
      case LevelType.cross:
        return '十字回廊';
      case LevelType.maze:
        return '回字迷宫';
      case LevelType.portals:
        return '传送门';
    }
  }

  String get description {
    switch (this) {
      case LevelType.open:
        return '没有障碍物，专注吃分';
      case LevelType.border:
        return '内圈围墙，四边各留缺口';
      case LevelType.pillars:
        return '均匀分布的 2×2 立柱';
      case LevelType.cross:
        return '中央十字墙，中心留出空场';
      case LevelType.maze:
        return '双层回字围墙，考验路线规划';
      case LevelType.portals:
        return '两对传送门，瞬间穿越棋盘';
    }
  }
}

/// 一格宽的方形围墙，多段可以拼成回字、十字等图案。
class LevelLayout {
  const LevelLayout({
    this.walls = const <Point>{},
    this.portals = const <Point, Point>{},
  });

  static const LevelLayout empty = LevelLayout();

  /// 不可通行的墙格。
  final Set<Point> walls;

  /// 传送门入口到出口的映射，两个方向都记录。
  final Map<Point, Point> portals;

  bool isWall(Point point) => walls.contains(point);

  Point? portalExit(Point point) => portals[point];
}

/// 按关卡类型与棋盘尺寸生成布局。障碍图案会随尺寸缩放。
LevelLayout buildLevelLayout(LevelType type, int columns, int rows) {
  final center = columns ~/ 2;
  final middle = rows ~/ 2;

  switch (type) {
    case LevelType.open:
      return LevelLayout.empty;
    case LevelType.border:
      return LevelLayout(walls: _borderWalls(columns, rows, center, middle));
    case LevelType.pillars:
      return LevelLayout(walls: _pillarWalls(columns, rows));
    case LevelType.cross:
      return LevelLayout(walls: _crossWalls(columns, rows, center, middle));
    case LevelType.maze:
      return LevelLayout(walls: _mazeWalls(columns, rows, center, middle));
    case LevelType.portals:
      return _portalLayout(columns, rows, center, middle);
  }
}

Set<Point> _borderWalls(int columns, int rows, int center, int middle) {
  const inset = 2;
  const left = inset;
  const top = inset;
  final right = columns - inset - 1;
  final bottom = rows - inset - 1;

  return _ringWalls(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    gaps: <Point>{
      for (var d = -1; d <= 1; d++) Point(center + d, top),
      for (var d = -1; d <= 1; d++) Point(center + d, bottom),
      for (var d = -1; d <= 1; d++) Point(left, middle + d),
      for (var d = -1; d <= 1; d++) Point(right, middle + d),
    },
  );
}

Set<Point> _pillarWalls(int columns, int rows) {
  const spacing = 5;
  final walls = <Point>{};
  for (var x = 3; x + 1 <= columns - 3; x += spacing) {
    for (var y = 3; y + 1 <= rows - 3; y += spacing) {
      walls
        ..add(Point(x, y))
        ..add(Point(x + 1, y))
        ..add(Point(x, y + 1))
        ..add(Point(x + 1, y + 1));
    }
  }
  return walls;
}

Set<Point> _crossWalls(int columns, int rows, int center, int middle) {
  final walls = <Point>{};
  for (var y = 2; y <= rows - 3; y++) {
    if (y >= middle - 2 && y <= middle + 2) continue;
    walls.add(Point(center, y));
  }
  for (var x = 2; x <= columns - 3; x++) {
    if (x >= center - 2 && x <= center + 2) continue;
    walls.add(Point(x, middle));
  }
  return walls;
}

Set<Point> _mazeWalls(int columns, int rows, int center, int middle) {
  final walls = _ringWalls(
    left: 2,
    top: 2,
    right: columns - 3,
    bottom: rows - 3,
    gaps: <Point>{
      for (var d = -1; d <= 1; d++) Point(center + d, 2),
      for (var d = -1; d <= 1; d++) Point(center + d, rows - 3),
      for (var d = -1; d <= 1; d++) Point(2, middle + d),
      for (var d = -1; d <= 1; d++) Point(columns - 3, middle + d),
    },
  );

  const left = 5;
  const top = 5;
  final right = columns - 6;
  final bottom = rows - 6;
  if (right - left >= 2 && bottom - top >= 2) {
    walls.addAll(
      _ringWalls(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        gaps: <Point>{
          Point(center, top),
          Point(center, bottom),
          Point(left, middle),
          Point(right, middle),
        },
      ),
    );
  }
  return walls;
}

LevelLayout _portalLayout(int columns, int rows, int center, int middle) {
  final left = Point(2, middle);
  final right = Point(columns - 3, middle);
  final top = Point(center, 2);
  final bottom = Point(center, rows - 3);
  return LevelLayout(
    portals: <Point, Point>{
      left: right,
      right: left,
      top: bottom,
      bottom: top,
    },
  );
}

Set<Point> _ringWalls({
  required int left,
  required int top,
  required int right,
  required int bottom,
  Set<Point> gaps = const <Point>{},
}) {
  final walls = <Point>{};
  for (var x = left; x <= right; x++) {
    for (final y in <int>[top, bottom]) {
      final point = Point(x, y);
      if (!gaps.contains(point)) walls.add(point);
    }
  }
  for (var y = top; y <= bottom; y++) {
    for (final x in <int>[left, right]) {
      final point = Point(x, y);
      if (!gaps.contains(point)) walls.add(point);
    }
  }
  return walls;
}
