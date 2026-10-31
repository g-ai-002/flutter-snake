import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_snake/pages/home_page.dart';
import 'package:flutter_snake/providers/game_provider.dart';
import 'package:flutter_snake/providers/settings_provider.dart';

import 'fakes/fake_storage.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('主页展示每日挑战入口与数据入口', (WidgetTester tester) async {
    final storage = FakeStorageService.create();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
          ChangeNotifierProvider(
            create: (_) => GameProvider(storage, audioEnabled: false),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );

    expect(find.textContaining('每日挑战'), findsOneWidget);
    expect(find.text('今日尚未挑战'), findsOneWidget);
    expect(find.text('数据'), findsOneWidget);
    expect(find.text('开始游戏'), findsOneWidget);
  });
}
