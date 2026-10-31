import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../game/combo_tracker.dart';
import '../game/food_spawner.dart';
import '../game/power_up_manager.dart';
import '../models/achievement.dart';
import '../models/daily_challenge.dart';
import '../models/game_mode.dart';
import '../models/game_state.dart';
import '../models/level.dart';
import '../models/player_stats.dart';
import '../models/power_up.dart';
import '../services/audio_service.dart';
import '../services/daily_service.dart';
import '../services/leaderboard_service.dart';
import '../services/log_service.dart';
import '../services/stats_service.dart';
import '../services/storage_service.dart';
import '../utils/game_rules.dart';

class GameProvider extends ChangeNotifier {
  final StorageService _storage;
  final FoodSpawner Function(int seed) _spawnerFactory;
  FoodSpawner _foodSpawner;
  final PowerUpManager _powerUps = PowerUpManager();
  final ComboTracker _combo = ComboTracker();
  final bool audioEnabled;
  GameState _state;
  Direction _nextDirection = Direction.right;
  bool _directionLocked = false;
  LevelType _level = LevelType.open;
  GameMode _mode = GameMode.classic;
  DailyChallenge? _daily;
  DailyResult? _dailyResult;
  int _foodEaten = 0;
  int _lastTimeDisplay = 0;
  List<AchievementId> _lastUnlocked = const <AchievementId>[];

  /// [audioEnabled] 为 false 时不触碰音频插件，便于无音频环境与单元测试。
  /// [foodSpawner] 注入后每日挑战也复用同一个生成器，方便测试固定食物序列。
  GameProvider(
    this._storage, {
    Random? random,
    FoodSpawner? foodSpawner,
    this.audioEnabled = true,
  }) : _spawnerFactory = foodSpawner == null
           ? ((seed) => FoodSpawner(random: Random(seed)))
           : ((_) => foodSpawner),
       _foodSpawner = foodSpawner ?? FoodSpawner(random: random),
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

  /// 当前选择的玩法模式，下一局生效。
  GameMode get mode => _mode;

  /// 当前连击数，窗口结束后回到 1。
  int get combo => _combo.combo;

  /// 限时挑战的剩余秒数；其它模式返回 null。
  double? get remainingSeconds =>
      _state.mode == GameMode.timed ? _state.remainingSeconds : null;

  /// 最近一局新解锁的成就，开局时清空。
  List<AchievementId> get lastUnlocked => _lastUnlocked;

  /// 当前对局是否为每日挑战。
  bool get isDaily => _daily != null;

  /// 当前每日挑战的排期；普通对局为 null。
  DailyChallenge? get daily => _daily;

  /// 最近一次每日挑战的结算摘要，普通对局为 null。
  DailyResult? get dailyResult => _dailyResult;

  /// 今天的每日挑战排期。
  DailyChallenge get todayChallenge => DailyChallenge.forDate(DateTime.now());

  int get todayBest => DailyService.instance.bestFor(todayChallenge.dateKey);

  /// 今天是否已经完成过一次每日挑战（0 分也算完成）。
  bool get playedToday => DailyService.instance.played(todayChallenge.dateKey);

  /// 连续挑战天数；今天尚未挑战时从昨天开始数。
  int get dailyStreak =>
      DailyService.instance.streakUntil(todayChallenge.dateKey);

  int get dailyBestEver => DailyService.instance.historicalBest;

  int get dailyPlayedDays => DailyService.instance.playedDays;

  PlayerStats get stats => StatsService.instance.stats;

  int get unlockedAchievementCount => AchievementCatalog.unlockedCount(stats);

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

  /// 推进连击窗口与限时倒计时，由游戏循环按真实帧时间调用。
  void tickTime(double dt) {
    if (_state.status != GameStatus.playing) return;

    if (_combo.update(dt)) {
      notifyListeners();
    }
    if (_state.mode != GameMode.timed) return;

    final left = _state.remainingSeconds - dt;
    if (left <= 0) {
      _state = _state.copyWith(remainingSeconds: 0);
      _finish(GameOverReason.timeout);
      return;
    }
    _state = _state.copyWith(remainingSeconds: left);
    final display = left.ceil();
    if (display != _lastTimeDisplay) {
      _lastTimeDisplay = display;
      notifyListeners();
    }
  }

  void start() {
    _dailyResult = null;
    final daily = _daily;
    if (daily == null) {
      startWithLayout(_buildLayout(_state.boardWidth, _state.boardHeight));
      return;
    }
    // 重开每日挑战时重置种子，保证同一局排期内食物序列可复现。
    _applyDailyRules(daily);
    startWithLayout(_buildLayout(daily.boardSize, daily.boardSize));
  }

  /// 预置每日挑战规则但不开始，供游戏页在构建画布前同步棋盘尺寸。
  void prepareDaily(DailyChallenge challenge) {
    _daily = challenge;
    _dailyResult = null;
    _level = challenge.level;
    _mode = challenge.mode;
    _applyDailyRules(challenge);
  }

  /// 每日挑战的棋盘、速度与食物种子；开局与预置共用。
  void _applyDailyRules(DailyChallenge challenge) {
    _foodSpawner = _spawnerFactory(challenge.seed);
    _state = _state.copyWith(
      boardWidth: challenge.boardSize,
      boardHeight: challenge.boardSize,
      speedMs: challenge.speedMs,
    );
  }

  /// 开始今天的每日挑战：规则、棋盘与种子都由 [challenge] 决定。
  void startDaily(DailyChallenge challenge) {
    prepareDaily(challenge);
    startWithLayout(_buildLayout(challenge.boardSize, challenge.boardSize));
  }

  /// 退出每日挑战，下一次 [start] 恢复按设置页规则开局。
  ///
  /// 不主动通知：调用方紧接着会写入新规则并开局，避免在构建期间触发重建。
  void exitDaily() {
    if (_daily == null) return;
    _daily = null;
    _dailyResult = null;
  }

  /// 使用指定布局开局，供自定义关卡与测试使用。
  void startWithLayout(LevelLayout layout) {
    final daily = _daily;
    final prefix = daily == null ? '' : '每日挑战 ${daily.dateKey} ';
    LogService.info('$prefix游戏开始, 关卡: ${_level.label}, 模式: ${_mode.label}');
    final w = _state.boardWidth;
    final h = _state.boardHeight;
    final body = _initialBody(w, h);

    _resetRun();
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
      mode: _mode,
      remainingSeconds: _mode.initialSeconds ?? 0,
      daily: daily,
    );
    notifyListeners();
  }

  /// 出生点：棋盘中央、蛇头朝右的三格蛇身。
  List<Point> _initialBody(int w, int h) {
    final center = w ~/ 2;
    final mid = h ~/ 2;
    return [
      Point(center - 2, mid),
      Point(center - 1, mid),
      Point(center, mid),
    ];
  }

  /// 开局前清空上一局的临时状态，避免道具、连击与成就残留。
  void _resetRun() {
    _powerUps.clear();
    _combo.reset();
    _foodEaten = 0;
    _lastUnlocked = const <AchievementId>[];
    _lastTimeDisplay = (_mode.initialSeconds ?? 0).ceil();
    _nextDirection = Direction.right;
    _directionLocked = false;
  }

  /// 生成当前关卡的布局，并清空出生点所在行，避免开局即撞墙。
  LevelLayout _buildLayout(int w, int h) {
    final center = w ~/ 2;
    final mid = h ~/ 2;
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

  void updateMode(GameMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    LogService.info('选择玩法: ${mode.label}');
    notifyListeners();
  }

  /// 推进一次游戏逻辑，由 Flame 按当前移动间隔调用。
  void tick() {
    if (_state.status != GameStatus.playing) return;

    final snake = _state.snake;
    final direction = _nextDirection;
    _directionLocked = false;

    final head = _resolveHead(snake.head.move(direction));
    if (_isBlocked(head, snake)) {
      if (_consumeShield()) return;
      _finish(GameOverReason.collision);
      return;
    }

    final food = _state.food;
    final ate = _canEat(food, head);
    final body = List<Point>.of(snake.body)..add(head);
    if (!ate) {
      body.removeAt(0);
    }

    var score = _state.score;
    var remaining = _state.remainingSeconds;
    if (ate) {
      _foodEaten++;
      _combo.registerEat();
      score += _scoreForFood();
      if (_state.mode == GameMode.timed) {
        remaining = min(
          GameRules.timedMaxSeconds.toDouble(),
          remaining + GameRules.timedBonusSeconds,
        );
        _lastTimeDisplay = remaining.ceil();
      }
    }

    final previousHighScore = _state.highScore;
    final highScore = max(score, previousHighScore);

    _state = _state.copyWith(
      snake: snake.copyWith(body: body, direction: direction),
      food: ate ? _spawnFood(body) : food,
      score: score,
      highScore: highScore,
      remainingSeconds: remaining,
    );

    if (ate) {
      _applyPickup(food, score);
    }
    if (highScore > previousHighScore) {
      _storage.setHighScore(highScore);
    }

    notifyListeners();
  }

  /// 穿墙与传送门都在这里结算，返回蛇头真正落点。
  Point _resolveHead(Point head) {
    var resolved = head;
    if (_state.mode.wrapsEdges) {
      resolved = Point(
        resolved.x % _state.boardWidth,
        resolved.y % _state.boardHeight,
      );
    }
    final portalExit = _state.layout.portalExit(resolved);
    if (portalExit != null) {
      LogService.info('穿越传送门: $resolved -> $portalExit');
      resolved = portalExit;
    }
    return resolved;
  }

  /// 食物本身或磁铁吸附范围内的一格都算吃到。
  bool _canEat(Food food, Point head) {
    if (head == food.position) return true;
    return _powerUps.has(PowerUpType.magnet) &&
        head.manhattanTo(food.position) <= 1;
  }

  int _scoreForFood() {
    var gain = GameRules.baseFoodScore * _combo.multiplier;
    if (_powerUps.has(PowerUpType.doubleScore)) {
      gain *= 2;
    }
    return gain;
  }

  Food _spawnFood(List<Point> occupied) => _foodSpawner.spawn(
    columns: _state.boardWidth,
    rows: _state.boardHeight,
    occupied: occupied,
    layout: _state.layout,
  );

  /// 护盾抵消一次碰撞；返回 true 表示本步不再结算死亡。
  bool _consumeShield() {
    if (!_powerUps.consumeShield()) return false;
    if (audioEnabled) {
      AudioService().playShieldBreak();
    }
    LogService.info('护盾抵挡了一次碰撞');
    notifyListeners();
    return true;
  }

  /// 拾取后的道具激活、音效与日志。
  void _applyPickup(Food food, int score) {
    final type = food.type;
    if (type == null) {
      LogService.info('吃到食物, 得分: $score, 连击: ${_combo.combo}');
      if (audioEnabled) {
        AudioService().playEat();
      }
      return;
    }
    _powerUps.activate(type);
    LogService.info('拾取道具: ${type.label}, 得分: $score');
    if (audioEnabled) {
      AudioService().playPowerUp();
    }
  }

  bool _isBlocked(Point head, Snake snake) {
    if (head.x < 0 ||
        head.x >= _state.boardWidth ||
        head.y < 0 ||
        head.y >= _state.boardHeight) {
      return true;
    }
    if (_state.layout.isWall(head)) return true;
    // 尾巴会在本步移开，因此从下标 1 开始判定。
    for (var i = 1; i < snake.body.length; i++) {
      if (snake.body[i] == head) return true;
    }
    return false;
  }

  void _finish(GameOverReason reason) {
    LogService.info(
      '游戏结束(${reason.label}), 得分: ${_state.score}, 连击: ${_combo.best}',
    );
    if (audioEnabled) {
      AudioService().playGameOver();
    }
    _recordScore();
    final highScore = _recordStats();
    _combo.reset();
    _state = _state.copyWith(
      status: GameStatus.over,
      highScore: highScore,
      overReason: reason,
    );
    notifyListeners();
  }

  /// 排行榜与每日挑战成绩：结算时立即写入，不阻塞界面。
  void _recordScore() {
    unawaited(LeaderboardService.addScore(_state.score));
    final daily = _daily;
    if (daily != null) {
      _dailyResult = DailyService.instance.record(daily.dateKey, _state.score);
    }
  }

  /// 累计统计与成就解锁；返回刷新后的最高分。
  int _recordStats() {
    final newHighScore = max(_state.score, _state.highScore);
    if (newHighScore > _state.highScore) {
      _storage.setHighScore(newHighScore);
    }
    _powerUps.clear();
    final update = StatsService.instance.record(
      GameRun(
        mode: _state.mode,
        score: _state.score,
        bestCombo: _combo.best,
        length: _state.snake.body.length,
        food: _foodEaten,
      ),
    );
    _lastUnlocked = update.unlocked;
    if (update.unlocked.isNotEmpty) {
      LogService.info(
        '解锁成就: ${update.unlocked.map((id) => id.title).join('、')}',
      );
    }
    return newHighScore;
  }
}
