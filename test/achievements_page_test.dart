import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_snake/models/achievement.dart';
import 'package:flutter_snake/pages/achievements_page.dart';
import 'package:flutter_snake/providers/game_provider.dart';
import 'package:flutter_snake/services/stats_service.dart';

import 'fakes/fake_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    StatsService.instance.resetForTest();
  });

  testWidgets('成就页展示解锁进度与统计指标', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) =>
            GameProvider(FakeStorageService.create(), audioEnabled: false),
        child: const MaterialApp(home: AchievementsPage()),
      ),
    );

    expect(
      find.text('已解锁 0 / ${AchievementCatalog.all.length}'),
      findsOneWidget,
    );
    expect(find.text('局数'), findsOneWidget);
    expect(find.text('最佳连击'), findsOneWidget);
    expect(find.text(AchievementCatalog.all.first.title), findsOneWidget);
  });
}
