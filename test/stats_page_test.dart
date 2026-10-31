import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_snake/pages/stats_page.dart';
import 'package:flutter_snake/providers/game_provider.dart';

import 'fakes/fake_storage.dart';

Widget _buildApp(FakeStorageService storage) {
  return ChangeNotifierProvider(
    create: (_) => GameProvider(storage, audioEnabled: false),
    child: const MaterialApp(home: StatsPage()),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('数据统计页展示生涯、每日挑战与排行榜区块', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(FakeStorageService.create()));
    await tester.pumpAndSettle();

    expect(find.text('数据统计'), findsOneWidget);
    expect(find.text('生涯数据'), findsOneWidget);
    expect(find.text('每日挑战'), findsOneWidget);
    expect(find.text('日历'), findsOneWidget);
    expect(find.text('排行榜 Top 5'), findsOneWidget);
    expect(find.text('暂无记录，先玩一局吧'), findsOneWidget);
  });

  testWidgets('未挑战时展示提示文案', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(FakeStorageService.create()));
    await tester.pumpAndSettle();

    expect(find.text('未挑战'), findsOneWidget);
    expect(find.text('连续天数'), findsOneWidget);
    expect(find.text('挑战天数'), findsOneWidget);
  });

  testWidgets('分享战绩按钮复制生涯数据', (WidgetTester tester) async {
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

    await tester.pumpWidget(_buildApp(FakeStorageService.create()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('分享战绩'));
    await tester.pumpAndSettle();

    final setData = calls.firstWhere(
      (call) => call.method == 'Clipboard.setData',
    );
    expect((setData.arguments as Map)['text'], contains('贪吃蛇生涯战绩'));
    expect(find.text('战绩已复制到剪贴板'), findsOneWidget);
  });

  testWidgets('日历按钮进入每日挑战日历', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(FakeStorageService.create()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('日历'));
    await tester.pumpAndSettle();

    expect(find.text('每日挑战日历'), findsOneWidget);
    expect(find.text('本月概览'), findsOneWidget);
  });
}
