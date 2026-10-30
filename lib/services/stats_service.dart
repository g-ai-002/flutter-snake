import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement.dart';
import '../models/player_stats.dart';
import 'log_service.dart';

/// 一次结算带来的统计变化与新解锁成就。
class StatsUpdate {
  const StatsUpdate({required this.stats, required this.unlocked});

  final PlayerStats stats;
  final List<AchievementId> unlocked;
}

/// 玩家统计的读写入口。
///
/// [record] 同步更新内存并异步落盘，保证结算界面能立即展示新成就；
/// 存储不可用时只记录日志，不影响游戏主流程。
class StatsService {
  StatsService._();

  static final StatsService instance = StatsService._();

  static const String _key = 'player_stats';

  PlayerStats _stats = PlayerStats.empty;

  PlayerStats get stats => _stats;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _stats = PlayerStats.fromJson(decoded);
      }
    } catch (e) {
      LogService.warning('玩家统计读取失败: $e');
    }
  }

  StatsUpdate record(GameRun run) {
    final before = _stats;
    _stats = before.merge(run);
    final unlocked = AchievementCatalog.newlyUnlocked(before, _stats);
    unawaited(_persist(_stats));
    return StatsUpdate(stats: _stats, unlocked: unlocked);
  }

  Future<void> _persist(PlayerStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(stats.toJson()));
    } catch (e) {
      LogService.warning('玩家统计保存失败: $e');
    }
  }

  /// 仅用于测试：清空内存统计，避免用例之间互相影响。
  @visibleForTesting
  void resetForTest() {
    _stats = PlayerStats.empty;
  }
}
