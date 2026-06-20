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
  });
}
