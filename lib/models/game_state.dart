enum Direction { up, down, left, right }

enum GameStatus { idle, playing, paused, over }

class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);

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
  bool operator ==(Object other) => other is Point && other.x == x && other.y == y;

  @override
  int get hashCode => x.hashCode ^ (y.hashCode << 16);

  @override
  String toString() => '($x, $y)';
}

class Snake {
  final List<Point> body;
  Direction direction;

  Snake({
    required this.body,
    this.direction = Direction.right,
  });

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

  const Food(this.position);
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

  GameState({
    required this.snake,
    required this.food,
    this.status = GameStatus.idle,
    this.score = 0,
    this.highScore = 0,
    this.boardWidth = 20,
    this.boardHeight = 20,
    this.speedMs = 200,
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
    );
  }
}
