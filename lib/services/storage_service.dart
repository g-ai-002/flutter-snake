import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class StorageService {
  static Future<StorageService>? _initFuture;

  SharedPreferences? _prefs;
  bool _initialized = false;

  StorageService._();

  static Future<StorageService> get instance {
    final cached = _initFuture;
    if (cached != null) return cached;
    final f = _bootstrap();
    _initFuture = f;
    return f;
  }

  static Future<StorageService> _bootstrap() async {
    final s = StorageService._();
    await s._init();
    return s;
  }

  Future<void> _init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
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
}
