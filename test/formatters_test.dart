import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_snake/models/daily_challenge.dart';
import 'package:flutter_snake/utils/formatters.dart';

void main() {
  group('时间格式化', () {
    test('两位补零', () {
      expect(pad2(7), '07');
      expect(pad2(12), '12');
      expect(pad2(0), '00');
    });

    test('日期键固定 8 位且字典序即时间序', () {
      final early = formatDateKey(DateTime(2026, 1, 5));
      final late = formatDateKey(DateTime(2026, 12, 31));
      expect(early, '20260105');
      expect(late, '20261231');
      expect(early.compareTo(late), lessThan(0));
    });

    test('每日挑战日期键与公共格式化一致', () {
      final date = DateTime(2026, 10, 31);
      expect(DailyChallenge.keyFor(date), formatDateKey(date));
    });

    test('日志时间戳带毫秒', () {
      expect(
        formatLogTimestamp(DateTime(2026, 10, 31, 8, 5, 3, 42)),
        '08:05:03.042',
      );
    });

    test('日志整行格式', () {
      expect(
        formatLogLine(DateTime(2026, 10, 31, 8, 5, 3, 42), 'INFO', '启动完成'),
        '[08:05:03.042][INFO] 启动完成',
      );
    });

    test('完整与紧凑时间用于不同列表', () {
      final date = DateTime(2026, 3, 9, 7, 8);
      expect(formatDateTime(date), '2026-03-09 07:08');
      expect(formatShortDateTime(date), '03-09 07:08');
    });
  });
}
