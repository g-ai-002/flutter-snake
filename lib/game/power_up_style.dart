import 'package:flutter/material.dart';

import '../models/power_up.dart';

/// 各类道具的统一配色。
Color powerUpColor(PowerUpType type) {
  switch (type) {
    case PowerUpType.speedUp:
      return const Color(0xFFFFA726);
    case PowerUpType.slowDown:
      return const Color(0xFF42A5F5);
    case PowerUpType.shield:
      return const Color(0xFF26C6DA);
    case PowerUpType.magnet:
      return const Color(0xFFAB47BC);
    case PowerUpType.doubleScore:
      return const Color(0xFFFFD54F);
  }
}

/// 道具在 HUD 上的图标。
IconData powerUpIcon(PowerUpType type) {
  switch (type) {
    case PowerUpType.speedUp:
      return Icons.speed;
    case PowerUpType.slowDown:
      return Icons.slow_motion_video;
    case PowerUpType.shield:
      return Icons.shield_outlined;
    case PowerUpType.magnet:
      return Icons.attractions;
    case PowerUpType.doubleScore:
      return Icons.stars;
  }
}
