import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_snake/models/daily_challenge.dart';
import 'package:flutter_snake/models/game_mode.dart';
import 'package:flutter_snake/models/player_stats.dart';
import 'package:flutter_snake/services/share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('单局战绩文本包含模式、得分与结束方式', () {
    final text = ShareService.buildRunText(
      mode: GameMode.timed,
      score: 120,
      highScore: 340,
      reasonLabel: '时间到',
    );

    expect(text, contains('贪吃蛇 · 限时挑战'));
    expect(text, contains('得分 120 · 最高分 340'));
    expect(text, contains('结束方式：时间到'));
    expect(text, isNot(contains('每日挑战')));
  });

  test('每日挑战战绩带上当日排期', () {
    final daily = DailyChallenge.forDate(DateTime(2026, 10, 30));
    final text = ShareService.buildRunText(
      mode: daily.mode,
      score: 88,
      highScore: 200,
      reasonLabel: '游戏结束',
      daily: daily,
    );

    expect(text, contains('贪吃蛇 · 每日挑战'));
    expect(text, contains(daily.weekdayLabel));
    expect(text, contains(daily.subtitle));
  });

  test('生涯战绩文本汇总累计数据', () {
    final text = ShareService.buildCareerText(
      stats: const PlayerStats(
        gamesPlayed: 12,
        totalFood: 88,
        bestScore: 340,
        bestCombo: 5,
        bestLength: 18,
      ),
      achievements: 7,
      achievementTotal: 15,
      streak: 3,
      dailyBest: 120,
    );

    expect(text, contains('最高分 340 · 总局数 12'));
    expect(text, contains('累计食物 88 · 最佳连击 x5 · 最长蛇身 18'));
    expect(text, contains('成就 7/15 · 每日挑战连续 3 天 · 每日最佳 120'));
  });

  test('复制战绩写入剪贴板', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final ok = await ShareService.copy('🐍 测试战绩');

    expect(ok, isTrue);
    final setData = calls.firstWhere(
      (call) => call.method == 'Clipboard.setData',
    );
    expect((setData.arguments as Map)['text'], '🐍 测试战绩');
  });
}
