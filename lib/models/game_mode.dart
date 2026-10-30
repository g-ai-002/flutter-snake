import '../utils/game_rules.dart';

/// 玩法模式：决定边界规则与单局结束条件。
enum GameMode { classic, wrap, timed }

extension GameModeInfo on GameMode {
  String get label {
    switch (this) {
      case GameMode.classic:
        return '经典';
      case GameMode.wrap:
        return '穿墙';
      case GameMode.timed:
        return '限时挑战';
    }
  }

  String get description {
    switch (this) {
      case GameMode.classic:
        return '撞墙或撞到自己即结束';
      case GameMode.wrap:
        return '越过边界从对侧出现';
      case GameMode.timed:
        return '${GameRules.timedLimitSeconds} 秒抢分，吃食物加时';
    }
  }

  /// 越界时是否从对侧穿出。
  bool get wrapsEdges => this == GameMode.wrap;

  /// 限时模式的剩余秒数；其它模式返回 null。
  double? get initialSeconds =>
      this == GameMode.timed ? GameRules.timedLimitSeconds.toDouble() : null;
}
