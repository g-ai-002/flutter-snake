# 贪吃蛇游戏 — 项目规划

## 长期目标
- 跨 Android + Windows + Web 三平台的经典贪吃蛇游戏
- 精美克制的界面，操作与主流游戏一致
- 支持多种难度和棋盘大小
- 持续可演进：每个版本可独立交付，可观测、可回滚

## 中期目标
- [x] 经典贪吃蛇玩法（移动、吃食物、增长、碰撞检测）
- [x] 多种难度级别（慢/中/快）
- [x] 多种棋盘大小（小/中/大）
- [x] 最高分记录持久化
- [x] 暂停/继续/重新开始
- [x] 控制方式：桌面方向键（空格暂停）+ 全平台棋盘手势（点击/滑动）
- [x] 自适应布局（手机/折叠屏/平板/桌面）
- [x] 深色/浅色主题切换
- [x] 日志系统（按日落盘到用户目录 logs/）
- [x] 音效反馈（后续版本）
- [x] 排行榜（后续版本）
- [x] 双流水线构建与发布（GitHub Actions / Gitea Actions，push tag 自动发布 Windows + Android 交付件）
- [x] 基于 Flame 引擎的组件化渲染与游戏循环
- [x] 基于 Flame 的平滑移动、粒子与暂停 overlay
- [x] 基于 Flame 的相机、飘字、倒计时/结算与背景音乐
- [x] 多类型食物与道具（加速/减速/护盾/磁铁/双倍分）
- [x] 关卡与障碍：网格围墙、立柱阵、十字回廊、回字迷宫
- [x] 传送门：成对入口/出口，支持跨棋盘穿越
- [x] 精灵图与皮肤：蛇头、身体、食物的贴图/逐帧动画，支持皮肤切换
- [x] 输入统一由 Flame 处理：KeyboardEvents + TapCallbacks/DragCallbacks
- [x] 画布铺满整页：棋盘严格居中、带外边框，触摸手势覆盖整屏

## 短期目标
- 持续按 prompt.md 的版本节奏：新功能 → patch 修复 → patch 重构

---

## 版本历史

### v0.10.0 (MINOR)

- **状态**: 已发布 ✅
- **目标**: 支持 Web 平台并新增 GitHub Pages 多版本在线试玩
- **任务**:
  - [x] Web 平台条件导入：日志、文件系统、窗口初始化拆分 `_io` / `_web`
  - [x] Web 端日志回退到内存，设置页仍可查看
  - [x] 静态网格/地形烘焙为 `ui.Picture`
  - [x] 暂停/结算时暂停 Flame 主循环，恢复时重启
  - [x] 平台自适应操作提示
  - [x] GitHub Pages 多版本站点与 Gitea Web ZIP 产物
  - [x] 棋盘网格烘焙为 `ui.Picture`
  - [x] 版本号 0.9.0 → 0.10.0
  - [x] 更新 README/plan/versions

### v0.9.0 (MINOR)
- **状态**: 已发布 ✅
- **目标**: 画布铺满整页、全屏手势与棋盘居中外框
- **任务**:
  - [x] 画布铺满游戏页：`GameWidget` 占满 body，HUD 悬浮其上
  - [x] 新增 `board_camera`，相机按 Flutter 回报的棋盘槽位对齐世界棋盘
  - [x] 触摸手势回到 Flame：viewport 手势层覆盖整个画布，棋盘内外均可操作
  - [x] 棋盘严格居中（竖屏 HUD 在上下、横屏在左右），新增 2px 外边框
  - [x] 版本号 0.8.0 → 0.9.0
  - [x] 更新 README/plan/versions

### v0.8.0 (MINOR)
- **状态**: 已发布 ✅
- **目标**: 关卡/障碍/传送门、精灵图皮肤与 Flame 原生输入
- **任务**:
  - [x] 关卡系统：空旷、边墙、立柱阵、十字回廊、回字迷宫、传送门
  - [x] 障碍图案随棋盘尺寸缩放，开局自动清空出生走廊
  - [x] 传送门成对穿越，跨棋盘插值吸附并触发粒子反馈
  - [x] 食物生成避让墙体与传送门
  - [x] 皮肤系统：经典/像素/霓虹/糖果，蛇头、身体、食物贴图与逐帧动画
  - [x] 关卡与皮肤持久化，设置页/主页展示与切换
  - [x] 键盘（方向键/WASD/空格）迁移到 Flame KeyboardEvents
  - [x] 点击/滑动迁移到 Flame TapCallbacks/DragCallbacks
  - [x] 单元测试：布局边界、传送门、撞墙、护盾、输入方向、皮肤元数据
  - [x] 版本号 0.7.0 → 0.8.0
  - [x] 更新 README/plan/versions

### v0.7.0 (MINOR)
- **状态**: 已发布 ✅
- **目标**: 多类型食物与道具系统
- **任务**:
  - [x] 食物/道具类型：加速、减速、护盾、磁铁、双倍分
  - [x] 生成规则：概率、互斥、不与蛇身/障碍重叠
  - [x] 生命周期：拾取后的持续/倒计时/失效恢复
  - [x] 拾取特效：粒子、飘字、图标与音效
  - [x] 与暂停/倒计时/结算/最高分/排行榜兼容
  - [x] 单元测试：生成、拾取、计时、失效、碰撞
  - [x] 版本号 0.6.0 → 0.7.0
  - [x] 更新 README/plan/versions

### v0.6.0 (MINOR)
- **状态**: 已发布 ✅
- **目标**: 用相机、飘字、倒计时/结算、慢动作与音频把 Flame 体验做完整
- **任务**:
  - [x] 分数飘字与连吃提示（TextComponent + effects）
  - [x] 棋盘迁入 World + 固定分辨率 CameraComponent，死亡相机抖动
  - [x] 开局 3-2-1-GO 倒计时 overlay
  - [x] 游戏结束结算 overlay（得分/最高分/再来一局）
  - [x] 死亡慢动作（HasTimeScale）
  - [x] 音效预加载 + 循环背景音乐
  - [x] 版本号 0.5.0 → 0.6.0

### v0.5.0 (MINOR)
- **状态**: 已发布 ✅
- **目标**: 用 Flame 动画与 overlay 做可见的效果升级
- **任务**:
  - [x] 平滑移动：蛇在格子之间按 `dt` 插值滑动
  - [x] 吃到食物时身体继续前移，避免增长那一 tick 整条蛇停顿
  - [x] 吃食物粒子爆发 + 食物呼吸光晕
  - [x] 死亡反馈：红色闪屏、棋盘抖动、蛇头 X 眼
  - [x] 暂停 overlay：棋盘内半透明遮罩 + 继续按钮
  - [x] 版本号 0.4.0 → 0.5.0

### v0.4.0 (MINOR)
- **状态**: 已发布 ✅
- **目标**: 将游戏渲染与主循环迁移到 Flame 引擎
- **任务**:
  - [x] 引入 Flame 1.38.2，棋盘改为组件化渲染（背景/网格、食物、蛇身）
  - [x] 游戏循环由 `Timer.periodic` 迁移到 `FlameGame.update(dt)` 累积步进
  - [x] 游戏页改用 `GameWidget` 承载棋盘，保留手势与键盘控制
  - [x] 进入游戏时同步设置中的棋盘大小与速度
  - [x] 修复吃到食物后最高分未立即持久化的问题
  - [x] 补充 Flame 驱动入口 `tick()` 的单元测试
  - [x] 版本号 0.3.6 → 0.4.0

### v0.3.1 (PATCH)
- **状态**: 开发完成 ✅
- **目标**: 补齐 Gitea 流水线的标签发布能力，统一双流水线的发布方式
- **任务**:
  - [x] Gitea 构建工作流增加 `v*` 标签推送触发，推送标签即完成构建、产物上传与 Release 创建
  - [x] 版本号 0.3.0 → 0.3.1（`pubspec.yaml` 与 `AppConstants.version` 同步）
  - [x] 更新 README：新增 v0.3.1 下载入口、合并压缩历史版本、补充发版流程说明
  - [x] 更新 plan.md：记录本版本目标、任务与状态

### v0.3.0 (MINOR)
- **状态**: 已发布 ✅
- **目标**: 棋盘手势控制 + 构建链与依赖基线升级
- **任务**:
  - [x] 手势控制：整块棋盘支持点击 / 滑动判定方向，替换屏幕方向键控件
  - [x] 修复蛇头眼睛朝向与移动方向相反的问题
  - [x] 升级 Flutter 至 3.47.7、Dart SDK 下限对齐至 3.13.5
  - [x] 升级 Android 构建链（compileSdk 37 / targetSdk 37 / minSdk 35、NDK 30.0.16248370）并支持国内 Maven 镜像
  - [x] 新增 Gitea 构建与发布工作流，工作流名称与步骤显示名中文化
  - [x] 版本号 0.2.2 → 0.3.0
  - [x] 更新 README 文档

### v0.2.2 (PATCH)
- **状态**: 已发布 ✅
- **目标**: 重构优化存量代码，修复已知问题
- **任务**:
  - [x] 修复 Bug：FocusNode 泄漏（game_page）、AudioService dispose 未调用、leaderboard 无错误处理
  - [x] 性能优化：_randomFood 用 Set 替代 List.any、shouldRepaint 精确比较、home_page 用 context.select
  - [x] 代码质量：拆分 _tick 长方法、移除重复持久化最高分、_drawEyes 提取映射表、平行数组改结构化数据
  - [x] 错误处理：storage/file_system/main.dart 加 try-catch
  - [x] 测试增强：GameProvider 核心逻辑、LeaderboardService、边界测试
  - [x] 配置优化：analysis_options 收紧 lint 规则、CI 版本号从 pubspec.yaml 读取
  - [x] 版本号 0.2.1 → 0.2.2

### v0.2.1 (PATCH)
- **状态**: 已发布 ✅
- **目标**: 修复 CI 流水线 Windows 构建报错
- **任务**:
  - [x] 修复 audioplayers_windows 插件 C++ coroutine 编译错误
  - [x] 版本号 0.2.0 → 0.2.1

### v0.2.0 (MINOR)
- **状态**: 已发布 ✅
- **目标**: 音效反馈 + 排行榜
- **任务**:
  - [x] 音效反馈：吃食物音效、游戏结束音效（程序化生成 WAV，无需外部音频文件）
  - [x] 排行榜：多条目最高分记录（分数 + 日期），排行榜页面
  - [x] 版本号 0.1.2 → 0.2.0
  - [x] 更新测试用例
  - [x] 更新 README 文档

### v0.1.2 (PATCH)
- **状态**: 已发布 ✅
- **目标**: 重构优化存量代码，修复已知问题
- **任务**:
  - [x] 修复 settings_page.dart: RadioGroup 组件不存在，改用 RadioListTile 直接分组
  - [x] 修复 game_provider.dart: _gameOver() 不持久化最高分
  - [x] 简化 StorageService 单例模式，移除不必要的 Future 缓存
  - [x] 改进 widget_test.dart 添加有意义的冒烟测试
  - [x] 版本号 0.1.1 → 0.1.2

### v0.1.1 (PATCH)
- **状态**: 已发布 ✅
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
- Flutter: 3.47.8
- Dart: 3.13.7（对应 Flutter 3.47.8 内置 Dart SDK）
- Android SDK: compileSdk=37.2 / targetSdk=37 / minSdk=35（只保留最新 3 个 Android 大版本），NDK 30.0.16248370
- provider: 6.1.5+1
- flame: 1.38.2
- shared_preferences: 2.5.6
- path_provider: 2.1.6
- path: 1.9.1
- window_manager: 0.5.2
- audioplayers: 6.8.1
