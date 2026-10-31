import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_snake/models/daily_challenge.dart';
import 'package:flutter_snake/services/daily_service.dart';

String _key(DateTime date) => DailyChallenge.keyFor(date);

void main() {
  setUp(() => DailyService.instance.resetForTest());

  test('首次完成记录今日最佳与连续 1 天', () {
    final result = DailyService.instance.record('20261031', 80);

    expect(result.score, 80);
    expect(result.bestScore, 80);
    expect(result.isNewBest, isTrue);
    expect(result.streak, 1);
    expect(DailyService.instance.bestFor('20261031'), 80);
    expect(DailyService.instance.played('20261031'), isTrue);
    expect(DailyService.instance.playedDays, 1);
    expect(DailyService.instance.historicalBest, 80);
  });

  test('同一天只保留最好成绩', () {
    final service = DailyService.instance;
    service.record('20261031', 100);

    final lower = service.record('20261031', 60);
    expect(lower.bestScore, 100);
    expect(lower.isNewBest, isFalse);

    final higher = service.record('20261031', 120);
    expect(higher.bestScore, 120);
    expect(higher.isNewBest, isTrue);
    expect(service.playedDays, 1);
  });

  test('连续天数跨日累计', () {
    final service = DailyService.instance;
    service.record('20261029', 10);
    service.record('20261030', 20);
    service.record('20261031', 30);

    expect(service.streakUntil('20261031'), 3);
    // 新的一天还没挑战时，从昨天开始数，连胜仍然有效。
    expect(service.streakUntil('20261101'), 3);
  });

  test('断档后只统计最近一段连续天数', () {
    final service = DailyService.instance;
    service.record('20261028', 10);
    service.record('20261030', 20);
    service.record('20261031', 30);

    expect(service.streakUntil('20261031'), 2);
    expect(service.streakUntil('20261102'), 0);
  });

  test('非法日期键返回 0 天', () {
    expect(DailyService.instance.streakUntil('bad-key'), 0);
  });

  test('记录最多保留最近 60 天', () {
    final service = DailyService.instance;
    final first = DateTime(2026);
    for (var i = 0; i < 70; i++) {
      service.record(_key(first.add(Duration(days: i))), i);
    }

    expect(service.playedDays, DailyService.maxDays);
    expect(service.played(_key(first)), isFalse);
    expect(service.played(_key(first.add(const Duration(days: 69)))), isTrue);
  });
}
