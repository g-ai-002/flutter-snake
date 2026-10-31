import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_snake/models/daily_challenge.dart';
import 'package:flutter_snake/pages/daily_calendar_page.dart';
import 'package:flutter_snake/services/daily_service.dart';

Widget _buildApp() => const MaterialApp(home: DailyCalendarPage());

/// 日历整月约 6 行，默认 800×600 测试窗口放不下，改用更高画布避免滚动干扰。
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    DailyService.instance.resetForTest();
  });

  testWidgets('日历展示本月概览与已挑战成绩', (WidgetTester tester) async {
    _useTallScreen(tester);
    final now = DateTime.now();
    DailyService.instance.record(DailyChallenge.keyFor(now), 88);

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('每日挑战日历'), findsOneWidget);
    expect(find.text('${now.year}年${now.month}月'), findsOneWidget);
    expect(find.text('完成天数'), findsOneWidget);
    expect(find.text('本月最佳'), findsOneWidget);
    expect(find.text('88'), findsWidgets);
    expect(
      find.byKey(ValueKey('day-${DailyChallenge.keyFor(now)}')),
      findsOneWidget,
    );
  });

  testWidgets('点击日期查看当日排期与成绩', (WidgetTester tester) async {
    _useTallScreen(tester);
    final now = DateTime.now();
    final todayKey = DailyChallenge.keyFor(now);
    DailyService.instance.record(todayKey, 66);

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    final cell = find.byKey(ValueKey('day-$todayKey'));
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pumpAndSettle();

    final challenge = DailyChallenge.forDate(now);
    expect(find.textContaining(challenge.weekdayLabel), findsOneWidget);
    expect(find.text(challenge.subtitle), findsOneWidget);
    expect(find.text('最佳成绩 66 分'), findsOneWidget);
  });

  testWidgets('未挑战日期给出空状态提示', (WidgetTester tester) async {
    _useTallScreen(tester);
    final now = DateTime.now();
    final day = now.day == 1 ? 2 : 1;
    final key = DailyChallenge.keyFor(DateTime(now.year, now.month, day));

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    final cell = find.byKey(ValueKey('day-$key'));
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pumpAndSettle();

    expect(find.text('当日未挑战'), findsOneWidget);
  });

  testWidgets('可回看上个月且不能翻到未来', (WidgetTester tester) async {
    _useTallScreen(tester);
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1);
    DailyService.instance.record(DailyChallenge.keyFor(previous), 42);

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('上个月'));
    await tester.pumpAndSettle();

    expect(find.text('${previous.year}年${previous.month}月'), findsOneWidget);
    expect(find.text('42'), findsWidgets);
    expect(find.text('本月'), findsOneWidget);

    await tester.tap(find.text('本月'));
    await tester.pumpAndSettle();
    expect(find.text('${now.year}年${now.month}月'), findsOneWidget);

    final next = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('下个月'),
        matching: find.byType(IconButton),
      ),
    );
    expect(next.onPressed, isNull);
  });
}
