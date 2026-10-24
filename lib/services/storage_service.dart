import 'package:shared_preferences/shared_preferences.dart';
import '../models/level.dart';
import '../models/skin.dart';
import '../utils/constants.dart';

class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  /// 仅供测试使用
  StorageService.test();

  static Future<StorageService> get instance async {
    if (_instance != null) return _instance!;
    _instance = StorageService._();
    _instance!._prefs = await SharedPreferences.getInstance();
    return _instance!;
  }

  SharedPreferences get _p {
    final p = _prefs;
    if (p == null) throw StateError('StorageService 尚未初始化');
    return p;
  }

  bool get darkMode => _p.getBool(AppConstants.prefKeyDarkMode) ?? false;
  Future<void> setDarkMode(bool v) async {
    try { await _p.setBool(AppConstants.prefKeyDarkMode, v); } catch (_) {}
  }

  int get highScore => _p.getInt(AppConstants.prefKeyHighScore) ?? 0;
  Future<void> setHighScore(int v) async {
    try { await _p.setInt(AppConstants.prefKeyHighScore, v); } catch (_) {}
  }

  int get boardSize => _p.getInt(AppConstants.prefKeyBoardSize) ?? AppConstants.defaultBoardWidth;
  Future<void> setBoardSize(int v) async {
    try { await _p.setInt(AppConstants.prefKeyBoardSize, v); } catch (_) {}
  }

  int get speed => _p.getInt(AppConstants.prefKeySpeed) ?? AppConstants.defaultSpeedMs;
  Future<void> setSpeed(int v) async {
    try { await _p.setInt(AppConstants.prefKeySpeed, v); } catch (_) {}
  }

  bool get muted => _p.getBool(AppConstants.prefKeyMuted) ?? false;
  Future<void> setMuted(bool v) async {
    try { await _p.setBool(AppConstants.prefKeyMuted, v); } catch (_) {}
  }

  LevelType get level {
    final name = _p.getString(AppConstants.prefKeyLevel);
    return LevelType.values.firstWhere(
      (value) => value.name == name,
      orElse: () => LevelType.open,
    );
  }

  Future<void> setLevel(LevelType v) async {
    try { await _p.setString(AppConstants.prefKeyLevel, v.name); } catch (_) {}
  }

  SnakeSkin get skin {
    final name = _p.getString(AppConstants.prefKeySkin);
    return SnakeSkin.values.firstWhere(
      (value) => value.name == name,
      orElse: () => SnakeSkin.classic,
    );
  }

  Future<void> setSkin(SnakeSkin v) async {
    try { await _p.setString(AppConstants.prefKeySkin, v.name); } catch (_) {}
  }
}
