import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_snake/game/board_camera.dart';
import 'package:flutter_snake/game/snake_game.dart';
import 'package:flutter_snake/models/game_state.dart';
import 'package:flutter_snake/models/skin.dart';
import 'package:flutter_snake/providers/game_provider.dart';

import 'fakes/fake_storage.dart';

void main() {
  const worldBoard = Rect.fromLTWH(0, 0, 400, 400);

  group('相机布局', () {
    test('棋盘居中时的缩放与取景器位置', () {
      final layout = cameraLayoutForBoard(
        canvasSize: const Size(400, 800),
        boardRect: const Rect.fromLTWH(100, 300, 200, 200),
        worldBoardRect: worldBoard,
      );

      expect(layout.zoom, 0.5);
      expect(layout.position.x, 200);
      expect(layout.position.y, 200);
    });

    test('棋盘偏离画布中心时取景器反向偏移', () {
      final layout = cameraLayoutForBoard(
        canvasSize: const Size(400, 800),
        boardRect: const Rect.fromLTWH(100, 500, 200, 200),
        worldBoardRect: worldBoard,
      );

      expect(layout.zoom, 0.5);
      expect(layout.position.x, 200);
      expect(layout.position.y, -200);
    });

    test('指定缩放时棋盘中心仍落在目标矩形中心', () {
      final layout = cameraLayoutForBoard(
        canvasSize: const Size(400, 800),
        boardRect: const Rect.fromLTWH(100, 300, 200, 200),
        worldBoardRect: worldBoard,
        zoom: 0.25,
      );

      expect(layout.zoom, 0.25);
      expect(layout.position.x, 200);
      expect(layout.position.y, 200);
    });
  });

  group('SnakeGame 画布手势', () {
    SnakeGame buildGame(GameProvider provider) {
      return SnakeGame(
        provider: provider,
        surfaceColor: Colors.black,
        snakeColor: Colors.green,
        foodColor: Colors.red,
        gridColor: Colors.white,
        wallColor: Colors.grey,
        portalColor: Colors.purple,
        skin: SnakeSkin.classic,
      );
    }

    test('棋盘槽位同步到相机', () {
      final provider =
          GameProvider(FakeStorageService.create(), audioEnabled: false);
      final game = buildGame(provider);
      game.updateBoardLayout(
        boardRect: const Rect.fromLTWH(0, 0, 200, 200),
        canvasSize: const Size(200, 400),
      );

      expect(game.camera.viewfinder.zoom, 0.5);
      expect(game.camera.viewfinder.position.x, 200);
      expect(game.camera.viewfinder.position.y, 400);
    });

    test('棋盘以外的滑动也能转向', () {
      final provider =
          GameProvider(FakeStorageService.create(), audioEnabled: false);
      provider.start();
      final game = buildGame(provider);
      game.updateBoardLayout(
        boardRect: const Rect.fromLTWH(0, 0, 200, 200),
        canvasSize: const Size(200, 400),
      );
      final head = provider.state.snake.head;

      game.handleSwipe(const Offset(0, 80));
      provider.tick();

      expect(provider.state.snake.head, head.move(Direction.down));
    });

    test('点击位置相对棋盘中心推断方向', () {
      final provider =
          GameProvider(FakeStorageService.create(), audioEnabled: false);
      provider.start();
      final game = buildGame(provider);
      game.updateBoardLayout(
        boardRect: const Rect.fromLTWH(0, 0, 200, 200),
        canvasSize: const Size(200, 400),
      );
      final head = provider.state.snake.head;

      game.handleTap(const Offset(100, 10));
      provider.tick();

      expect(provider.state.snake.head, head.move(Direction.up));
    });
  });
}
