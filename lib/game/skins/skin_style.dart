import 'package:flutter/material.dart';

import '../../models/skin.dart';

/// 皮肤对蛇身的配色覆盖；返回 null 表示沿用主题色。
Color? snakeSkinColor(SnakeSkin skin) {
  switch (skin) {
    case SnakeSkin.classic:
      return null;
    case SnakeSkin.pixel:
      return const Color(0xFF5FD068);
    case SnakeSkin.neon:
      return const Color(0xFF22D3EE);
    case SnakeSkin.candy:
      return const Color(0xFFFF8BC1);
  }
}

/// 皮肤对食物的配色覆盖；返回 null 表示沿用主题色。
Color? snakeSkinFoodColor(SnakeSkin skin) {
  switch (skin) {
    case SnakeSkin.classic:
      return null;
    case SnakeSkin.pixel:
      return const Color(0xFFE4572E);
    case SnakeSkin.neon:
      return const Color(0xFFF472B6);
    case SnakeSkin.candy:
      return const Color(0xFF5EEAD4);
  }
}

bool skinUsesNeonGlow(SnakeSkin skin) => skin == SnakeSkin.neon;

IconData skinIcon(SnakeSkin skin) {
  switch (skin) {
    case SnakeSkin.classic:
      return Icons.palette_outlined;
    case SnakeSkin.pixel:
      return Icons.grid_view;
    case SnakeSkin.neon:
      return Icons.auto_awesome;
    case SnakeSkin.candy:
      return Icons.cake_outlined;
  }
}
