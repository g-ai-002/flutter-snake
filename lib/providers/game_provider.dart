import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/game_state.dart';
import '../models/power_up.dart';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../services/log_service.dart';
import '../services/storage_service.dart';

class GameProvider extends ChangeNotifier {
  final StorageService _storage;
  final Random _random;
  GameState _state;
  Direction _nextDirection = Direction.right;
  bool _directionLocked = false;

  final Map<PowerUpType, ActiveEffect> _effects = {};
  int _shieldCharges = 0;
  double _effectNotifyTimer = 0;

  GameProvider(this._storage, {Random? random})
      : _random = random ?? Random(),
        _state = GameState(
          snake: Snake(
            body: [
              const Point(10, 10),
              const Point(11, 10),
              const Point(12, 10),
            ],
          ),
          food: const Food(Point(15, 10)),
          highScore: _storage.highScore,
        );

  GameState get state => _state;
  bool get isPlaying => _state.status == GameStatus.playing;
  bool get isPaused => _state.status == GameStatus.paused;
  bool get isOver => _state.status == GameStatus.over;
  bool get isIdle => _state.status == GameStatus.idle;

  List<ActiveEffect> get activeEffects => _effects.values.toList();
  bool hasEffect(PowerUpType type) => _effects.containsKey(type);
  bool get hasShield => _shieldCharges > 0;

  /// 当前生效速度（含加速/减速道具）。
  int get effectiveSpeedMs {
    if (_effects.containsKey(PowerUpType.speedUp)) {
      return max(60, (_state.speedMs * 0.65).round());
    }
    if (_effects.containsKey(PowerUpType.slowDown)) {
      return min(600, (_state.speedMs * 1.5).round());
    }
    return _state.speedMs;
  }

  void changeDirection(Direction dir) {
    if (_directionLocked) return;
    if (_state.status != GameStatus.playing) return;

    final current = _state.snake.direction;
    final opposite = _opposite(current);
    if (dir == opposite) return;

    _nextDirection = dir;
    _directionLocked = true;
  }

  /// 倒计时等尚未推进的阶段允许重新选择方向。
  void unlockDirection() {
    _directionLocked = false;
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

  /// 激活一个道具效果（也用于测试）。
  void activatePowerUp(PowerUpType type) {
    _activate(type);
    notifyListeners();
  }

  void _activate(PowerUpType type) {
    if (type == PowerUpType.speedUp) {
      _effects.remove(PowerUpType.slowDown);
    } else if (type == PowerUpType.slowDown) {
      _effects.remove(PowerUpType.speedUp);
    }
    _effects[type] = ActiveEffect(
      type: type,
      total: type.durationSeconds,
    );
    if (type == PowerUpType.shield) {
      _shieldCharges = 1;
    }
    _effectNotifyTimer = 0;
  }

  /// 推进道具效果计时，由游戏循环按真实帧时间调用；暂停/倒计时时冻结。
  void updateEffects(double dt) {
    if (_effects.isEmpty) return;

    var changed = false;
    for (final effect in _effects.values.toList()) {
      effect.remaining -= dt;
      if (effect.remaining <= 0) {
        _effects.remove(effect.type);
        if (effect.type == PowerUpType.shield) {
          _shieldCharges = 0;
        }
        changed = true;
      }
    }

    _effectNotifyTimer += dt;
    if (changed || _effectNotifyTimer >= 0.2) {
      _effectNotifyTimer = 0;
      notifyListeners();
    }
  }

  void start() {
    LogService.info('游戏开始');
    final w = _state.boardWidth;
    final h = _state.boardHeight;
    final center = w ~/ 2;
    final mid = h ~/ 2;
    final body = [
      Point(center - 2, mid),
      Point(center - 1, mid),
      Point(center, mid),
    ];

    _effects.clear();
    _shieldCharges = 0;
    _effectNotifyTimer = 0;
    _state = GameState(
      snake: Snake(body: body),
      food: _randomFood(w, h, body),
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
  }

  void pause() {
    if (_state.status != GameStatus.playing) return;
    LogService.info('游戏暂停');
    _state = _state.copyWith(status: GameStatus.paused);
    notifyListeners();
  }

  void resume() {
    if (_state.status != GameStatus.paused) return;
    LogService.info('游戏继续');
    _state = _state.copyWith(status: GameStatus.playing);
    notifyListeners();
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

  /// 推进一次游戏逻辑，由 Flame 按当前移动间隔调用。
  void tick() {
    if (_state.status != GameStatus.playing) return;

    final snake = _state.snake;
    final dir = _nextDirection;
    _directionLocked = false;

    final newHead = snake.head.move(dir);

    if (_isCollision(newHead, snake)) {
      if (_shieldCharges > 0) {
        _shieldCharges = 0;
        _effects.remove(PowerUpType.shield);
        _effectNotifyTimer = 0;
        AudioService().playShieldBreak();
        LogService.info('护盾抵挡了一次碰撞');
        notifyListeners();
        return;
      }
      _gameOver();
      return;
    }

    final food = _state.food;
    final magnet = _effects.containsKey(PowerUpType.magnet);
    final ate = newHead == food.position ||
        (magnet && _isNear(newHead, food.position));

    final newBody = List<Point>.from(snake.body)..add(newHead);
    if (!ate) {
      newBody.removeAt(0);
    }

    final gain = _effects.containsKey(PowerUpType.doubleScore) ? 20 : 10;
    final newScore = ate ? _state.score + gain : _state.score;
    final previousHighScore = _state.highScore;
    final newHighScore =
        newScore > previousHighScore ? newScore : previousHighScore;

    Food newFood = food;
    if (ate) {
      newFood = _randomFood(_state.boardWidth, _state.boardHeight, newBody);
      if (food.type == null) {
        LogService.info('吃到食物, 得分: $newScore');
        AudioService().playEat();
      } else {
        _activate(food.type!);
        LogService.info('拾取道具: ${food.type!.label}, 得分: $newScore');
        AudioService().playPowerUp();
      }
    }

    _state = _state.copyWith(
      snake: snake.copyWith(body: newBody, direction: dir),
      food: newFood,
      score: newScore,
      highScore: newHighScore,
    );

    if (newHighScore > previousHighScore) {
      _storage.setHighScore(newHighScore);
    }

    notifyListeners();
  }

  bool _isNear(Point a, Point b) {
    return (a.x - b.x).abs() + (a.y - b.y).abs() <= 1;
  }

  bool _isCollision(Point head, Snake snake) {
    if (head.x < 0 ||
        head.x >= _state.boardWidth ||
        head.y < 0 ||
        head.y >= _state.boardHeight) {
      return true;
    }
    final bodyWithoutTail = snake.body.sublist(1);
    return bodyWithoutTail.any((p) => p == head);
  }

  void _gameOver() {
    LogService.info('游戏结束, 得分: ${_state.score}');
    AudioService().playGameOver();
    LeaderboardService.addScore(_state.score);
    final newHighScore =
        _state.score > _state.highScore ? _state.score : _state.highScore;
    if (newHighScore > _state.highScore) {
      _storage.setHighScore(newHighScore);
    }
    _effects.clear();
    _shieldCharges = 0;
    _effectNotifyTimer = 0;
    _state = _state.copyWith(
      status: GameStatus.over,
      highScore: newHighScore,
    );
    notifyListeners();
  }

  Food _randomFood(int w, int h, List<Point> occupied) {
    final occupiedSet = occupied.toSet();
    final available = <Point>[];
    for (var x = 0; x < w; x++) {
      for (var y = 0; y < h; y++) {
        final p = Point(x, y);
        if (!occupiedSet.contains(p)) {
          available.add(p);
        }
      }
    }

    final type = _random.nextDouble() < 0.28
        ? PowerUpType.values[_random.nextInt(PowerUpType.values.length)]
        : null;

    if (available.isEmpty) {
      return Food(
        Point(_random.nextInt(w), _random.nextInt(h)),
        type: type,
      );
    }
    return Food(
      available[_random.nextInt(available.length)],
      type: type,
    );
  }
}
