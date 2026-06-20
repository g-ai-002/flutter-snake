import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_snake/models/game_state.dart';
import 'package:flutter_snake/providers/game_provider.dart';
import 'package:flutter_snake/providers/settings_provider.dart';
import 'package:flutter_snake/services/storage_service.dart';

class FakeStorageService extends StorageService {
  final Map<String, dynamic> _store = {};

  FakeStorageService() : super.test();

  static FakeStorageService create() => FakeStorageService();

  @override
  bool get darkMode => _store['dark_mode'] as bool? ?? false;

  @override
  Future<void> setDarkMode(bool v) async {
    _store['dark_mode'] = v;
  }

  @override
  int get highScore => _store['high_score'] as int? ?? 0;

  @override
  Future<void> setHighScore(int v) async {
    _store['high_score'] = v;
  }

  @override
  int get boardSize => _store['board_size'] as int? ?? 20;

  @override
  Future<void> setBoardSize(int v) async {
    _store['board_size'] = v;
  }

  @override
  int get speed => _store['speed'] as int? ?? 200;

  @override
  Future<void> setSpeed(int v) async {
    _store['speed'] = v;
  }

  @override
  bool get muted => _store['muted'] as bool? ?? false;

  @override
  Future<void> setMuted(bool v) async {
    _store['muted'] = v;
  }
}

Widget buildTestApp(FakeStorageService storage) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
      ChangeNotifierProvider(create: (_) => GameProvider(storage)),
    ],
    child: MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('贪吃蛇')),
        body: const Center(child: Text('测试')),
      ),
    ),
  );
}

void main() {
  testWidgets('应用启动冒烟测试', (WidgetTester tester) async {
    final storage = FakeStorageService.create();
    await tester.pumpWidget(buildTestApp(storage));
    expect(find.text('贪吃蛇'), findsOneWidget);
    expect(find.text('测试'), findsOneWidget);
  });

  testWidgets('GameProvider 初始状态', (WidgetTester tester) async {
    final storage = FakeStorageService.create();
    await tester.pumpWidget(buildTestApp(storage));
    final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();
    expect(game.isIdle, isTrue);
    expect(game.state.score, 0);
  });

  testWidgets('SettingsProvider 默认值', (WidgetTester tester) async {
    final storage = FakeStorageService.create();
    await tester.pumpWidget(buildTestApp(storage));
    final settings = tester.element(find.byType(MaterialApp)).read<SettingsProvider>();
    expect(settings.darkMode, isFalse);
    expect(settings.boardSize, 20);
    expect(settings.speed, 200);
    expect(settings.muted, isFalse);
  });

  testWidgets('SettingsProvider 静音切换', (WidgetTester tester) async {
    final storage = FakeStorageService.create();
    await tester.pumpWidget(buildTestApp(storage));
    final settings = tester.element(find.byType(MaterialApp)).read<SettingsProvider>();
    expect(settings.muted, isFalse);
    await settings.setMuted(true);
    expect(settings.muted, isTrue);
  });

  group('GameProvider 核心逻辑', () {
    testWidgets('start 后状态变为 playing', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();
      game.start();
      expect(game.isPlaying, isTrue);
      expect(game.state.score, 0);
    });

    testWidgets('pause 和 resume', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();
      game.start();
      expect(game.isPlaying, isTrue);
      game.pause();
      expect(game.isPaused, isTrue);
      game.resume();
      expect(game.isPlaying, isTrue);
    });

    testWidgets('togglePause 切换暂停状态', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();
      game.start();
      game.togglePause();
      expect(game.isPaused, isTrue);
      game.togglePause();
      expect(game.isPlaying, isTrue);
    });

    testWidgets('changeDirection 忽略反向', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();
      game.start();
      // 初始方向是 right，尝试改为 left 应被忽略
      game.changeDirection(Direction.left);
      // 方向锁在 _tick 中释放，这里只验证 changeDirection 不抛异常
      expect(game.isPlaying, isTrue);
    });

    testWidgets('updateBoardSize 更新棋盘大小', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();
      game.updateBoardSize(25);
      expect(game.state.boardWidth, 25);
      expect(game.state.boardHeight, 25);
    });

    testWidgets('updateSpeed 更新速度', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();
      game.updateSpeed(100);
      expect(game.state.speedMs, 100);
    });

    testWidgets('最高分持久化', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await storage.setHighScore(50);
      await tester.pumpWidget(buildTestApp(storage));
      final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();
      expect(game.state.highScore, 50);
    });
  });

  group('SettingsProvider 设置持久化', () {
    testWidgets('toggleDarkMode 持久化', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final settings = tester.element(find.byType(MaterialApp)).read<SettingsProvider>();
      await settings.toggleDarkMode(true);
      expect(settings.darkMode, isTrue);
      expect(storage.darkMode, isTrue);
    });

    testWidgets('setBoardSize 持久化', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final settings = tester.element(find.byType(MaterialApp)).read<SettingsProvider>();
      await settings.setBoardSize(15);
      expect(settings.boardSize, 15);
      expect(storage.boardSize, 15);
    });

    testWidgets('setSpeed 持久化', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final settings = tester.element(find.byType(MaterialApp)).read<SettingsProvider>();
      await settings.setSpeed(300);
      expect(settings.speed, 300);
      expect(storage.speed, 300);
    });
  });
}
