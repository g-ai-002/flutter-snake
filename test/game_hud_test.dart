import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_snake/models/game_mode.dart';
import 'package:flutter_snake/models/power_up.dart';
import 'package:flutter_snake/pages/widgets/game_hud.dart';
import 'package:flutter_snake/providers/game_provider.dart';

import 'fakes/fake_storage.dart';

Widget _buildHud(GameProvider game, GlobalKey pageKey) {
  return ChangeNotifierProvider<GameProvider>.value(
    value: game,
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 600,
          child: GameHud(
            pageKey: pageKey,
            canvasSize: const Size(400, 600),
            boardRect: const Rect.fromLTWH(0, 100, 400, 400),
            landscape: false,
            showHint: false,
            onBoardRect: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('HUD 展示最高分与模式，并在切换模式后刷新', (WidgetTester tester) async {
    final storage = FakeStorageService.create();
    await storage.setHighScore(42);
    final game = GameProvider(storage, audioEnabled: false);

    await tester.pumpWidget(_buildHud(game, GlobalKey()));
    expect(find.text('最高分: 42'), findsOneWidget);
    expect(find.text('模式: 经典'), findsOneWidget);

    game.updateMode(GameMode.wrap);
    await tester.pump();
    expect(find.text('模式: 穿墙'), findsOneWidget);
    expect(find.text('模式: 经典'), findsNothing);
  });

  testWidgets('HUD 道具栏只展示生效中的效果', (WidgetTester tester) async {
    final storage = FakeStorageService.create();
    final game = GameProvider(storage, audioEnabled: false);

    await tester.pumpWidget(_buildHud(game, GlobalKey()));
    expect(find.textContaining('加速'), findsNothing);

    game.activatePowerUp(PowerUpType.speedUp);
    await tester.pump();
    expect(find.textContaining('加速'), findsOneWidget);

    game.updateEffects(PowerUpType.speedUp.durationSeconds + 0.1);
    await tester.pump();
    expect(find.textContaining('加速'), findsNothing);
  });

  testWidgets('未开局时 HUD 提供重新开始按钮', (WidgetTester tester) async {
    final storage = FakeStorageService.create();
    final game = GameProvider(storage, audioEnabled: false);

    await tester.pumpWidget(_buildHud(game, GlobalKey()));
    expect(find.text('重新开始'), findsOneWidget);
    expect(game.isIdle, isTrue);

    await tester.tap(find.text('重新开始'));
    await tester.pump();
    expect(game.isPlaying, isTrue);
    expect(find.text('重新开始'), findsNothing);
  });
}
