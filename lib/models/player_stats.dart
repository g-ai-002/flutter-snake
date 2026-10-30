import 'dart:math' as math;

import 'game_mode.dart';

/// 单局结算时提交给统计系统的摘要。
class GameRun {
  const GameRun({
    required this.mode,
    required this.score,
    required this.bestCombo,
    required this.length,
    required this.food,
  });

  final GameMode mode;
  final int score;
  final int bestCombo;
  final int length;
  final int food;
}

/// 跨局累计的玩家统计，用于成就判定。
class PlayerStats {
  const PlayerStats({
    this.gamesPlayed = 0,
    this.totalFood = 0,
    this.bestScore = 0,
    this.bestCombo = 1,
    this.bestLength = 0,
    this.bestTimedScore = 0,
    this.modesPlayed = const <GameMode>{},
  });

  static const PlayerStats empty = PlayerStats();

  final int gamesPlayed;
  final int totalFood;
  final int bestScore;
  final int bestCombo;
  final int bestLength;
  final int bestTimedScore;
  final Set<GameMode> modesPlayed;

  /// 合并一局结果；所有最好成绩取最大值。
  PlayerStats merge(GameRun run) {
    return PlayerStats(
      gamesPlayed: gamesPlayed + 1,
      totalFood: totalFood + run.food,
      bestScore: math.max(bestScore, run.score),
      bestCombo: math.max(bestCombo, run.bestCombo),
      bestLength: math.max(bestLength, run.length),
      bestTimedScore: run.mode == GameMode.timed
          ? math.max(bestTimedScore, run.score)
          : bestTimedScore,
      modesPlayed: <GameMode>{...modesPlayed, run.mode},
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'gamesPlayed': gamesPlayed,
    'totalFood': totalFood,
    'bestScore': bestScore,
    'bestCombo': bestCombo,
    'bestLength': bestLength,
    'bestTimedScore': bestTimedScore,
    'modesPlayed': modesPlayed.map((mode) => mode.name).toList(),
  };

  /// 宽容解析：缺字段或未知模式名都回退到默认值。
  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    final modes = <GameMode>{};
    final rawModes = json['modesPlayed'];
    if (rawModes is List) {
      for (final raw in rawModes) {
        for (final mode in GameMode.values) {
          if (mode.name == raw) modes.add(mode);
        }
      }
    }
    return PlayerStats(
      gamesPlayed: _asInt(json['gamesPlayed']),
      totalFood: _asInt(json['totalFood']),
      bestScore: _asInt(json['bestScore']),
      bestCombo: math.max(1, _asInt(json['bestCombo'])),
      bestLength: _asInt(json['bestLength']),
      bestTimedScore: _asInt(json['bestTimedScore']),
      modesPlayed: modes,
    );
  }

  static int _asInt(Object? value) => value is int ? value : 0;
}
