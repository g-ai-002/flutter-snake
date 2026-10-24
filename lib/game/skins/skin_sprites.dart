import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../models/skin.dart';
import '../../services/log_service.dart';

/// 一套皮肤对应的已加载贴图。
class SkinSprites {
  const SkinSprites({
    this.head,
    this.body,
    this.tail,
    this.foodFrames = const <ui.Image>[],
  });

  static const SkinSprites empty = SkinSprites();

  final ui.Image? head;
  final ui.Image? body;
  final ui.Image? tail;
  final List<ui.Image> foodFrames;

  /// 蛇身贴图齐全才启用贴图渲染，否则回退到矢量绘制。
  bool get isReady => head != null && body != null;

  /// 按皮肤声明的资源路径加载贴图，单个文件失败时记录日志并跳过。
  static Future<SkinSprites> load(
    FlameGame<World> game,
    SnakeSkin skin,
  ) async {
    final assets = skin.spriteAssets;
    if (assets.isEmpty) return SkinSprites.empty;

    final dir = skin.spriteDir;
    final head = await _tryLoad(game, 'sprites/$dir/snake_head.png');
    final body = await _tryLoad(game, 'sprites/$dir/snake_body.png');
    final tail = await _tryLoad(game, 'sprites/$dir/snake_tail.png');
    final frames = <ui.Image>[];
    for (var i = 0; i < skin.foodFrameCount; i++) {
      final frame = await _tryLoad(
        game,
        'sprites/$dir/food_$i.png',
      );
      if (frame != null) frames.add(frame);
    }

    return SkinSprites(
      head: head,
      body: body,
      tail: tail,
      foodFrames: frames,
    );
  }

  static Future<ui.Image?> _tryLoad(
    FlameGame<World> game,
    String path,
  ) async {
    try {
      return await game.images.load(path);
    } catch (e) {
      LogService.warning('皮肤贴图加载失败: $path ($e)');
      return null;
    }
  }
}
