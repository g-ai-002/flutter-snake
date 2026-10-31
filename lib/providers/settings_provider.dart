import 'package:flutter/foundation.dart';

import '../models/game_mode.dart';
import '../models/level.dart';
import '../models/skin.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(StorageService storage)
    : _storage = storage,
      _darkMode = storage.darkMode,
      _boardSize = storage.boardSize,
      _speed = storage.speed,
      _muted = storage.muted,
      _level = storage.level,
      _skin = storage.skin,
      _mode = storage.mode {
    AudioService().setMuted(_muted);
  }

  final StorageService _storage;
  bool _darkMode;
  int _boardSize;
  int _speed;
  bool _muted;
  LevelType _level;
  SnakeSkin _skin;
  GameMode _mode;

  bool get darkMode => _darkMode;
  int get boardSize => _boardSize;
  int get speed => _speed;
  bool get muted => _muted;
  LevelType get level => _level;
  SnakeSkin get skin => _skin;
  GameMode get mode => _mode;

  String get levelLabel => _level.label;
  String get skinLabel => _skin.label;
  String get modeLabel => _mode.label;

  String get speedLabel {
    for (final opt in AppConstants.speedOptions) {
      if (opt.ms == _speed) return opt.label;
    }
    return '中速';
  }

  String get boardSizeLabel {
    for (final opt in AppConstants.boardOptions) {
      if (opt.size == _boardSize) return opt.label;
    }
    return '中 (20×20)';
  }

  Future<void> toggleDarkMode(bool value) => _update(
    current: _darkMode,
    next: value,
    apply: () => _darkMode = value,
    persist: _storage.setDarkMode,
  );

  Future<void> setBoardSize(int size) => _update(
    current: _boardSize,
    next: size,
    apply: () => _boardSize = size,
    persist: _storage.setBoardSize,
  );

  Future<void> setSpeed(int ms) => _update(
    current: _speed,
    next: ms,
    apply: () => _speed = ms,
    persist: _storage.setSpeed,
  );

  Future<void> setLevel(LevelType level) => _update(
    current: _level,
    next: level,
    apply: () => _level = level,
    persist: _storage.setLevel,
  );

  Future<void> setSkin(SnakeSkin skin) => _update(
    current: _skin,
    next: skin,
    apply: () => _skin = skin,
    persist: _storage.setSkin,
  );

  Future<void> setMode(GameMode mode) => _update(
    current: _mode,
    next: mode,
    apply: () => _mode = mode,
    persist: _storage.setMode,
  );

  Future<void> setMuted(bool value) => _update(
    current: _muted,
    next: value,
    apply: () {
      _muted = value;
      AudioService().setMuted(value);
    },
    persist: _storage.setMuted,
  );

  /// 设置项统一写入流程：值未变直接返回；先刷新界面再异步落盘，
  /// 避免等待磁盘 IO 时切页出现无响应感。
  Future<void> _update<T>({
    required T current,
    required T next,
    required VoidCallback apply,
    required Future<void> Function(T value) persist,
  }) async {
    if (current == next) return;
    apply();
    notifyListeners();
    await persist(next);
  }
}
