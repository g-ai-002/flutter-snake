class AppConstants {
  AppConstants._();

  static const String appName = '贪吃蛇';
  static const String version = '0.11.0';

  static const String prefKeyDarkMode = 'dark_mode';
  static const String prefKeyHighScore = 'high_score';
  static const String prefKeyBoardSize = 'board_size';
  static const String prefKeySpeed = 'speed';
  static const String prefKeyMuted = 'muted';
  static const String prefKeyLevel = 'level';
  static const String prefKeySkin = 'skin';
  static const String prefKeyMode = 'game_mode';

  static const int defaultBoardWidth = 20;
  static const int defaultSpeedMs = 200;

  static const List<BoardOption> boardOptions = [
    BoardOption(size: 15, label: '小 (15×15)'),
    BoardOption(size: 20, label: '中 (20×20)'),
    BoardOption(size: 25, label: '大 (25×25)'),
  ];

  static const List<SpeedOption> speedOptions = [
    SpeedOption(ms: 300, label: '慢速'),
    SpeedOption(ms: 200, label: '中速'),
    SpeedOption(ms: 100, label: '快速'),
  ];
}

class BoardOption {
  final int size;
  final String label;
  const BoardOption({required this.size, required this.label});
}

class SpeedOption {
  final int ms;
  final String label;
  const SpeedOption({required this.ms, required this.label});
}
