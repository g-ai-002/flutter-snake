import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_challenge.dart';
import 'log_service.dart';

/// 一次每日挑战结算的结果摘要。
class DailyResult {
  const DailyResult({
    required this.dateKey,
    required this.score,
    required this.bestScore,
    required this.isNewBest,
    required this.streak,
  });

  final String dateKey;
  final int score;
  final int bestScore;
  final bool isNewBest;

  /// 含当天的连续挑战天数。
  final int streak;
}

/// 每日挑战成绩的读写入口。
///
/// [record] 同步更新内存并异步落盘，结算界面可以立即展示今日最佳与连胜；
/// 存储不可用时只记录日志，不影响游戏主流程。
class DailyService {
  DailyService._();

  static final DailyService instance = DailyService._();

  static const String _key = 'daily_challenge_scores';

  /// 只保留最近 60 天，避免记录无限增长。
  static const int maxDays = 60;

  Map<String, int> _scores = <String, int>{};

  Map<String, int> get scores => Map<String, int>.unmodifiable(_scores);

  int get playedDays => _scores.length;

  /// 历史单日最高分。
  int get historicalBest => _scores.values.fold(0, math.max);

  int bestFor(String dateKey) => _scores[dateKey] ?? 0;

  bool played(String dateKey) => _scores.containsKey(dateKey);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final scores = <String, int>{};
      decoded.forEach((key, value) {
        if (key is String && value is int) scores[key] = value;
      });
      _scores = scores;
    } catch (e) {
      LogService.warning('每日挑战成绩读取失败: $e');
    }
  }

  /// 提交一次成绩，只保留当日最好成绩；返回展示所需的摘要。
  DailyResult record(String dateKey, int score) {
    final firstPlay = !played(dateKey);
    final previous = bestFor(dateKey);
    final best = math.max(previous, score);
    final isNewBest = score > previous;
    _scores[dateKey] = best;
    _prune();
    unawaited(_persist());
    final streak = streakUntil(dateKey);
    if (firstPlay) {
      LogService.info('每日挑战: $dateKey 首次完成, 得分 $score, 连续 $streak 天');
    } else {
      LogService.info('每日挑战: $dateKey 得分 $score, 最佳 $best, 连续 $streak 天');
    }
    return DailyResult(
      dateKey: dateKey,
      score: score,
      bestScore: best,
      isNewBest: isNewBest,
      streak: streak,
    );
  }

  /// 从 [dateKey] 向前数连续挑战天数。
  ///
  /// 当天还没挑战时从昨天开始数，这样新的一天开局前仍能看到有效连胜。
  int streakUntil(String dateKey) {
    final parsed = DailyChallenge.dateFromKey(dateKey);
    if (parsed == null) return 0;
    var day = parsed;
    if (!played(dateKey)) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var count = 0;
    while (played(DailyChallenge.keyFor(day))) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  /// 按日期排序保留最近 [maxDays] 天。
  void _prune() {
    if (_scores.length <= maxDays) return;
    final keys = _scores.keys.toList()..sort((a, b) => b.compareTo(a));
    final kept = keys.take(maxDays);
    _scores = <String, int>{for (final key in kept) key: _scores[key]!};
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_scores));
    } catch (e) {
      LogService.warning('每日挑战成绩保存失败: $e');
    }
  }

  /// 仅用于测试：清空内存记录，避免用例之间互相影响。
  @visibleForTesting
  void resetForTest() {
    _scores = <String, int>{};
  }
}
