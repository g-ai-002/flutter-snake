import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/game/input/direction_input.dart';
import 'package:flutter_snake/models/game_state.dart';

void main() {
  group('方向推断', () {
    test('由位移取占优轴推断方向', () {
      expect(directionFromDelta(const Offset(30, 5)), Direction.right);
      expect(directionFromDelta(const Offset(-30, 5)), Direction.left);
      expect(directionFromDelta(const Offset(5, 30)), Direction.down);
      expect(directionFromDelta(const Offset(5, -30)), Direction.up);
    });

    test('由点击位置相对中心推断方向', () {
      const size = Size(200, 200);
      expect(
        directionFromTap(const Offset(180, 100), size),
        Direction.right,
      );
      expect(
        directionFromTap(const Offset(20, 100), size),
        Direction.left,
      );
      expect(
        directionFromTap(const Offset(100, 180), size),
        Direction.down,
      );
      expect(
        directionFromTap(const Offset(100, 20), size),
        Direction.up,
      );
    });

    test('中心死区不产生方向', () {
      const size = Size(200, 200);
      expect(directionFromTap(const Offset(100, 100), size), isNull);
      expect(directionFromTap(const Offset(101, 102), size), isNull);
    });
  });
}
