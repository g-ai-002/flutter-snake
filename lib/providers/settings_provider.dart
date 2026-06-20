import 'package:flutter/foundation.dart';
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
    AudioService().setMuted(_muted);
  }

  late bool _darkMode;
  late int _boardSize;
  late int _speed;
  late bool _muted;

  bool get darkMode => _darkMode;
  int get boardSize => _boardSize;
  int get speed => _speed;
  bool get muted => _muted;

  String get speedLabel {
    final idx = AppConstants.speeds.indexOf(_speed);
    return idx >= 0 ? AppConstants.speedLabels[idx] : '中速';
  }

  String get boardSizeLabel {
    final idx = AppConstants.boardSizes.indexOf(_boardSize);
    return idx >= 0 ? AppConstants.boardSizeLabels[idx] : '中 (20×20)';
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

  Future<void> setMuted(bool v) async {
    if (_muted == v) return;
    _muted = v;
    AudioService().setMuted(v);
    await _storage.setMuted(v);
    notifyListeners();
  }
}
