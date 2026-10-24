import 'package:flutter/material.dart';

import '../models/level.dart';

/// 关卡在设置页/主页上的图标。
IconData levelIcon(LevelType level) {
  switch (level) {
    case LevelType.open:
      return Icons.grid_on;
    case LevelType.border:
      return Icons.crop_square;
    case LevelType.pillars:
      return Icons.view_module;
    case LevelType.cross:
      return Icons.add;
    case LevelType.maze:
      return Icons.account_tree_outlined;
    case LevelType.portals:
      return Icons.donut_large;
  }
}
