import 'package:flutter/services.dart';

import '../models/daily_challenge.dart';
import '../models/game_mode.dart';
import '../models/player_stats.dart';
import 'log_service.dart';

/// 战绩文本生成与剪贴板复制。
///
/// 不依赖第三方分享插件：把战绩整理成纯文本复制到剪贴板，
/// 用户可以自行粘贴到任意聊天工具，包体与权限都不增加。
class ShareService {
  ShareService._();

  /// 单局战绩文本，每日挑战会额外带上当日排期。
  static String buildRunText({
    required GameMode mode,
    required int score,
    required int highScore,
    required String reasonLabel,
    DailyChallenge? daily,
  }) {
    return <String>[
      '🐍 贪吃蛇 · ${daily == null ? mode.label : '每日挑战'}',
      if (daily != null) '${daily.weekdayLabel} · ${daily.subtitle}',
      '得分 $score · 最高分 $highScore',
      '结束方式：$reasonLabel',
    ].join('\n');
  }

  /// 生涯战绩文本，用于数据统计页的一键分享。
  static String buildCareerText({
    required PlayerStats stats,
    required int achievements,
    required int achievementTotal,
    required int streak,
    required int dailyBest,
  }) {
    return <String>[
      '🐍 贪吃蛇生涯战绩',
      '最高分 ${stats.bestScore} · 总局数 ${stats.gamesPlayed}',
      '累计食物 ${stats.totalFood} · 最佳连击 x${stats.bestCombo} · '
          '最长蛇身 ${stats.bestLength}',
      '成就 $achievements/$achievementTotal · 每日挑战连续 $streak 天 · '
          '每日最佳 $dailyBest',
    ].join('\n');
  }

  /// 复制文本到剪贴板；失败时只记录日志，不打断结算界面。
  static Future<bool> copy(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      LogService.info('战绩已复制到剪贴板');
      return true;
    } catch (e) {
      LogService.warning('战绩复制失败: $e');
      return false;
    }
  }
}
