import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/power_up_style.dart';
import '../../models/game_mode.dart';
import '../../models/game_state.dart';
import '../../models/level.dart';
import '../../models/power_up.dart';
import '../../providers/game_provider.dart';
import '../../utils/game_hints.dart';

/// 悬浮在 Flame 画布之上的 HUD。
///
/// 负责棋盘槽位、道具效果、状态信息与操作提示；不接收点击的区域放行给
/// Flame 的手势层，保证画布任意位置都能转向。
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.pageKey,
    required this.canvasSize,
    required this.boardRect,
    required this.landscape,
    required this.showHint,
    required this.onBoardRect,
  });

  /// 整个游戏页的 Key，用于把棋盘槽位换算成页面坐标。
  final GlobalKey pageKey;
  final Size canvasSize;
  final Rect boardRect;
  final bool landscape;
  final bool showHint;
  final ValueChanged<Rect> onBoardRect;

  @override
  Widget build(BuildContext context) {
    final left = boardRect.left;
    final top = boardRect.top;
    final side = boardRect.width;

    return Stack(
      children: [
        Positioned.fromRect(
          rect: boardRect,
          child: BoardSlot(pageKey: pageKey, onRect: onBoardRect),
        ),
        // 道具效果贴住棋盘上沿。
        Positioned(
          top: top + 8,
          left: left + 8,
          width: math.max(0, side - 16),
          child: const IgnorePointer(child: _EffectsBar()),
        ),
        if (!landscape) ...[
          Positioned(
            top: math.max(4, top - 40),
            left: 16,
            right: 16,
            child: const IgnorePointer(child: _StatusLine()),
          ),
          Positioned(
            top: top + side + 12,
            left: 16,
            right: 16,
            child: _HintArea(showHint: showHint),
          ),
        ] else ...[
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            width: math.max(0, left - 24),
            child: const Align(
              alignment: Alignment.centerRight,
              child: IgnorePointer(child: _StatusLine(vertical: true)),
            ),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            width: math.max(0, canvasSize.width - left - side - 24),
            child: Center(child: _HintArea(showHint: showHint)),
          ),
        ],
      ],
    );
  }
}

/// 只用于占位的棋盘槽位：把自身在游戏页中的矩形回报给 Flame 相机。
class BoardSlot extends StatefulWidget {
  const BoardSlot({super.key, required this.pageKey, required this.onRect});

  final GlobalKey pageKey;
  final ValueChanged<Rect> onRect;

  @override
  State<BoardSlot> createState() => _BoardSlotState();
}

class _BoardSlotState extends State<BoardSlot> {
  final GlobalKey _slotKey = GlobalKey();
  Rect? _lastRect;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportRect());
    return SizedBox.expand(key: _slotKey);
  }

  void _reportRect() {
    if (!mounted) return;
    final pageBox = widget.pageKey.currentContext?.findRenderObject();
    final slotBox = _slotKey.currentContext?.findRenderObject();
    if (pageBox is! RenderBox || slotBox is! RenderBox) return;
    if (!pageBox.hasSize || !slotBox.hasSize || slotBox.size.isEmpty) return;

    final rect =
        slotBox.localToGlobal(Offset.zero, ancestor: pageBox) & slotBox.size;
    if (rect == _lastRect) return;
    _lastRect = rect;
    widget.onRect(rect);
  }
}

/// HUD 需要展示的字段快照，字段值相等时 HUD 不重建。
typedef _StatusSnapshot = ({
  int highScore,
  String mode,
  String level,
  int? remainingSeconds,
  int combo,
  GameStatus status,
  GameOverReason reason,
});

/// 最高分、关卡与结束状态。
class _StatusLine extends StatelessWidget {
  const _StatusLine({this.vertical = false});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final snapshot = context.select<GameProvider, _StatusSnapshot>((game) {
      final state = game.state;
      return (
        highScore: state.highScore,
        mode: game.mode.label,
        level: game.level.label,
        remainingSeconds: game.remainingSeconds?.ceil(),
        combo: game.combo,
        status: state.status,
        reason: state.overReason,
      );
    });
    final colorScheme = Theme.of(context).colorScheme;
    final remaining = snapshot.remainingSeconds;
    final items = <Widget>[
      Text(
        '最高分: ${snapshot.highScore}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      Text(
        '模式: ${snapshot.mode}',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      Text(
        '关卡: ${snapshot.level}',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      if (remaining != null)
        Text(
          '剩余: ${remaining}s',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: remaining <= 10 ? colorScheme.error : colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      if (snapshot.combo > 1)
        Text(
          '连击 x${snapshot.combo}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.tertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      if (snapshot.status == GameStatus.over)
        Text(
          snapshot.reason.label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colorScheme.error, fontWeight: FontWeight.w600),
        ),
    ];

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: item,
            ),
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: items,
    );
  }
}

/// 当前生效的道具倒计时。
class _EffectsBar extends StatelessWidget {
  const _EffectsBar();

  @override
  Widget build(BuildContext context) {
    // 用类型 + 整秒数做签名，秒数不变就不重建，避免每帧刷新文本。
    final signature = context.select<GameProvider, String>(
      (game) => game.activeEffects
          .map((effect) => '${effect.type.name}:${effect.remaining.ceil()}')
          .join('|'),
    );
    if (signature.isEmpty) {
      return const SizedBox.shrink();
    }
    final effects = context.read<GameProvider>().activeEffects.toList(
      growable: false,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: effects.map((effect) => _EffectChip(effect: effect)).toList(),
    );
  }
}

class _EffectChip extends StatelessWidget {
  const _EffectChip({required this.effect});

  final ActiveEffect effect;

  @override
  Widget build(BuildContext context) {
    final color = powerUpColor(effect.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(powerUpIcon(effect.type), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${effect.type.label} ${effect.remaining.ceil()}s',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 开局短暂展示玩法提示，未开局时提供重新开始按钮。
class _HintArea extends StatelessWidget {
  const _HintArea({required this.showHint});

  final bool showHint;

  @override
  Widget build(BuildContext context) {
    final status = context.select<GameProvider, GameStatus>(
      (game) => game.state.status,
    );

    if (status == GameStatus.playing && !showHint) {
      return const SizedBox.shrink();
    }
    if (status == GameStatus.playing || status == GameStatus.paused) {
      return SizedBox(
        height: 60,
        child: Center(
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                GameHints.inGame,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (status == GameStatus.idle) {
      return ElevatedButton.icon(
        onPressed: context.read<GameProvider>().start,
        icon: const Icon(Icons.replay),
        label: const Text('重新开始'),
        style: ElevatedButton.styleFrom(minimumSize: const Size(180, 44)),
      );
    }
    return const SizedBox.shrink();
  }
}
