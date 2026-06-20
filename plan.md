# 贪吃蛇游戏 — 项目规划

## 长期目标
- 跨 Android + Windows 双平台的经典贪吃蛇游戏
- 精美克制的界面，操作与主流游戏一致
- 支持多种难度和棋盘大小
- 持续可演进：每个版本可独立交付，可观测、可回滚

## 中期目标
- [x] 经典贪吃蛇玩法（移动、吃食物、增长、碰撞检测）
- [x] 多种难度级别（慢/中/快）
- [x] 多种棋盘大小（小/中/大）
- [x] 最高分记录持久化
- [x] 暂停/继续/重新开始
- [x] 键盘方向键 + 触摸方向键控制
- [x] 自适应布局（手机/折叠屏/平板/桌面）
- [x] 深色/浅色主题切换
- [x] 日志系统（按日落盘到用户目录 logs/）
- [ ] 音效反馈（后续版本）
- [ ] 排行榜（后续版本）

## 短期目标
- 持续按 prompt.md 的版本节奏：新功能 → patch 修复 → patch 重构

---

## 版本历史

### v0.1.1 (PATCH)
- **状态**: 开发中 🔧
- **目标**: 修复 CI 流水线报错
- **任务**:
  - [x] 修复 game_page.dart: RawKeyEvent → KeyEvent 迁移
  - [x] 修复 settings_page.dart: RadioGroup 替代废弃 API + const 构造
  - [x] 版本号 0.1.0 → 0.1.1

### v0.1.0 (MINOR)
- **状态**: 已发布 ✅
- **目标**: 首个版本：贪吃蛇游戏最小可用集
- **任务**:
  - [x] 项目脚手架（pubspec/analysis_options/.gitignore）
  - [x] Android 平台文件（manifest、build.gradle、签名、minSdk=34/targetSdk=36/compileSdk=36）
  - [x] 主题（Material 3 浅/深色、Windows YaHei UI、克制扁平风）
  - [x] 数据模型（Snake、Food、GameState）
  - [x] 服务层：日志、文件系统、存储
  - [x] 状态层：GameProvider、SettingsProvider
  - [x] 游戏核心：棋盘渲染、蛇移动、食物生成、碰撞检测、分数
  - [x] 界面：主页、游戏页、设置页
  - [x] 键盘方向键 + 触摸方向键控制
  - [x] 暂停/继续/重新开始
  - [x] 最高分持久化
  - [x] 单元测试
  - [x] GitHub Actions：lint + 单测 + Android APK + Windows ZIP + tag 自动 release
  - [x] README/plan

---

## 设计原则
- **离线优先**：纯本地游戏，不联网。
- **克制设计**：Material 3 风格，扁平化，少即是多。
- **可观测**：所有关键操作写入日志文件，方便排障。
- **包体克制**：当前依赖均为成熟稳定的纯 Dart / Flutter 插件，避免引入大型原生 SDK。

## 依赖与版本基线
- Flutter: 3.44.1
- provider: 6.1.5+1
- shared_preferences: 2.5.5
- path_provider: 2.1.5
- path: 1.9.1
- window_manager: 0.5.1
