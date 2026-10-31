import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_snake/game/overlays/game_over_overlay.dart';
import 'package:flutter_snake/providers/game_provider.dart';

import 'fakes/fake_storage.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('结算遮罩可复制本局战绩', (WidgetTester tester) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final provider = GameProvider(
      FakeStorageService.create(),
      audioEnabled: false,
    );
    // 直接向右撞墙，确保遮罩展示真实结算数据。
    provider.start();
    for (var i = 0; i < 30 && !provider.isOver; i++) {
      provider.tick();
    }
    expect(provider.isOver, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameOverOverlay(provider: provider, onExit: () {}),
        ),
      ),
    );

    expect(find.text('分享战绩'), findsOneWidget);
    await tester.tap(find.text('分享战绩'));
    await tester.pumpAndSettle();

    final setData = calls.firstWhere(
      (call) => call.method == 'Clipboard.setData',
    );
    final text = (setData.arguments as Map)['text'] as String;
    expect(text, contains('贪吃蛇 · 经典'));
    expect(text, contains('得分 ${provider.state.score}'));
    expect(text, contains('最高分 ${provider.state.highScore}'));
    expect(find.text('战绩已复制到剪贴板'), findsOneWidget);
  });
}
