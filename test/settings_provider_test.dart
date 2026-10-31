import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_snake/models/game_mode.dart';
import 'package:flutter_snake/models/level.dart';
import 'package:flutter_snake/models/skin.dart';
import 'package:flutter_snake/providers/settings_provider.dart';

import 'fakes/fake_storage.dart';

/// SettingsProvider 构造时会创建 AudioService，纯 Dart 测试里没有音频插件，
/// 这里把 audioplayers 的平台通道打桩，避免异步 MissingPluginException。
void _mockAudioChannels() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in ['xyz.luan/audioplayers.global', 'xyz.luan/audioplayers']) {
    messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_mockAudioChannels);

  group('SettingsProvider 写入流程', () {
    test('修改设置先刷新内存再写回存储', () async {
      final storage = FakeStorageService.create();
      final settings = SettingsProvider(storage);

      await settings.setBoardSize(25);
      await settings.setSpeed(100);
      await settings.setLevel(LevelType.maze);
      await settings.setMode(GameMode.timed);
      await settings.setSkin(SnakeSkin.candy);

      expect(settings.boardSize, 25);
      expect(settings.speed, 100);
      expect(settings.level, LevelType.maze);
      expect(settings.mode, GameMode.timed);
      expect(settings.skin, SnakeSkin.candy);
      expect(storage.boardSize, 25);
      expect(storage.speed, 100);
      expect(storage.level, LevelType.maze);
      expect(storage.mode, GameMode.timed);
      expect(storage.skin, SnakeSkin.candy);
    });

    test('值未变化时不通知界面', () async {
      final storage = FakeStorageService.create();
      final settings = SettingsProvider(storage);
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.setBoardSize(settings.boardSize);
      await settings.setSpeed(settings.speed);
      await settings.setMode(settings.mode);
      await settings.setLevel(settings.level);
      await settings.setSkin(settings.skin);
      await settings.toggleDarkMode(settings.darkMode);

      expect(notifications, 0);
    });

    test('每次真实修改只通知一次', () async {
      final storage = FakeStorageService.create();
      final settings = SettingsProvider(storage);
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.toggleDarkMode(true);
      await settings.setMuted(true);

      expect(notifications, 2);
      expect(storage.darkMode, isTrue);
      expect(storage.muted, isTrue);
    });
  });
}
