import 'daily_challenge.dart';
import 'game_mode.dart';
import 'level.dart';
import 'power_up.dart';

enum Direction { up, down, left, right }

extension DirectionInfo on Direction {
  /// 反方向，用于拦截掉头输入。
  Direction get opposite {
    switch (this) {
      case Direction.up:
        return Direction.down;
      case Direction.down:
        return Direction.up;
      case Direction.left:
        return Direction.right;
      case Direction.right:
        return Direction.left;
    }
  }
}

enum GameStatus { idle, playing, paused, over }

/// 单局结束原因，用于结算文案。
enum GameOverReason { collision, timeout }

extension GameOverReasonInfo on GameOverReason {
  String get label {
    switch (this) {
      case GameOverReason.collision:
        return '游戏结束';
      case GameOverReason.timeout:
        return '时间到';
    }
  }
}

class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);

  /// 曼哈顿距离，用于磁铁吸附范围判定。
  int manhattanTo(Point other) => (x - other.x).abs() + (y - other.y).abs();

  Point move(Direction dir) {
    switch (dir) {
      case Direction.up:
        return Point(x, y - 1);
      case Direction.down:
        return Point(x, y + 1);
      case Direction.left:
        return Point(x - 1, y);
      case Direction.right:
        return Point(x + 1, y);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Point && other.x == x && other.y == y;

  @override
  int get hashCode => x.hashCode ^ (y.hashCode << 16);

  @override
  String toString() => '($x, $y)';
}

class Snake {
  final List<Point> body;
  Direction direction;

  Snake({required this.body, this.direction = Direction.right});

  Point get head => body.last;

  Snake copyWith({List<Point>? body, Direction? direction}) {
    return Snake(
      body: body ?? List.from(this.body),
      direction: direction ?? this.direction,
    );
  }
}

class Food {
  final Point position;
  final PowerUpType? type;

  const Food(this.position, {this.type});
}

class GameState {
  final Snake snake;
  final Food food;
  final GameStatus status;
  final int score;
  final int highScore;
  final int boardWidth;
  final int boardHeight;
  final int speedMs;
  final LevelType level;
  final LevelLayout layout;
  final GameMode mode;
  final double remainingSeconds;
  final GameOverReason overReason;

  /// 非空表示本局是每日挑战，结算时按挑战日期记录成绩。
  final DailyChallenge? daily;

  GameState({
    required this.snake,
    required this.food,
    this.status = GameStatus.idle,
    this.score = 0,
    this.highScore = 0,
    this.boardWidth = 20,
    this.boardHeight = 20,
    this.speedMs = 200,
    this.level = LevelType.open,
    this.layout = LevelLayout.empty,
    this.mode = GameMode.classic,
    this.remainingSeconds = 0,
    this.overReason = GameOverReason.collision,
    this.daily,
  });

  GameState copyWith({
    Snake? snake,
    Food? food,
    GameStatus? status,
    int? score,
    int? highScore,
    int? boardWidth,
    int? boardHeight,
    int? speedMs,
    LevelType? level,
    LevelLayout? layout,
    GameMode? mode,
    double? remainingSeconds,
    GameOverReason? overReason,
    DailyChallenge? daily,
  }) {
    return GameState(
      snake: snake ?? this.snake,
      food: food ?? this.food,
      status: status ?? this.status,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      boardWidth: boardWidth ?? this.boardWidth,
      boardHeight: boardHeight ?? this.boardHeight,
      speedMs: speedMs ?? this.speedMs,
      level: level ?? this.level,
      layout: layout ?? this.layout,
      mode: mode ?? this.mode,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      overReason: overReason ?? this.overReason,
      daily: daily ?? this.daily,
    );
  }
}
