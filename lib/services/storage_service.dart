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

  /// 写入失败（如存储不可用）时静默忽略，不影响游戏主流程。
  Future<void> _write(
    Future<bool> Function(SharedPreferences prefs) action,
  ) async {
    try {
      await action(_p);
    } catch (_) {}
  }

  /// 枚举按名称存取，遇到未知值回退到默认项。
  T _enumValue<T extends Enum>(List<T> values, String key, T fallback) {
    final name = _p.getString(key);
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  bool get darkMode => _p.getBool(AppConstants.prefKeyDarkMode) ?? false;
  Future<void> setDarkMode(bool v) => _write(
        (p) => p.setBool(AppConstants.prefKeyDarkMode, v),
      );

  int get highScore => _p.getInt(AppConstants.prefKeyHighScore) ?? 0;
  Future<void> setHighScore(int v) => _write(
        (p) => p.setInt(AppConstants.prefKeyHighScore, v),
      );

  int get boardSize =>
      _p.getInt(AppConstants.prefKeyBoardSize) ??
      AppConstants.defaultBoardWidth;
  Future<void> setBoardSize(int v) => _write(
        (p) => p.setInt(AppConstants.prefKeyBoardSize, v),
      );

  int get speed =>
      _p.getInt(AppConstants.prefKeySpeed) ?? AppConstants.defaultSpeedMs;
  Future<void> setSpeed(int v) => _write(
        (p) => p.setInt(AppConstants.prefKeySpeed, v),
      );

  bool get muted => _p.getBool(AppConstants.prefKeyMuted) ?? false;
  Future<void> setMuted(bool v) => _write(
        (p) => p.setBool(AppConstants.prefKeyMuted, v),
      );

  LevelType get level => _enumValue(
        LevelType.values,
        AppConstants.prefKeyLevel,
        LevelType.open,
      );

  Future<void> setLevel(LevelType v) => _write(
        (p) => p.setString(AppConstants.prefKeyLevel, v.name),
      );

  SnakeSkin get skin => _enumValue(
        SnakeSkin.values,
        AppConstants.prefKeySkin,
        SnakeSkin.classic,
      );

  Future<void> setSkin(SnakeSkin v) => _write(
        (p) => p.setString(AppConstants.prefKeySkin, v.name),
      );
}
