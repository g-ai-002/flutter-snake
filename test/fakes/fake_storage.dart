import 'package:flutter_snake/models/level.dart';
import 'package:flutter_snake/models/skin.dart';
import 'package:flutter_snake/services/storage_service.dart';

/// 测试用的内存存储，避免依赖 SharedPreferences。
class FakeStorageService extends StorageService {
  final Map<String, dynamic> _store = {};

  FakeStorageService() : super.test();

  static FakeStorageService create() => FakeStorageService();

  @override
  bool get darkMode => _store['dark_mode'] as bool? ?? false;

  @override
  Future<void> setDarkMode(bool v) async {
    _store['dark_mode'] = v;
  }

  @override
  int get highScore => _store['high_score'] as int? ?? 0;

  @override
  Future<void> setHighScore(int v) async {
    _store['high_score'] = v;
  }

  @override
  int get boardSize => _store['board_size'] as int? ?? 20;

  @override
  Future<void> setBoardSize(int v) async {
    _store['board_size'] = v;
  }

  @override
  int get speed => _store['speed'] as int? ?? 200;

  @override
  Future<void> setSpeed(int v) async {
    _store['speed'] = v;
  }

  @override
  bool get muted => _store['muted'] as bool? ?? false;

  @override
  Future<void> setMuted(bool v) async {
    _store['muted'] = v;
  }

  LevelType _level = LevelType.open;

  @override
  LevelType get level => _level;

  @override
  Future<void> setLevel(LevelType v) async {
    _level = v;
  }

  SnakeSkin _skin = SnakeSkin.classic;

  @override
  SnakeSkin get skin => _skin;

  @override
  Future<void> setSkin(SnakeSkin v) async {
    _skin = v;
  }
}
