import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_snake/models/game_mode.dart';
import 'package:flutter_snake/pages/settings_page.dart';
import 'package:flutter_snake/providers/game_provider.dart';
import 'package:flutter_snake/providers/settings_provider.dart';

import 'fakes/fake_storage.dart';

Widget _buildApp(FakeStorageService storage, GameProvider game) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
      ChangeNotifierProvider<GameProvider>.value(value: game),
    ],
    child: const MaterialApp(home: SettingsPage()),
  );
}

/// 滚动到指定文案。
Future<void> _scrollTo(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.scrollUntilVisible(finder, 200);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// 滚动到指定文案并点击对应选项。
Future<void> _selectOption(WidgetTester tester, String label) async {
  await _scrollTo(tester, label);
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('设置页渲染所有分组', (WidgetTester tester) async {
    final storage = FakeStorageService.create();
    await tester.pumpWidget(
      _buildApp(storage, GameProvider(storage, audioEnabled: false)),
    );

    expect(find.text('外观'), findsOneWidget);
    expect(find.text('棋盘大小'), findsOneWidget);
    for (final label in ['游戏速度', '玩法模式', '关卡', '皮肤', '关于']) {
      await _scrollTo(tester, label);
      expect(find.text(label), findsOneWidget, reason: '$label 分组应可见');
    }
  });

  testWidgets('选择棋盘大小同步设置与当前对局', (WidgetTester tester) async {
    final storage = FakeStorageService.create();
    final game = GameProvider(storage, audioEnabled: false);
    await tester.pumpWidget(_buildApp(storage, game));

    final settings = tester
        .element(find.byType(SettingsPage))
        .read<SettingsProvider>();

    await _selectOption(tester, '小 (15×15)');

    expect(settings.boardSize, 15);
    expect(storage.boardSize, 15);
    expect(game.state.boardWidth, 15);
    expect(game.state.boardHeight, 15);
  });

  testWidgets('切换速度会更新对局速度', (WidgetTester tester) async {
    final storage = FakeStorageService.create();
    final game = GameProvider(storage, audioEnabled: false);
    await tester.pumpWidget(_buildApp(storage, game));

    final settings = tester
        .element(find.byType(SettingsPage))
        .read<SettingsProvider>();

    await _selectOption(tester, '快速');

    expect(settings.speed, 100);
    expect(storage.speed, 100);
    expect(game.state.speedMs, 100);
  });

  testWidgets('切换玩法模式写回存储并在下一局生效', (WidgetTester tester) async {
    final storage = FakeStorageService.create();
    final game = GameProvider(storage, audioEnabled: false);
    await tester.pumpWidget(_buildApp(storage, game));

    final settings = tester
        .element(find.byType(SettingsPage))
        .read<SettingsProvider>();

    await _selectOption(tester, '穿墙');

    expect(settings.mode, GameMode.wrap);
    expect(storage.mode, GameMode.wrap);
    expect(game.mode, GameMode.wrap);
  });
}
