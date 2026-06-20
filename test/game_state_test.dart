import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/models/game_state.dart';

void main() {
  group('Point', () {
    test('move up', () {
      const p = Point(5, 5);
      expect(p.move(Direction.up), const Point(5, 4));
    });

    test('move down', () {
      const p = Point(5, 5);
      expect(p.move(Direction.down), const Point(5, 6));
    });

    test('move left', () {
      const p = Point(5, 5);
      expect(p.move(Direction.left), const Point(4, 5));
    });

    test('move right', () {
      const p = Point(5, 5);
      expect(p.move(Direction.right), const Point(6, 5));
    });

    test('equality', () {
      expect(const Point(3, 4), const Point(3, 4));
      expect(const Point(3, 4), isNot(const Point(4, 3)));
    });
  });

  group('Snake', () {
    test('head is last element', () {
      final snake = Snake(body: [const Point(0, 0), const Point(1, 0), const Point(2, 0)]);
      expect(snake.head, const Point(2, 0));
    });

    test('copyWith preserves unchanged fields', () {
      final snake = Snake(body: [const Point(0, 0)], direction: Direction.up);
      final copy = snake.copyWith();
      expect(copy.direction, Direction.up);
      expect(copy.body.length, 1);
    });
  });

  group('GameState', () {
    test('copyWith updates fields', () {
      final state = GameState(
        snake: Snake(body: [const Point(0, 0)]),
        food: const Food(Point(5, 5)),
      );
      final updated = state.copyWith(score: 10);
      expect(updated.score, 10);
      expect(updated.snake.body.length, 1);
    });
  });

  group('Direction', () {
    test('all directions are distinct', () {
      final dirs = Direction.values.toSet();
      expect(dirs.length, 4);
    });
  });
}
