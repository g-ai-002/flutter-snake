import 'package:flutter/material.dart';

/// 统计数值 + 标签的紧凑展示单元。
///
/// 数据统计页与成就页都需要「数值在上、标签在下」的指标块，
/// 这里统一实现，避免两处各写一份样式。
class StatMetric extends StatelessWidget {
  const StatMetric({
    super.key,
    required this.label,
    required this.value,
    this.accent = false,
    this.width,
    this.dense = false,
  });

  final String label;
  final String value;

  /// 是否用主题主色强调（如今日已挑战的最佳成绩）。
  final bool accent;

  /// 固定宽度；为空时按内容自适应。
  final double? width;

  /// 紧凑模式：数值用更小的字号，用于成就页这类密集列表。
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final valueStyle = dense
        ? theme.textTheme.titleSmall
        : theme.textTheme.titleMedium;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: valueStyle?.copyWith(
              fontWeight: FontWeight.bold,
              color: accent ? colors.primary : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
