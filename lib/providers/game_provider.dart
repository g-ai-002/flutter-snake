import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/game_state.dart';
import '../models/level.dart';
import '../models/power_up.dart';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../services/log_service.dart';
import '../services/storage_service.dart';

class GameProvider extends ChangeNotifier {
  final StorageService _storage;
  final Random _random;
  final bool audioEnabled;
  GameState _state;
  Direction _nextDirection = Direction.right;
  bool _directionLocked = false;
  LevelType _level = LevelType.open;

  final Map<PowerUpType, ActiveEffect> _effects = {};
  int _shieldCharges = 0;
  double _effectNotifyTimer = 0;

  /// [audioEnabled] 为 false 时不触碰音频插件，便于无音频环境与单元测试。
  GameProvider(
    this._storage, {
    Random? random,
    this.audioEnabled = true,
  })  : _random = random ?? Random(),
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

  /// 当前选择的关卡，下一局生效。
  LevelType get level => _level;

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
    final w = _state.boardWidth;
    final h = _state.boardHeight;
    final center = w ~/ 2;
    final mid = h ~/ 2;
    startWithLayout(_buildLayout(w, h, center, mid));
  }

  /// 使用指定布局开局，供自定义关卡与测试使用。
  void startWithLayout(LevelLayout layout) {
    LogService.info('游戏开始, 关卡: ${_level.label}');
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
      food: _randomFood(w, h, body, layout),
      status: GameStatus.playing,
      highScore: _state.highScore,
      boardWidth: w,
      boardHeight: h,
      speedMs: _state.speedMs,
      level: _level,
      layout: layout,
    );
    _nextDirection = Direction.right;
    _directionLocked = false;
    notifyListeners();
  }

  /// 生成当前关卡的布局，并清空出生点所在行，避免开局即撞墙。
  LevelLayout _buildLayout(int w, int h, int center, int mid) {
    final base = buildLevelLayout(_level, w, h);
    final walls = Set<Point>.of(base.walls);
    // 出生通道留出 5 格缓冲，让玩家在倒计时后有时间转向。
    for (var x = center - 3; x <= center + 4; x++) {
      walls.remove(Point(x, mid));
    }
    return LevelLayout(walls: walls, portals: base.portals);
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

  void updateLevel(LevelType level) {
    if (_level == level) return;
    _level = level;
    LogService.info('选择关卡: ${level.label}');
    notifyListeners();
  }

  /// 推进一次游戏逻辑，由 Flame 按当前移动间隔调用。
  void tick() {
    if (_state.status != GameStatus.playing) return;

    final snake = _state.snake;
    final dir = _nextDirection;
    _directionLocked = false;

    var newHead = snake.head.move(dir);
    final portalExit = _state.layout.portalExit(newHead);
    if (portalExit != null) {
      LogService.info('穿越传送门: $newHead -> $portalExit');
      newHead = portalExit;
    }

    if (_isCollision(newHead, snake)) {
      if (_shieldCharges > 0) {
        _shieldCharges = 0;
        _effects.remove(PowerUpType.shield);
        _effectNotifyTimer = 0;
        if (audioEnabled) {
          AudioService().playShieldBreak();
        }
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
      newFood = _randomFood(
        _state.boardWidth,
        _state.boardHeight,
        newBody,
        _state.layout,
      );
      if (food.type == null) {
        LogService.info('吃到食物, 得分: $newScore');
        if (audioEnabled) {
          AudioService().playEat();
        }
      } else {
        _activate(food.type!);
        LogService.info('拾取道具: ${food.type!.label}, 得分: $newScore');
        if (audioEnabled) {
          AudioService().playPowerUp();
        }
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
    if (_state.layout.isWall(head)) return true;
    final bodyWithoutTail = snake.body.sublist(1);
    return bodyWithoutTail.any((p) => p == head);
  }

  void _gameOver() {
    LogService.info('游戏结束, 得分: ${_state.score}');
    if (audioEnabled) {
      AudioService().playGameOver();
    }
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

  Food _randomFood(
    int w,
    int h,
    List<Point> occupied,
    LevelLayout layout,
  ) {
    final occupiedSet = <Point>{
      ...occupied,
      ...layout.walls,
      ...layout.portals.keys,
    };
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
