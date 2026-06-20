import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../services/log_service.dart';
import '../services/storage_service.dart';

class GameProvider extends ChangeNotifier {
  final StorageService _storage;
  Timer? _timer;
  GameState _state;
  Direction _nextDirection = Direction.right;
  bool _directionLocked = false;

  GameProvider(this._storage)
      : _state = GameState(
          snake: Snake(body: [const Point(10, 10), const Point(11, 10), const Point(12, 10)]),
          food: const Food(Point(15, 10)),
          highScore: _storage.highScore,
        );

  GameState get state => _state;
  bool get isPlaying => _state.status == GameStatus.playing;
  bool get isPaused => _state.status == GameStatus.paused;
  bool get isOver => _state.status == GameStatus.over;
  bool get isIdle => _state.status == GameStatus.idle;

  void changeDirection(Direction dir) {
    if (_directionLocked) return;
    if (_state.status != GameStatus.playing) return;

    final current = _state.snake.direction;
    final opposite = _opposite(current);
    if (dir == opposite) return;

    _nextDirection = dir;
    _directionLocked = true;
  }

  Direction _opposite(Direction d) {
    switch (d) {
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

  void start() {
    LogService.info('游戏开始');
    final w = _state.boardWidth;
    final h = _state.boardHeight;
    final center = w ~/ 2;
    final mid = h ~/ 2;

    _state = GameState(
      snake: Snake(body: [Point(center - 2, mid), Point(center - 1, mid), Point(center, mid)]),
      food: _randomFood(w, h, [Point(center - 2, mid), Point(center - 1, mid), Point(center, mid)]),
      status: GameStatus.playing,
      score: 0,
      highScore: _state.highScore,
      boardWidth: w,
      boardHeight: h,
      speedMs: _state.speedMs,
    );
    _nextDirection = Direction.right;
    _directionLocked = false;
    notifyListeners();
    _startTimer();
  }

  void pause() {
    if (_state.status != GameStatus.playing) return;
    LogService.info('游戏暂停');
    _state = _state.copyWith(status: GameStatus.paused);
    _timer?.cancel();
    notifyListeners();
  }

  void resume() {
    if (_state.status != GameStatus.paused) return;
    LogService.info('游戏继续');
    _state = _state.copyWith(status: GameStatus.playing);
    notifyListeners();
    _startTimer();
  }

  void togglePause() {
    if (_state.status == GameStatus.playing) {
      pause();
    } else if (_state.status == GameStatus.paused) {
      resume();
    }
  }

  void updateBoardSize(int size) {
    _state = _state.copyWith(boardWidth: size, boardHeight: size);
    notifyListeners();
  }

  void updateSpeed(int ms) {
    _state = _state.copyWith(speedMs: ms);
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _state.speedMs), (_) {
      _tick();
    });
  }

  void _tick() {
    if (_state.status != GameStatus.playing) return;

    final snake = _state.snake;
    final dir = _nextDirection;
    _directionLocked = false;

    final newHead = snake.head.move(dir);

    // 撞墙检测
    if (newHead.x < 0 ||
        newHead.x >= _state.boardWidth ||
        newHead.y < 0 ||
        newHead.y >= _state.boardHeight) {
      _gameOver();
      return;
    }

    // 撞自己检测（排除尾部，因为尾部即将移走）
    final bodyWithoutTail = snake.body.sublist(1);
    if (bodyWithoutTail.any((p) => p == newHead)) {
      _gameOver();
      return;
    }

    final ate = newHead == _state.food.position;
    final newBody = List<Point>.from(snake.body)..add(newHead);
    if (!ate) {
      newBody.removeAt(0);
    }

    final oldHighScore = _state.highScore;
    final newScore = ate ? _state.score + 10 : _state.score;
    final newHighScore = newScore > oldHighScore ? newScore : oldHighScore;

    Food newFood = _state.food;
    if (ate) {
      newFood = _randomFood(_state.boardWidth, _state.boardHeight, newBody);
      LogService.info('吃到食物, 得分: $newScore');
      AudioService().playEat();
    }

    _state = _state.copyWith(
      snake: snake.copyWith(body: newBody, direction: dir),
      food: newFood,
      score: newScore,
      highScore: newHighScore,
    );

    if (newHighScore > oldHighScore) {
      _storage.setHighScore(newHighScore);
    }

    notifyListeners();
  }

  void _gameOver() {
    LogService.info('游戏结束, 得分: ${_state.score}');
    _timer?.cancel();
    AudioService().playGameOver();
    LeaderboardService.addScore(_state.score);
    if (_state.score > _state.highScore) {
      _storage.setHighScore(_state.score);
    }
    _state = _state.copyWith(
      status: GameStatus.over,
      highScore: _state.score > _state.highScore ? _state.score : _state.highScore,
    );
    notifyListeners();
  }

  Food _randomFood(int w, int h, List<Point> occupied) {
    final rng = Random();
    final available = <Point>[];
    for (var x = 0; x < w; x++) {
      for (var y = 0; y < h; y++) {
        final p = Point(x, y);
        if (!occupied.any((o) => o == p)) {
          available.add(p);
        }
      }
    }
    if (available.isEmpty) {
      return Food(Point(rng.nextInt(w), rng.nextInt(h)));
    }
    return Food(available[rng.nextInt(available.length)]);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
