import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../models/game_mode.dart';

/// 玩法模式在设置页/主页上的图标。
IconData modeIcon(GameMode mode) {
  switch (mode) {
    case GameMode.classic:
      return Icons.sports_esports;
    case GameMode.wrap:
      return Icons.sync_alt;
    case GameMode.timed:
      return Icons.timer_outlined;
  }
}

/// 成就在成就页与结算页上的图标。
IconData achievementIcon(AchievementId id) {
  switch (id) {
    case AchievementId.firstGame:
      return Icons.flag;
    case AchievementId.games10:
      return Icons.repeat;
    case AchievementId.games50:
      return Icons.military_tech;
    case AchievementId.score100:
      return Icons.looks_one_outlined;
    case AchievementId.score300:
      return Icons.looks_3_outlined;
    case AchievementId.score500:
      return Icons.workspace_premium;
    case AchievementId.food50:
      return Icons.restaurant;
    case AchievementId.combo3:
      return Icons.bolt;
    case AchievementId.combo5:
      return Icons.flash_on;
    case AchievementId.combo8:
      return Icons.whatshot;
    case AchievementId.length10:
      return Icons.timeline;
    case AchievementId.length20:
      return Icons.straighten;
    case AchievementId.length30:
      return Icons.gesture;
    case AchievementId.allModes:
      return Icons.dashboard_customize;
    case AchievementId.timed300:
      return Icons.hourglass_bottom;
  }
}
