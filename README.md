# 贪吃蛇 🐍

经典贪吃蛇游戏，基于 Flutter + Flame 引擎开发，支持 Android 和 Windows 双平台。

## 功能

- 🔥 基于 Flame 引擎的组件化棋盘渲染与游戏主循环
- ✨ 平滑移动：蛇在格子之间连续滑动
- 🎆 吃食物粒子爆发与食物呼吸光效
- 💥 死亡反馈：红色闪屏、棋盘抖动、蛇头 X 眼
- ⏸️ 棋盘内暂停遮罩，点击继续
- 🏆 分数飘字与连吃提示
- 🎥 相机缩放/抖动与死亡慢动作
- ⏱️ 开局 3-2-1-GO 倒计时
- 📊 游戏结束结算 overlay（再来一局）
- 🎮 经典贪吃蛇玩法：移动、吃食物、增长、碰撞检测
- 🎯 三种难度：慢速 / 中速 / 快速
- 📐 三种棋盘大小：15×15 / 20×20 / 25×25
- 🏆 最高分记录持久化
- ⏯️ 暂停 / 继续 / 重新开始
- 🎮 手势控制：点击 / 滑动整块棋盘判定方向
- ⌨️ 键盘控制：方向键转向、空格暂停（Windows）
- 🌓 深色 / 浅色主题切换
- 📱 自适应布局（手机 / 折叠屏 / 平板 / 桌面）
- 🎵 音效与背景音乐：预加载、吃食物/结束音效、循环 BGM
- 🏅 排行榜：多条目最高分记录
- 🌐 简体中文界面

## 下载

### v0.3.1

- [Android APK](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.3.1)
- [Windows ZIP](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.3.1)

### v0.3.0

- [Android APK](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.3.0)
- [Windows ZIP](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.3.0)

### v0.2.2

- [Android APK](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.2.2)
- [Windows ZIP](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.2.2)

### v0.1.0 ~ v0.2.1（历史版本）

- [v0.2.1](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.2.1) | [v0.2.0](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.2.0) | [v0.1.2](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.1.2) | [v0.1.1](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.1.1) | [v0.1.0](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.1.0)

## 开发

### 环境要求

- Flutter 3.47.7+（内置 Dart 3.13.5+）
- Android SDK 37+（编译 SDK；最低支持 Android 15，仅覆盖最新 3 个 Android 大版本）
- Windows 10+

### 运行

```bash
flutter pub get
flutter run
```

### 测试

```bash
flutter test
```

### 发布

推送 `v*` 标签会触发 GitHub Actions 与 Gitea Actions 双流水线，分别构建 Android APK 与
Windows ZIP，并在对应平台自动创建 Release：

```bash
git tag v0.3.1
git push origin v0.3.1
```

构建产物的版本号取自 `pubspec.yaml` 的 `version` 字段，标签版本号优先；应用内展示的版本号
位于 `lib/utils/constants.dart` 的 `AppConstants.version`，发版时需与 `pubspec.yaml` 同步修改。

## 技术栈

- Flutter 3.47.7
- Flame 1.38.2（棋盘渲染与游戏主循环）
- Provider 状态管理
- Material 3 设计
- SharedPreferences 持久化
- audioplayers 音效播放
- window_manager 桌面窗口管理

## 许可证

MIT
