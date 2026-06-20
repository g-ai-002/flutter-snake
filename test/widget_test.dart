import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_snake/providers/game_provider.dart';
import 'package:flutter_snake/providers/settings_provider.dart';
import 'package:flutter_snake/services/storage_service.dart';

class FakeStorageService extends StorageService {
  final Map<String, dynamic> _store = {};

  FakeStorageService() : super.test();

  static Future<FakeStorageService> create() async {
    final s = FakeStorageService();
    return s;
  }

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
    final storage = await FakeStorageService.create();
    await tester.pumpWidget(buildTestApp(storage));
    expect(find.text('贪吃蛇'), findsOneWidget);
    expect(find.text('测试'), findsOneWidget);
  });

  testWidgets('GameProvider 初始状态', (WidgetTester tester) async {
    final storage = await FakeStorageService.create();
    await tester.pumpWidget(buildTestApp(storage));
    final game = tester.element(find.byType(MaterialApp)).read<GameProvider>();
    expect(game.isIdle, isTrue);
    expect(game.state.score, 0);
  });

  testWidgets('SettingsProvider 默认值', (WidgetTester tester) async {
    final storage = await FakeStorageService.create();
    await tester.pumpWidget(buildTestApp(storage));
    final settings = tester.element(find.byType(MaterialApp)).read<SettingsProvider>();
    expect(settings.darkMode, isFalse);
    expect(settings.boardSize, 20);
    expect(settings.speed, 200);
  });
}
