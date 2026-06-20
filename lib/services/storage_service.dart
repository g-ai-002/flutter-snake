import 'package:shared_preferences/shared_preferences.dart';
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
  Future<void> setDarkMode(bool v) => _p.setBool(AppConstants.prefKeyDarkMode, v);

  int get highScore => _p.getInt(AppConstants.prefKeyHighScore) ?? 0;
  Future<void> setHighScore(int v) => _p.setInt(AppConstants.prefKeyHighScore, v);

  int get boardSize => _p.getInt(AppConstants.prefKeyBoardSize) ?? AppConstants.defaultBoardWidth;
  Future<void> setBoardSize(int v) => _p.setInt(AppConstants.prefKeyBoardSize, v);

  int get speed => _p.getInt(AppConstants.prefKeySpeed) ?? AppConstants.defaultSpeedMs;
  Future<void> setSpeed(int v) => _p.setInt(AppConstants.prefKeySpeed, v);

  bool get muted => _p.getBool(AppConstants.prefKeyMuted) ?? false;
  Future<void> setMuted(bool v) => _p.setBool(AppConstants.prefKeyMuted, v);
}
