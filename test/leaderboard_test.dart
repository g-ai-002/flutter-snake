import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/services/leaderboard_service.dart';

void main() {
  group('LeaderboardEntry', () {
    test('toJson and fromJson roundtrip', () {
      final entry = LeaderboardEntry(score: 100, date: DateTime(2026, 6, 21, 12, 0));
      final json = entry.toJson();
      final restored = LeaderboardEntry.fromJson(json);
      expect(restored.score, 100);
      expect(restored.date, DateTime(2026, 6, 21, 12, 0));
    });

    test('toJson 包含 score 和 date', () {
      final entry = LeaderboardEntry(score: 50, date: DateTime(2026, 1, 1));
      final json = entry.toJson();
      expect(json['score'], 50);
      expect(json['date'], isA<String>());
    });

    test('fromJson 正确解析', () {
      final json = {'score': 200, 'date': '2026-06-21T12:00:00.000'};
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.score, 200);
      expect(entry.date.year, 2026);
    });

    test('零分条目', () {
      final entry = LeaderboardEntry(score: 0, date: DateTime(2026, 6, 21));
      expect(entry.score, 0);
    });
  });
}
