/// 多类型食物/道具的效果类型。
enum PowerUpType {
  speedUp,
  slowDown,
  shield,
  magnet,
  doubleScore,
}

extension PowerUpTypeInfo on PowerUpType {
  /// 界面展示名称。
  String get label {
    switch (this) {
      case PowerUpType.speedUp:
        return '加速';
      case PowerUpType.slowDown:
        return '减速';
      case PowerUpType.shield:
        return '护盾';
      case PowerUpType.magnet:
        return '磁铁';
      case PowerUpType.doubleScore:
        return '双倍分';
    }
  }

  /// 飘字用短标签，避免依赖中文字体回退。
  String get shortLabel {
    switch (this) {
      case PowerUpType.speedUp:
        return 'SPEED';
      case PowerUpType.slowDown:
        return 'SLOW';
      case PowerUpType.shield:
        return 'SHIELD';
      case PowerUpType.magnet:
        return 'MAGNET';
      case PowerUpType.doubleScore:
        return 'x2';
    }
  }

  /// 效果持续时间（秒）。
  double get durationSeconds {
    switch (this) {
      case PowerUpType.speedUp:
        return 6;
      case PowerUpType.slowDown:
        return 5;
      case PowerUpType.shield:
        return 10;
      case PowerUpType.magnet:
        return 6;
      case PowerUpType.doubleScore:
        return 8;
    }
  }
}

/// 当前生效中的道具效果。
class ActiveEffect {
  ActiveEffect({required this.type, required this.total})
      : remaining = total;

  final PowerUpType type;
  final double total;
  double remaining;
}
