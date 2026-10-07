import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/models/game_state.dart';
import 'package:flutter_snake/widgets/gesture_control.dart';

Widget _wrap(void Function(Direction direction) onDirection) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: GestureControl(
            onDirection: onDirection,
            child: const ColoredBox(color: Color(0xFF000000)),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('GestureControl 方向推断', () {
    test('由位移取占优轴推断方向', () {
      expect(
        GestureControl.directionFromDelta(const Offset(30, 5)),
        Direction.right,
      );
      expect(
        GestureControl.directionFromDelta(const Offset(-30, 5)),
        Direction.left,
      );
      expect(
        GestureControl.directionFromDelta(const Offset(5, 30)),
        Direction.down,
      );
      expect(
        GestureControl.directionFromDelta(const Offset(5, -30)),
        Direction.up,
      );
    });

    test('由点击位置相对中心推断方向', () {
      const size = Size(200, 200);
      expect(
        GestureControl.directionFromTap(const Offset(180, 100), size),
        Direction.right,
      );
      expect(
        GestureControl.directionFromTap(const Offset(20, 100), size),
        Direction.left,
      );
      expect(
        GestureControl.directionFromTap(const Offset(100, 180), size),
        Direction.down,
      );
      expect(
        GestureControl.directionFromTap(const Offset(100, 20), size),
        Direction.up,
      );
    });

    test('中心死区不产生方向', () {
      const size = Size(200, 200);
      expect(
        GestureControl.directionFromTap(const Offset(100, 100), size),
        isNull,
      );
      expect(
        GestureControl.directionFromTap(const Offset(101, 102), size),
        isNull,
      );
    });
  });

  group('GestureControl 手势区域', () {
    testWidgets('点击棋盘按位置触发方向', (WidgetTester tester) async {
      final received = <Direction>[];
      await tester.pumpWidget(_wrap(received.add));

      final center = tester.getCenter(find.byType(GestureControl));
      await tester.tapAt(center + const Offset(70, 0));
      await tester.pump();

      expect(received, [Direction.right]);
    });

    testWidgets('在棋盘上滑动触发方向', (WidgetTester tester) async {
      final received = <Direction>[];
      await tester.pumpWidget(_wrap(received.add));

      final center = tester.getCenter(find.byType(GestureControl));
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pump();

      expect(received, [Direction.down]);
    });

    testWidgets('点击中心死区不触发方向', (WidgetTester tester) async {
      final received = <Direction>[];
      await tester.pumpWidget(_wrap(received.add));

      await tester.tapAt(tester.getCenter(find.byType(GestureControl)));
      await tester.pump();

      expect(received, isEmpty);
    });
  });
}
