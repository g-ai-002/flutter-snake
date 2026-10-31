import 'package:flutter/material.dart';
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
}
