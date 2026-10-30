import 'dart:math';

import 'package:flutter/foundation.dart';

import '../game/food_spawner.dart';
import '../game/power_up_manager.dart';
import '../models/game_state.dart';
import '../models/level.dart';
import '../models/power_up.dart';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../services/log_service.dart';
import '../services/storage_service.dart';

class GameProvider extends ChangeNotifier {
  final StorageService _storage;
  final FoodSpawner _foodSpawner;
  final PowerUpManager _powerUps = PowerUpManager();
  final bool audioEnabled;
  GameState _state;
  Direction _nextDirection = Direction.right;
  bool _directionLocked = false;
  LevelType _level = LevelType.open;

  /// [audioEnabled] 为 false 时不触碰音频插件，便于无音频环境与单元测试。
  GameProvider(
    this._storage, {
    Random? random,
    this.audioEnabled = true,
  })  : _foodSpawner = FoodSpawner(random: random),
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

  Iterable<ActiveEffect> get activeEffects => _powerUps.effects;
  bool hasEffect(PowerUpType type) => _powerUps.has(type);
  bool get hasShield => _powerUps.hasShield;

  /// 当前生效速度（含加速/减速道具）。
  int get effectiveSpeedMs => _powerUps.effectiveSpeedMs(_state.speedMs);

  void changeDirection(Direction dir) {
    if (_directionLocked) return;
    if (_state.status != GameStatus.playing) return;
    if (dir == _state.snake.direction.opposite) return;

    _nextDirection = dir;
    _directionLocked = true;
  }

  /// 倒计时等尚未推进的阶段允许重新选择方向。
  void unlockDirection() {
    _directionLocked = false;
  }

  /// 激活一个道具效果（也用于测试）。
  void activatePowerUp(PowerUpType type) {
    _powerUps.activate(type);
    notifyListeners();
  }

  /// 推进道具效果计时，由游戏循环按真实帧时间调用；暂停/倒计时时冻结。
  void updateEffects(double dt) {
    if (_powerUps.update(dt)) {
      notifyListeners();
    }
  }

  void start() {
    final w = _state.boardWidth;
    final h = _state.boardHeight;
    startWithLayout(_buildLayout(w, h, w ~/ 2, h ~/ 2));
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

    _powerUps.clear();
    _state = GameState(
      snake: Snake(body: body),
      food: _foodSpawner.spawn(
        columns: w,
        rows: h,
        occupied: body,
        layout: layout,
      ),
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
      if (_powerUps.consumeShield()) {
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
    final ate = newHead == food.position ||
        (_powerUps.has(PowerUpType.magnet) &&
            newHead.manhattanTo(food.position) <= 1);

    final newBody = List<Point>.from(snake.body)..add(newHead);
    if (!ate) {
      newBody.removeAt(0);
    }

    final gain = _powerUps.has(PowerUpType.doubleScore) ? 20 : 10;
    final newScore = ate ? _state.score + gain : _state.score;
    final previousHighScore = _state.highScore;
    final newHighScore =
        newScore > previousHighScore ? newScore : previousHighScore;

    Food newFood = food;
    if (ate) {
      newFood = _foodSpawner.spawn(
        columns: _state.boardWidth,
        rows: _state.boardHeight,
        occupied: newBody,
        layout: _state.layout,
      );
      if (food.type == null) {
        LogService.info('吃到食物, 得分: $newScore');
        if (audioEnabled) {
          AudioService().playEat();
        }
      } else {
        _powerUps.activate(food.type!);
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
    _powerUps.clear();
    _state = _state.copyWith(
      status: GameStatus.over,
      highScore: newHighScore,
    );
    notifyListeners();
  }
}
