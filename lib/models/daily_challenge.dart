import '../utils/formatters.dart';
import 'game_mode.dart';
import 'level.dart';

/// 每日挑战的固定排期：一周七天各有确定的关卡、玩法与棋盘。
class DailyPreset {
  const DailyPreset({
    required this.level,
    required this.mode,
    required this.boardSize,
    required this.speedMs,
  });

  final LevelType level;
  final GameMode mode;
  final int boardSize;
  final int speedMs;
}

/// 每日挑战：按日期确定随机种子与规则。
///
/// 同一天所有玩家拿到同一个种子，因此食物与道具的生成顺序完全一致，
/// 分数具备可比性；次日自动切换到下一套排期。
class DailyChallenge {
  const DailyChallenge({
    required this.dateKey,
    required this.seed,
    required this.level,
    required this.mode,
    required this.boardSize,
    required this.speedMs,
    required this.weekday,
  });

  /// 形如 `20261031` 的日期标识，同时作为成绩记录的存储键。
  final String dateKey;

  /// 食物生成器的随机种子。
  final int seed;
  final LevelType level;
  final GameMode mode;
  final int boardSize;
  final int speedMs;

  /// ISO 星期：1 = 周一，7 = 周日。
  final int weekday;

  /// 周一至周日的排期，索引与 [weekday] - 1 对应。
  static const List<DailyPreset> weeklyPresets = <DailyPreset>[
    DailyPreset(
      level: LevelType.open,
      mode: GameMode.classic,
      boardSize: 20,
      speedMs: 200,
    ),
    DailyPreset(
      level: LevelType.border,
      mode: GameMode.wrap,
      boardSize: 20,
      speedMs: 180,
    ),
    DailyPreset(
      level: LevelType.pillars,
      mode: GameMode.classic,
      boardSize: 15,
      speedMs: 170,
    ),
    DailyPreset(
      level: LevelType.cross,
      mode: GameMode.timed,
      boardSize: 20,
      speedMs: 200,
    ),
    DailyPreset(
      level: LevelType.maze,
      mode: GameMode.classic,
      boardSize: 25,
      speedMs: 200,
    ),
    DailyPreset(
      level: LevelType.portals,
      mode: GameMode.wrap,
      boardSize: 20,
      speedMs: 160,
    ),
    DailyPreset(
      level: LevelType.pillars,
      mode: GameMode.timed,
      boardSize: 15,
      speedMs: 180,
    ),
  ];

  factory DailyChallenge.forDate(DateTime date) {
    final weekday = date.weekday;
    final preset = weeklyPresets[(weekday - 1) % weeklyPresets.length];
    final key = keyFor(date);
    return DailyChallenge(
      dateKey: key,
      seed: seedForKey(key),
      level: preset.level,
      mode: preset.mode,
      boardSize: preset.boardSize,
      speedMs: preset.speedMs,
      weekday: weekday,
    );
  }

  /// `yyyyMMdd`，补零后长度固定，字典序即时间序。
  static String keyFor(DateTime date) => formatDateKey(date);

  /// 由日期键生成稳定的 31 位种子，不依赖平台与运行环境。
  static int seedForKey(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  /// 日期键转回当天零点；格式非法时返回 null。
  static DateTime? dateFromKey(String key) {
    if (key.length != 8) return null;
    final year = int.tryParse(key.substring(0, 4));
    final month = int.tryParse(key.substring(4, 6));
    final day = int.tryParse(key.substring(6));
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }

  String get weekdayLabel {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[(weekday - 1) % labels.length];
  }

  String get subtitle =>
      '${level.label} · ${mode.label} · $boardSize×$boardSize · ${speedMs}ms';
}
