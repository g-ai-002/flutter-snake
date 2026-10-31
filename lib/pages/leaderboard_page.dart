import 'package:flutter/material.dart';

import '../services/leaderboard_service.dart';
import '../utils/formatters.dart';

/// 排行榜页：展示全部记录，支持一键清空。
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<LeaderboardEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await LeaderboardService.getEntries();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '加载失败，请重试';
      });
    }
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空排行榜'),
        content: const Text('确定要清空所有记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await LeaderboardService.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('排行榜'),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '清空',
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _EmptyState(
        icon: Icons.error_outline,
        title: _error!,
        color: Theme.of(context).colorScheme.error,
        action: OutlinedButton(onPressed: _load, child: const Text('重试')),
      );
    }
    if (_entries.isEmpty) {
      return _EmptyState(
        icon: Icons.emoji_events,
        title: '暂无记录',
        subtitle: '开始游戏来创造记录吧',
        color: Theme.of(context).colorScheme.outline,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return ListTile(
          leading: _RankBadge(rank: index + 1),
          title: Text(
            '${entry.score} 分',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            formatDateTime(entry.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }
}

/// 空态/错误态的统一版式。
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.color,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.bodyLarge),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  /// 前三名的奖牌配色：金、银、铜。
  static const List<Color> _medalColors = [
    Color(0xFFFFD700),
    Color(0xFFC0C0C0),
    Color(0xFFCD7F32),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (rank <= _medalColors.length) {
      return CircleAvatar(
        backgroundColor: _medalColors[rank - 1],
        radius: 20,
        child: Text(
          '$rank',
          style: TextStyle(
            color: rank == 2 ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    return CircleAvatar(
      backgroundColor: colorScheme.surfaceContainerHighest,
      radius: 20,
      child: Text(
        '$rank',
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
      ),
    );
  }
}
