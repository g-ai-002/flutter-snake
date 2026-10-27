import 'platform_info.dart';

/// 各界面展示的玩法提示：桌面端讲键盘，移动端/浏览器讲触屏。
class GameHints {
  GameHints._();

  /// 首页底部的一句话提示。
  static String get home => isDesktopPlatform
      ? '方向键 / WASD 转向，空格暂停'
      : '点击或滑动屏幕任意位置转向';

  /// 游戏画面中的开局提示。
  static String get inGame => isDesktopPlatform
      ? '方向键 / WASD 转向 · 空格暂停'
      : '点击或滑动屏幕任意位置控制方向';

  /// 设置页：移动与转向。
  static String get movement => isDesktopPlatform
      ? '方向键 / WASD 控制蛇头方向，不能直接掉头'
      : '点击屏幕按相对方向转向，或向任意方向滑动';

  /// 设置页：暂停。
  static String get pause => isDesktopPlatform
      ? '空格 / P / Esc 暂停，再按一次继续'
      : '点右上角暂停按钮，再点一次继续';
}
