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

  Future<void> toggleDarkMode(bool value) async {
    if (_darkMode == value) return;
    _darkMode = value;
    notifyListeners();
    await _storage.setDarkMode(value);
  }

  Future<void> setBoardSize(int size) async {
    if (_boardSize == size) return;
    _boardSize = size;
    notifyListeners();
    await _storage.setBoardSize(size);
  }

  Future<void> setSpeed(int ms) async {
    if (_speed == ms) return;
    _speed = ms;
    notifyListeners();
    await _storage.setSpeed(ms);
  }

  Future<void> setLevel(LevelType level) async {
    if (_level == level) return;
    _level = level;
    notifyListeners();
    await _storage.setLevel(level);
  }

  Future<void> setSkin(SnakeSkin skin) async {
    if (_skin == skin) return;
    _skin = skin;
    notifyListeners();
    await _storage.setSkin(skin);
  }

  Future<void> setMode(GameMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _storage.setMode(mode);
  }

  Future<void> setMuted(bool v) async {
    if (_muted == v) return;
    _muted = v;
    AudioService().setMuted(v);
    notifyListeners();
    await _storage.setMuted(v);
  }
}
