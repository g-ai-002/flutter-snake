import 'dart:math' as math;

import 'player_stats.dart';

/// 成就定义：目标值、标题与说明。
enum AchievementId {
  firstGame(target: 1, title: '初次登场', description: '完成第一局游戏'),
  games10(target: 10, title: '老玩家', description: '累计完成 10 局游戏'),
  games50(target: 50, title: '常驻选手', description: '累计完成 50 局游戏'),
  score100(target: 100, title: '百分达成', description: '单局得分达到 100'),
  score300(target: 300, title: '三百分', description: '单局得分达到 300'),
  score500(target: 500, title: '蛇王', description: '单局得分达到 500'),
  food50(target: 50, title: '美食家', description: '累计吃到 50 个食物'),
  combo3(target: 3, title: '连击新手', description: '一次连击达到 3'),
  combo5(target: 5, title: '连击高手', description: '一次连击达到 5'),
  combo8(target: 8, title: '连击大师', description: '一次连击达到 8'),
  length10(target: 10, title: '初长成', description: '蛇身长度达到 10'),
  length20(target: 20, title: '长蛇', description: '蛇身长度达到 20'),
  length30(target: 30, title: '巨蟒', description: '蛇身长度达到 30'),
  allModes(target: 3, title: '全能选手', description: '三种玩法各完成一局'),
  timed300(target: 300, title: '限时猎手', description: '限时挑战单局得分达到 300');

  const AchievementId({
    required this.target,
    required this.title,
    required this.description,
  });

  final int target;
  final String title;
  final String description;
}

extension AchievementInfo on AchievementId {
  /// 当前统计下的进度值，用于展示进度条。
  int progress(PlayerStats stats) {
    switch (this) {
      case AchievementId.firstGame:
      case AchievementId.games10:
      case AchievementId.games50:
        return stats.gamesPlayed;
      case AchievementId.score100:
      case AchievementId.score300:
      case AchievementId.score500:
        return stats.bestScore;
      case AchievementId.food50:
        return stats.totalFood;
      case AchievementId.combo3:
      case AchievementId.combo5:
      case AchievementId.combo8:
        return stats.bestCombo;
      case AchievementId.length10:
      case AchievementId.length20:
      case AchievementId.length30:
        return stats.bestLength;
      case AchievementId.allModes:
        return stats.modesPlayed.length;
      case AchievementId.timed300:
        return stats.bestTimedScore;
    }
  }

  bool isUnlocked(PlayerStats stats) => progress(stats) >= target;

  double progressRatio(PlayerStats stats) =>
      (progress(stats) / target).clamp(0.0, 1.0).toDouble();

  /// 展示用的进度文本，例如 `3/10`。
  String progressLabel(PlayerStats stats) =>
      '${math.min(progress(stats), target)}/$target';
}

class AchievementCatalog {
  AchievementCatalog._();

  static List<AchievementId> get all => AchievementId.values;

  static int unlockedCount(PlayerStats stats) =>
      all.where((id) => id.isUnlocked(stats)).length;

  /// 相邻两次统计之间新解锁的成就。
  static List<AchievementId> newlyUnlocked(
    PlayerStats before,
    PlayerStats after,
  ) {
    return <AchievementId>[
      for (final id in all)
        if (!id.isUnlocked(before) && id.isUnlocked(after)) id,
    ];
  }
}
