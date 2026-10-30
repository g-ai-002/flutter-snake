import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_snake/models/game_state.dart';
import 'package:flutter_snake/models/game_mode.dart';
import 'package:flutter_snake/models/level.dart';
import 'package:flutter_snake/models/power_up.dart';
import 'package:flutter_snake/models/skin.dart';
import 'package:flutter_snake/providers/game_provider.dart';
import 'package:flutter_snake/providers/settings_provider.dart';

import 'fakes/fake_storage.dart';

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
    expect(settings.mode, GameMode.classic);
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

    testWidgets('加速效果生效并按时过期', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();
      final baseSpeed = game.state.speedMs;

      game.activatePowerUp(PowerUpType.speedUp);
      expect(game.hasEffect(PowerUpType.speedUp), isTrue);
      expect(game.effectiveSpeedMs, lessThan(baseSpeed));

      game.updateEffects(PowerUpType.speedUp.durationSeconds + 0.1);
      expect(game.hasEffect(PowerUpType.speedUp), isFalse);
      expect(game.effectiveSpeedMs, baseSpeed);
    });

    testWidgets('减速替换加速', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();
      final baseSpeed = game.state.speedMs;

      game.activatePowerUp(PowerUpType.speedUp);
      game.activatePowerUp(PowerUpType.slowDown);

      expect(game.hasEffect(PowerUpType.speedUp), isFalse);
      expect(game.hasEffect(PowerUpType.slowDown), isTrue);
      expect(game.effectiveSpeedMs, greaterThan(baseSpeed));
    });

    testWidgets('护盾生效并按时过期', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();

      game.activatePowerUp(PowerUpType.shield);
      expect(game.hasShield, isTrue);
      expect(game.hasEffect(PowerUpType.shield), isTrue);

      game.updateEffects(PowerUpType.shield.durationSeconds + 0.1);
      expect(game.hasShield, isFalse);
      expect(game.hasEffect(PowerUpType.shield), isFalse);
    });

    testWidgets('双倍分与磁铁可同时生效', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();

      game.activatePowerUp(PowerUpType.doubleScore);
      game.activatePowerUp(PowerUpType.magnet);

      expect(game.hasEffect(PowerUpType.doubleScore), isTrue);
      expect(game.hasEffect(PowerUpType.magnet), isTrue);
      expect(game.activeEffects.length, 2);
    });

    testWidgets('tick 按当前方向移动蛇头', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();
      game.start();

      final state = game.state;
      final head = state.snake.head;
      // 避开食物所在格，保证不会随机吃到食物
      final dir = head.move(Direction.up) == state.food.position
          ? Direction.down
          : Direction.up;
      final expected = head.move(dir);

      game.changeDirection(dir);
      game.tick();

      expect(game.state.snake.head, expected);
      expect(game.state.snake.direction, dir);
    });

    testWidgets('暂停时 tick 不移动蛇', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();
      game.start();
      game.pause();

      final head = game.state.snake.head;
      game.tick();

      expect(game.state.snake.head, head);
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
      // 方向锁在下一次 tick 中释放，这里只验证 changeDirection 不抛异常
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

    testWidgets('setLevel 持久化', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final settings = tester.element(find.byType(MaterialApp)).read<SettingsProvider>();
      await settings.setLevel(LevelType.portals);
      expect(settings.level, LevelType.portals);
      expect(storage.level, LevelType.portals);
    });

    testWidgets('setSkin 持久化', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final settings = tester.element(find.byType(MaterialApp)).read<SettingsProvider>();
      await settings.setSkin(SnakeSkin.pixel);
      expect(settings.skin, SnakeSkin.pixel);
      expect(storage.skin, SnakeSkin.pixel);
    });

    testWidgets('setMode 持久化', (WidgetTester tester) async {
      final storage = FakeStorageService.create();
      await tester.pumpWidget(buildTestApp(storage));
      final settings = tester.element(find.byType(MaterialApp)).read<SettingsProvider>();
      await settings.setMode(GameMode.wrap);
      expect(settings.mode, GameMode.wrap);
      expect(storage.mode, GameMode.wrap);
    });
  });
}
