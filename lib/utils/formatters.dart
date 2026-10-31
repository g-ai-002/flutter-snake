/// 全局共享的时间格式化工具。
///
/// 日期键、日志行首时间戳与列表时间此前分散在每日挑战、日志服务、排行榜与
/// 统计页各自实现，格式一旦需要调整容易改漏，这里统一收口。
library;

/// 两位补零，如 `7` → `07`。
String pad2(int value) => value.toString().padLeft(2, '0');

/// `yyyyMMdd`：补零后长度固定，字典序即时间序。
String formatDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}${pad2(date.month)}${pad2(date.day)}';

/// `HH:mm:ss.SSS`：日志行首时间戳。
String formatLogTimestamp(DateTime time) =>
    '${pad2(time.hour)}:${pad2(time.minute)}:${pad2(time.second)}.'
    '${time.millisecond.toString().padLeft(3, '0')}';

/// 日志整行：`[HH:mm:ss.SSS][LEVEL] 内容`。
String formatLogLine(DateTime time, String level, String message) =>
    '[${formatLogTimestamp(time)}][$level] $message';

/// `yyyy-MM-dd HH:mm`：排行榜等需要完整日期的列表。
String formatDateTime(DateTime date) =>
    '${date.year}-${pad2(date.month)}-${pad2(date.day)} '
    '${pad2(date.hour)}:${pad2(date.minute)}';

/// `MM-dd HH:mm`：统计页等空间紧张的列表。
String formatShortDateTime(DateTime date) =>
    '${pad2(date.month)}-${pad2(date.day)} '
    '${pad2(date.hour)}:${pad2(date.minute)}';
