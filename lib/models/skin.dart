/// 蛇与食物的外观皮肤。
enum SnakeSkin { classic, pixel, neon, candy }

extension SnakeSkinInfo on SnakeSkin {
  String get label {
    switch (this) {
      case SnakeSkin.classic:
        return '经典';
      case SnakeSkin.pixel:
        return '像素';
      case SnakeSkin.neon:
        return '霓虹';
      case SnakeSkin.candy:
        return '糖果';
    }
  }

  String get description {
    switch (this) {
      case SnakeSkin.classic:
        return '跟随主题色的简洁矢量造型';
      case SnakeSkin.pixel:
        return '16×16 像素贴图，食物逐帧动画';
      case SnakeSkin.neon:
        return '发光描边，夜光配色';
      case SnakeSkin.candy:
        return '粉彩身体与糖果色食物';
    }
  }

  /// 是否使用 assets/images/sprites 下的贴图。
  bool get usesSprites => this == SnakeSkin.pixel || this == SnakeSkin.candy;

  /// 贴图子目录名；矢量皮肤返回 null。
  String? get spriteDir {
    switch (this) {
      case SnakeSkin.pixel:
        return 'pixel';
      case SnakeSkin.candy:
        return 'candy';
      case SnakeSkin.classic:
      case SnakeSkin.neon:
        return null;
    }
  }

  int get foodFrameCount => usesSprites ? 4 : 1;

  /// 食物贴图动画帧率。
  double get foodAnimationFps => 8;

  /// 该皮肤需要的全部贴图资源路径。
  ///
  /// 路径相对 Flame `Images` 的默认前缀（`assets/images/`），
  /// 例如 `sprites/pixel/snake_head.png` 对应
  /// `assets/images/sprites/pixel/snake_head.png`。
  List<String> get spriteAssets {
    final dir = spriteDir;
    if (dir == null) return const <String>[];
    return <String>[
      'sprites/$dir/snake_head.png',
      'sprites/$dir/snake_body.png',
      'sprites/$dir/snake_tail.png',
      for (var i = 0; i < foodFrameCount; i++) 'sprites/$dir/food_$i.png',
    ];
  }
}
