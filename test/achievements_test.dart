import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/models/achievement.dart';
import 'package:flutter_snake/models/game_mode.dart';
import 'package:flutter_snake/models/player_stats.dart';

void main() {
  group('PlayerStats', () {
    test('merge 累计局数、食物与最佳成绩', () {
      final stats = PlayerStats.empty.merge(
        const GameRun(
          mode: GameMode.classic,
          score: 120,
          bestCombo: 4,
          length: 12,
          food: 9,
        ),
      );

      expect(stats.gamesPlayed, 1);
      expect(stats.totalFood, 9);
      expect(stats.bestScore, 120);
      expect(stats.bestCombo, 4);
      expect(stats.bestLength, 12);
      expect(stats.modesPlayed, {GameMode.classic});
      expect(stats.bestTimedScore, 0);
    });

    test('限时最佳只统计限时模式', () {
      final stats = PlayerStats.empty
          .merge(
            const GameRun(
              mode: GameMode.timed,
              score: 200,
              bestCombo: 2,
              length: 8,
              food: 20,
            ),
          )
          .merge(
            const GameRun(
              mode: GameMode.classic,
              score: 500,
              bestCombo: 3,
              length: 30,
              food: 40,
            ),
          );

      expect(stats.bestTimedScore, 200);
      expect(stats.bestScore, 500);
      expect(stats.gamesPlayed, 2);
      expect(stats.modesPlayed, {GameMode.timed, GameMode.classic});
    });

    test('JSON 往返保留模式集合', () {
      const stats = PlayerStats(
        gamesPlayed: 3,
        totalFood: 15,
        bestScore: 90,
        bestCombo: 3,
        bestLength: 11,
        bestTimedScore: 70,
        modesPlayed: {GameMode.wrap, GameMode.timed},
      );

      final restored = PlayerStats.fromJson(stats.toJson());
      expect(restored.gamesPlayed, 3);
      expect(restored.totalFood, 15);
      expect(restored.bestScore, 90);
      expect(restored.bestCombo, 3);
      expect(restored.bestLength, 11);
      expect(restored.bestTimedScore, 70);
      expect(restored.modesPlayed, {GameMode.wrap, GameMode.timed});
    });

    test('JSON 缺字段与未知模式回退到默认值', () {
      final stats = PlayerStats.fromJson(<String, dynamic>{
        'gamesPlayed': 2,
        'modesPlayed': ['wrap', 'unknown'],
      });
      expect(stats.gamesPlayed, 2);
      expect(stats.bestCombo, 1);
      expect(stats.modesPlayed, {GameMode.wrap});
    });
  });

  group('AchievementCatalog', () {
    test('进度按统计项取值', () {
      const stats = PlayerStats(
        gamesPlayed: 12,
        totalFood: 30,
        bestScore: 320,
        bestCombo: 5,
        bestLength: 18,
        bestTimedScore: 120,
        modesPlayed: {GameMode.classic, GameMode.timed},
      );

      expect(AchievementId.games10.progress(stats), 12);
      expect(AchievementId.score300.isUnlocked(stats), isTrue);
      expect(AchievementId.score500.isUnlocked(stats), isFalse);
      expect(AchievementId.combo5.isUnlocked(stats), isTrue);
      expect(AchievementId.length20.isUnlocked(stats), isFalse);
      expect(AchievementId.allModes.progress(stats), 2);
      expect(AchievementId.timed300.progress(stats), 120);
      expect(AchievementId.food50.progress(stats), 30);
    });

    test('进度比例与文本封顶', () {
      const stats = PlayerStats(gamesPlayed: 25);
      expect(AchievementId.games10.progressRatio(stats), 1.0);
      expect(AchievementId.games50.progressRatio(stats), 0.5);
      expect(AchievementId.games50.progressLabel(stats), '25/50');
      expect(AchievementId.games10.progressLabel(stats), '10/10');
    });

    test('unlockedCount 统计已解锁数量', () {
      const stats = PlayerStats(gamesPlayed: 1, bestScore: 120, bestCombo: 3);
      expect(AchievementCatalog.unlockedCount(stats), 3);
      expect(AchievementCatalog.all.length, 15);
    });

    test('newlyUnlocked 只返回本次新增', () {
      const before = PlayerStats(gamesPlayed: 1, bestScore: 10);
      const after = PlayerStats(gamesPlayed: 2, bestScore: 120, bestCombo: 3);

      final unlocked = AchievementCatalog.newlyUnlocked(before, after);
      expect(unlocked, contains(AchievementId.score100));
      expect(unlocked, contains(AchievementId.combo3));
      expect(unlocked, isNot(contains(AchievementId.firstGame)));
    });
  });
}
