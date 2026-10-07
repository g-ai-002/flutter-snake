import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/game_board.dart';
import '../widgets/gesture_control.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().start();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final game = context.read<GameProvider>();
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      game.changeDirection(Direction.up);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      game.changeDirection(Direction.down);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      game.changeDirection(Direction.left);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      game.changeDirection(Direction.right);
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      game.togglePause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final game = context.watch<GameProvider>();
    final state = game.state;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('得分: ${state.score}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (state.status == GameStatus.playing || state.status == GameStatus.paused)
              IconButton(
                icon: Icon(game.isPaused ? Icons.play_arrow : Icons.pause),
                tooltip: game.isPaused ? '继续' : '暂停',
                onPressed: () => game.togglePause(),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // 分数和最高分
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '最高分: ${state.highScore}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (state.status == GameStatus.over)
                      Text(
                        '游戏结束',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 游戏棋盘（整块区域同时作为手势控制层）
              Expanded(
                child: GestureControl(
                  onDirection: (dir) => game.changeDirection(dir),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: state.boardWidth / state.boardHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GameBoard(
                            state: state,
                            snakeColor: colorScheme.primary,
                            foodColor: colorScheme.error,
                            gridColor: colorScheme.outline
                                .withValues(alpha: 0.3),
                            backgroundColor: colorScheme.surface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 操作提示
              if (state.status == GameStatus.playing || state.status == GameStatus.paused)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    defaultTargetPlatform == TargetPlatform.windows
                        ? '方向键 / 点击或滑动棋盘控制方向'
                        : '点击或滑动棋盘控制方向',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              if (state.status == GameStatus.over || state.status == GameStatus.idle)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () => game.start(),
                    icon: const Icon(Icons.replay),
                    label: const Text('重新开始'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(180, 48),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
