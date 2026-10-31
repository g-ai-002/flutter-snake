import 'package:flutter/material.dart';

import '../models/daily_challenge.dart';
import '../services/daily_service.dart';
import 'widgets/section_card.dart';
import 'widgets/stat_metric.dart';

/// 每日挑战日历：按月回顾挑战完成情况与单日最佳成绩。
class DailyCalendarPage extends StatefulWidget {
  const DailyCalendarPage({super.key});

  @override
  State<DailyCalendarPage> createState() => _DailyCalendarPageState();
}

class _DailyCalendarPageState extends State<DailyCalendarPage> {
  static const List<String> _weekdayLabels = [
    '一',
    '二',
    '三',
    '四',
    '五',
    '六',
    '日',
  ];

  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  bool get _atCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _shiftMonth(int delta) {
    if (delta > 0 && _atCurrentMonth) return;
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  /// 点击日期：查看当天排期与成绩，历史日期只做回顾。
  Future<void> _showDay(DateTime date) {
    final challenge = DailyChallenge.forDate(date);
    final key = DailyChallenge.keyFor(date);
    final played = DailyService.instance.played(key);
    final score = DailyService.instance.bestFor(key);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.month}月${date.day}日 · ${challenge.weekdayLabel}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  challenge.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(
                      played ? Icons.military_tech : Icons.flag_outlined,
                      color: played ? colors.primary : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      played ? '最佳成绩 $score 分' : '当日未挑战',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '每日挑战按日期固定规则与种子，仅当天可参与。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final service = DailyService.instance;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = DateTime(_month.year, _month.month).weekday - 1;
    final todayKey = DailyChallenge.keyFor(_today);
    final playedDays = service.keysInMonth(_month).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日挑战日历'),
        actions: [
          if (!_atCurrentMonth)
            TextButton(
              onPressed: () {
                final now = DateTime.now();
                setState(() => _month = DateTime(now.year, now.month));
              },
              child: const Text('本月'),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                SectionCard(
                  icon: Icons.insights,
                  title: '本月概览',
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _metric('完成天数', '$playedDays/$daysInMonth'),
                      _metric('本月最佳', '${service.bestInMonth(_month)}'),
                      _metric('历史最佳', '${service.historicalBest}'),
                      _metric('连续天数', '${service.streakUntil(todayKey)}'),
                    ],
                  ),
                ),
                SectionCard(
                  icon: Icons.calendar_month,
                  title: '${_month.year}年${_month.month}月',
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        tooltip: '上个月',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _shiftMonth(-1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        tooltip: '下个月',
                        visualDensity: VisualDensity.compact,
                        onPressed: _atCurrentMonth
                            ? null
                            : () => _shiftMonth(1),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (final label in _weekdayLabels)
                            Expanded(
                              child: Center(
                                child: Text(
                                  label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 0.84,
                        children: [
                          for (var i = 0; i < leading; i++)
                            const SizedBox.shrink(),
                          for (var day = 1; day <= daysInMonth; day++)
                            _buildDay(day),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '每日挑战保留最近 ${DailyService.maxDays} 天记录，'
                  '高亮格表示已完成。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDay(int day) {
    final date = DateTime(_month.year, _month.month, day);
    final key = DailyChallenge.keyFor(date);
    final service = DailyService.instance;
    return _DayCell(
      key: ValueKey('day-$key'),
      date: date,
      score: service.played(key) ? service.bestFor(key) : null,
      isToday: key == DailyChallenge.keyFor(_today),
      isFuture: date.isAfter(_today),
      onTap: () => _showDay(date),
    );
  }

  static Widget _metric(String label, String value) {
    return StatMetric(label: label, value: value, width: 108);
  }
}

/// 单个日期格：日期数字 + 已挑战时的成绩。
class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.date,
    required this.score,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime date;
  final int? score;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final played = score != null;
    final background = played
        ? colors.primaryContainer.withValues(alpha: 0.55)
        : colors.surfaceContainerHighest.withValues(
            alpha: isFuture ? 0.16 : 0.34,
          );
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: isToday
                ? Border.all(color: colors.primary, width: 1.4)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : null,
                  color: isFuture
                      ? colors.onSurfaceVariant.withValues(alpha: 0.6)
                      : null,
                ),
              ),
              if (played)
                Text(
                  '$score',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
