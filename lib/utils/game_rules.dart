/// 与玩法模式、连击相关的规则常量。
class GameRules {
  GameRules._();

  /// 每吃到一个普通食物的基础得分。
  static const int baseFoodScore = 10;

  /// 连击窗口（秒）：窗口内再次吃到食物则连击 +1。
  static const double comboWindowSeconds = 2.5;

  /// 连击倍率上限，避免分数失控。
  static const int maxComboMultiplier = 5;

  /// 限时挑战的总时长与加时规则。
  static const int timedLimitSeconds = 60;
  static const int timedBonusSeconds = 2;
  static const int timedMaxSeconds = 120;
}
