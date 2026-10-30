import 'package:flutter/foundation.dart';

import '../models/game_mode.dart';
import '../models/level.dart';
import '../models/skin.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  SettingsProvider(this._storage) {
    _darkMode = _storage.darkMode;
    _boardSize = _storage.boardSize;
    _speed = _storage.speed;
    _muted = _storage.muted;
    _level = _storage.level;
    _skin = _storage.skin;
    _mode = _storage.mode;
    AudioService().setMuted(_muted);
  }

  late bool _darkMode;
  late int _boardSize;
  late int _speed;
  late bool _muted;
  late LevelType _level;
  late SnakeSkin _skin;
  late GameMode _mode;

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
    await _storage.setDarkMode(value);
    notifyListeners();
  }

  Future<void> setBoardSize(int size) async {
    if (_boardSize == size) return;
    _boardSize = size;
    await _storage.setBoardSize(size);
    notifyListeners();
  }

  Future<void> setSpeed(int ms) async {
    if (_speed == ms) return;
    _speed = ms;
    await _storage.setSpeed(ms);
    notifyListeners();
  }

  Future<void> setLevel(LevelType level) async {
    if (_level == level) return;
    _level = level;
    await _storage.setLevel(level);
    notifyListeners();
  }

  Future<void> setSkin(SnakeSkin skin) async {
    if (_skin == skin) return;
    _skin = skin;
    await _storage.setSkin(skin);
    notifyListeners();
  }

  Future<void> setMode(GameMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    await _storage.setMode(mode);
    notifyListeners();
  }

  Future<void> setMuted(bool v) async {
    if (_muted == v) return;
    _muted = v;
    AudioService().setMuted(v);
    await _storage.setMuted(v);
    notifyListeners();
  }
}
