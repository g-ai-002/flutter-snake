import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_snake/game/overlays/pause_overlay.dart';
import 'package:flutter_snake/providers/game_provider.dart';

import 'fakes/fake_storage.dart';

void main() {
  testWidgets('暂停遮罩提供继续、重新开始与返回主页', (WidgetTester tester) async {
    var resumed = 0;
    var restarted = 0;
    var exited = 0;
    final provider = GameProvider(
      FakeStorageService.create(),
      audioEnabled: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PauseOverlay(
          provider: provider,
          onResume: () => resumed++,
          onRestart: () => restarted++,
          onExit: () => exited++,
        ),
      ),
    );

    expect(find.text('已暂停'), findsOneWidget);

    await tester.tap(find.text('继续'));
    await tester.tap(find.text('重新开始'));
    await tester.tap(find.text('返回主页'));

    expect(resumed, 1);
    expect(restarted, 1);
    expect(exited, 1);
  });
}
