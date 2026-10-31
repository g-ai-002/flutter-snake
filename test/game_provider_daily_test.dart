import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_snake/models/daily_challenge.dart';
import 'package:flutter_snake/models/game_mode.dart';
import 'package:flutter_snake/models/level.dart';
import 'package:flutter_snake/providers/game_provider.dart';
import 'package:flutter_snake/services/daily_service.dart';
import 'package:flutter_snake/services/stats_service.dart';

import 'fakes/fake_storage.dart';

const DailyChallenge _challenge = DailyChallenge(
  dateKey: '20261031',
  seed: 20261031,
  level: LevelType.open,
  mode: GameMode.classic,
  boardSize: 15,
  speedMs: 200,
  weekday: DateTime.saturday,
);

GameProvider _game(FakeStorageService storage) =>
    GameProvider(storage, audioEnabled: false);

void main() {
  setUp(() {
    StatsService.instance.resetForTest();
    DailyService.instance.resetForTest();
  });

  test('每日挑战按排期覆盖关卡、模式、棋盘与速度', () {
    final game = _game(FakeStorageService.create())..startDaily(_challenge);

    expect(game.isDaily, isTrue);
    expect(game.state.daily?.dateKey, _challenge.dateKey);
    expect(game.state.level, LevelType.open);
    expect(game.state.mode, GameMode.classic);
    expect(game.state.boardWidth, 15);
    expect(game.state.boardHeight, 15);
    expect(game.state.speedMs, 200);
    expect(game.isPlaying, isTrue);
  });

  test('同一个种子生成相同的棋盘食物序列', () {
    final first = _game(FakeStorageService.create())..startDaily(_challenge);
    final second = _game(FakeStorageService.create())..startDaily(_challenge);

    expect(first.state.food.position, second.state.food.position);
    expect(first.state.food.type, second.state.food.type);
  });

  test('重开每日挑战会重置种子并保留挑战标记', () {
    final game = _game(FakeStorageService.create())..startDaily(_challenge);
    final firstFood = game.state.food.position;

    game.start();

    expect(game.isDaily, isTrue);
    expect(game.state.food.position, firstFood);
    expect(game.state.daily?.dateKey, _challenge.dateKey);
    expect(game.isPlaying, isTrue);
  });

  test('结算时写入当日成绩并返回连胜', () {
    final game = _game(FakeStorageService.create())..startDaily(_challenge);

    for (var i = 0; i < 200 && !game.isOver; i++) {
      game.tick();
    }

    expect(game.isOver, isTrue);
    expect(DailyService.instance.played(_challenge.dateKey), isTrue);
    expect(game.dailyResult, isNotNull);
    expect(game.dailyResult!.dateKey, _challenge.dateKey);
    expect(game.dailyResult!.bestScore, game.state.score);
    expect(game.dailyResult!.streak, 1);
  });

  test('退出每日挑战后按普通规则开局', () {
    final game = _game(FakeStorageService.create())..startDaily(_challenge);
    game.exitDaily();

    expect(game.isDaily, isFalse);
    expect(game.dailyResult, isNull);

    game.updateBoardSize(20);
    game.start();
    expect(game.state.daily, isNull);
    expect(game.state.boardWidth, 20);
  });

  test('今日挑战与排行数据可从每日服务读取', () {
    final game = _game(FakeStorageService.create());
    final today = game.todayChallenge.dateKey;
    DailyService.instance.record(today, 55);

    expect(game.todayBest, 55);
    expect(game.dailyStreak, 1);
    expect(game.dailyBestEver, 55);
    expect(game.dailyPlayedDays, 1);
  });
}
