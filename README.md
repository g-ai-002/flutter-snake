# 贪吃蛇 🐍

经典贪吃蛇游戏，基于 Flutter + Flame 引擎开发，支持 Android、Windows 与 Web 三平台。

## 功能

- 🔥 基于 Flame 引擎的组件化棋盘渲染与游戏主循环
- ✨ 平滑移动：蛇在格子之间连续滑动
- 🎆 吃食物粒子爆发与食物呼吸光效
- 💥 死亡反馈：红色闪屏、棋盘抖动、蛇头 X 眼
- ⏸️ 棋盘内暂停遮罩，点击继续
- 🏆 分数飘字与连吃提示
- 🍎 多类型食物/道具：加速、减速、护盾、磁铁、双倍分
- 🧲 磁铁吸附相邻食物，护盾抵挡一次碰撞
- ⏱️ 道具效果倒计时 HUD 与拾取特效
- 🎥 死亡相机拉近/抖动与慢动作
- ⏱️ 开局 3-2-1-GO 倒计时
- 📊 游戏结束结算 overlay（再来一局）
- 🎮 经典贪吃蛇玩法：移动、吃食物、增长、碰撞检测
- 🧱 关卡与障碍：边墙、立柱阵、十字回廊、回字迷宫
- 🌀 传送门：成对入口/出口，瞬间穿越棋盘
- 🎨 皮肤系统：经典 / 像素 / 霓虹 / 糖果，支持切换
- 🖼️ 精灵图：蛇头、身体与食物贴图，食物逐帧动画
- ⌨️ 键盘输入由 Flame 处理（方向键 / WASD / 空格），触摸手势覆盖整个游戏区域
- 🎯 三种难度：慢速 / 中速 / 快速
- 📐 三种棋盘大小：15×15 / 20×20 / 25×25
- 🏆 最高分记录持久化
- ⏯️ 暂停 / 继续 / 重新开始
- 🌓 深色 / 浅色主题切换
- 📱 自适应布局（手机 / 折叠屏 / 平板 / 桌面）
- 🎵 音效与背景音乐：预加载、吃食物/结束音效、循环 BGM
- 🏅 排行榜：多条目最高分记录
- 🌐 简体中文界面

## 下载

### v0.10.1（当前版本）

- [Android APK](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.10.1)
- [Windows ZIP](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.10.1)
- [Web 在线试玩](https://g-ai-002.github.io/flutter-snake/debug/)（首次需手动运行一次
  `Build & Release` 工作流；之后每个 `v*` tag 会生成独立的 `v<版本>/` 目录）

### 历史版本

- [v0.10.0](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.10.0) | [v0.9.0](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.9.0) | [v0.8.0](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.8.0) | [v0.7.0](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.7.0) | [v0.6.0](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.6.0)
- 更早版本（v0.5.0 及以前）：[v0.5.0](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.5.0) | [v0.4.0](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.4.0) | [v0.3.1](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.3.1) | [v0.3.0](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.3.0) | [v0.2.2](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.2.2) | [v0.2.1](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.2.1) | [v0.2.0](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.2.0) | [v0.1.2](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.1.2) | [v0.1.1](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.1.1) | [v0.1.0](https://github.com/g-ai-002/flutter-snake/releases/tag/v0.1.0)

## 开发

### 环境要求

- Flutter 3.47.8+（内置 Dart 3.13.7+）
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

### 皮肤贴图

皮肤精灵由脚本生成到 `assets/images/sprites/`（匹配 Flame `Images` 的默认前缀
`assets/images/`）：

```bash
python .build/generate_sprites.py
```

### Web

Web 平台由 CI 在构建时生成 `web/` 平台文件；本地预览前先执行：

```bash
flutter create --platforms=web --project-name flutter_snake .
flutter run -d chrome
```

发布 `v*` tag 后，GitHub Pages 会为每个版本保留独立目录（`v0.10.1/`、`v0.10.0/` …），
非 tag 构建写入 `debug/`，根目录自动生成版本索引页与 `versions.json`。

### 发布

推送 `v*` 标签会触发 GitHub Actions 与 Gitea Actions 双流水线，分别构建 Android APK 与
Windows ZIP，并在对应平台自动创建 Release：

```bash
git tag v0.10.1
git push origin v0.10.1
```

构建产物的版本号取自 `pubspec.yaml` 的 `version` 字段，标签版本号优先；应用内展示的版本号
位于 `lib/utils/constants.dart` 的 `AppConstants.version`，发版时需与 `pubspec.yaml` 同步修改。

## 技术栈

- Flutter 3.47.8
- Flame 1.38.2（棋盘渲染与游戏主循环）
- Provider 状态管理
- Material 3 设计
- SharedPreferences 持久化
- audioplayers 音效播放
- window_manager 桌面窗口管理
- Web：GitHub Pages 多版本在线试玩

### 代码结构

- `lib/game/snake_game.dart`：游戏编排（主循环、状态流转、overlay）
- `lib/game/camera_rig.dart`：相机对齐、缩放脉冲与抖动
- `lib/game/feedback_controller.dart`：闪屏、慢动作与连吃计时
- `lib/game/countdown_controller.dart`：开局 3-2-1-GO 倒计时
- `lib/game/power_up_manager.dart` / `lib/game/food_spawner.dart`：道具规则与食物生成
- `lib/providers/game_provider.dart`：游戏规则与持久化
- `lib/pages/widgets/game_hud.dart`：悬浮在画布上的 HUD

## 许可证

MIT
