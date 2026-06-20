class AppConstants {
  AppConstants._();

  static const String appName = '贪吃蛇';
  static const String version = '0.1.0';

  static const String prefKeyDarkMode = 'dark_mode';
  static const String prefKeyHighScore = 'high_score';
  static const String prefKeyBoardSize = 'board_size';
  static const String prefKeySpeed = 'speed';

  static const int defaultBoardWidth = 20;
  static const int defaultBoardHeight = 20;
  static const int defaultSpeedMs = 200;

  static const List<int> boardSizes = [15, 20, 25];
  static const List<int> speeds = [300, 200, 100];
  static const List<String> speedLabels = ['慢速', '中速', '快速'];
  static const List<String> boardSizeLabels = ['小 (15×15)', '中 (20×20)', '大 (25×25)'];
}
