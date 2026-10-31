import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_snake/models/daily_challenge.dart';
import 'package:flutter_snake/models/game_mode.dart';
import 'package:flutter_snake/models/level.dart';
import 'package:flutter_snake/utils/constants.dart';

void main() {
  test('同一天任意时刻生成同一套挑战', () {
    final morning = DailyChallenge.forDate(DateTime(2026, 10, 31, 8, 30));
    final night = DailyChallenge.forDate(DateTime(2026, 10, 31, 23, 59));

    expect(morning.dateKey, '20261031');
    expect(morning.seed, night.seed);
    expect(morning.level, night.level);
    expect(morning.mode, night.mode);
    expect(morning.boardSize, night.boardSize);
    expect(morning.speedMs, night.speedMs);
    expect(morning.weekday, DateTime.saturday);
    expect(morning.weekdayLabel, '周六');
  });

  test('相邻日期的日期键与种子都不同', () {
    final today = DailyChallenge.forDate(DateTime(2026, 10, 31));
    final tomorrow = DailyChallenge.forDate(DateTime(2026, 11));

    expect(today.dateKey, isNot(tomorrow.dateKey));
    expect(today.seed, isNot(tomorrow.seed));
    expect(tomorrow.dateKey, '20261101');
  });

  test('一周七天都按排期表给出合法规则', () {
    final boards = AppConstants.boardOptions.map((o) => o.size).toSet();
    expect(DailyChallenge.weeklyPresets, hasLength(7));

    for (var offset = 0; offset < 7; offset++) {
      // 2026-10-26 是周一。
      final date = DateTime(2026, 10, 26 + offset);
      final challenge = DailyChallenge.forDate(date);

      expect(challenge.weekday, offset + 1);
      expect(challenge.weekdayLabel, isNotEmpty);
      expect(boards, contains(challenge.boardSize));
      expect(challenge.speedMs, greaterThan(0));
      expect(challenge.seed, greaterThan(0));
    }
  });

  test('日期键解析对非法输入返回 null', () {
    expect(DailyChallenge.dateFromKey('20261031'), DateTime(2026, 10, 31));
    expect(DailyChallenge.dateFromKey('20260231'), isNull);
    expect(DailyChallenge.dateFromKey('20261301'), isNull);
    expect(DailyChallenge.dateFromKey('2026-10-31'), isNull);
    expect(DailyChallenge.dateFromKey(''), isNull);
  });

  test('副标题包含关卡、模式与棋盘尺寸', () {
    final challenge = DailyChallenge.forDate(DateTime(2026, 10, 31));
    expect(challenge.subtitle, contains(challenge.level.label));
    expect(challenge.subtitle, contains(challenge.mode.label));
    expect(challenge.subtitle, contains('${challenge.boardSize}×'));
  });
}
