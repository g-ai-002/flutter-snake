import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/game/skins/skin_style.dart';
import 'package:flutter_snake/models/skin.dart';

void main() {
  test('皮肤名称唯一', () {
    final labels = SnakeSkin.values.map((skin) => skin.label).toSet();
    expect(labels.length, SnakeSkin.values.length);
  });

  test('贴图皮肤声明完整的 7 个贴图资源', () {
    for (final skin in SnakeSkin.values) {
      if (skin.usesSprites) {
        expect(skin.spriteDir, isNotNull);
        expect(skin.foodFrameCount, 4);
        expect(skin.spriteAssets.length, 7);
        expect(
          skin.spriteAssets.every((path) => path.endsWith('.png')),
          isTrue,
        );
        expect(
          skin.spriteAssets.every((path) => path.startsWith('sprites/')),
          isTrue,
        );
        expect(
          skin.spriteAssets.every((path) => path.contains(skin.spriteDir!)),
          isTrue,
        );
      } else {
        expect(skin.spriteDir, isNull);
        expect(skin.spriteAssets, isEmpty);
      }
    }
  });

  test('配色覆盖只对特定皮肤生效', () {
    expect(snakeSkinColor(SnakeSkin.classic), isNull);
    expect(snakeSkinColor(SnakeSkin.pixel), isNotNull);
    expect(snakeSkinColor(SnakeSkin.neon), isNotNull);
    expect(snakeSkinFoodColor(SnakeSkin.classic), isNull);
    expect(snakeSkinFoodColor(SnakeSkin.candy), isNotNull);
    expect(skinUsesNeonGlow(SnakeSkin.neon), isTrue);
    expect(skinUsesNeonGlow(SnakeSkin.pixel), isFalse);
  });
}
