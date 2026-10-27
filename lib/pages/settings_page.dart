import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../game/level_style.dart';
import '../game/skins/skin_style.dart';
import '../models/level.dart';
import '../models/skin.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../services/file_system_service.dart';
import '../services/log_service.dart';
import '../utils/constants.dart';
import '../utils/platform_info.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _logContent = '';
  String _logDir = '';

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _loadLogDir();
  }

  Future<void> _loadLogs() async {
    final logs = LogService.getRecentLogs();
    if (mounted) {
      setState(() => _logContent = logs.join('\n'));
    }
  }

  Future<void> _loadLogDir() async {
    try {
      final path = await FileSystemService.instance.getLogRootPath();
      if (!mounted) {
        return;
      }
      setState(() => _logDir = path);
    } catch (e, stack) {
      LogService.error('读取日志目录失败', e, stack);
    }
  }

  bool get _canOpenDir => isDesktopPlatform;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();
    final game = context.read<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // 主题
          const _SectionHeader(title: '外观'),
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('切换深色/浅色主题'),
            value: settings.darkMode,
            onChanged: (v) => settings.toggleDarkMode(v),
            secondary: Icon(
              settings.darkMode ? Icons.dark_mode : Icons.light_mode,
              color: colorScheme.primary,
            ),
          ),
          const Divider(),
          // 音效
          const _SectionHeader(title: '音效'),
          SwitchListTile(
            title: const Text('静音'),
            subtitle: const Text('关闭游戏音效'),
            value: settings.muted,
            onChanged: (v) => settings.setMuted(v),
            secondary: Icon(
              settings.muted ? Icons.volume_off : Icons.volume_up,
              color: colorScheme.primary,
            ),
          ),
          const Divider(),
          // 棋盘大小
          const _SectionHeader(title: '棋盘大小'),
          ...AppConstants.boardOptions.map((opt) {
            return RadioListTile<int>(
              title: Text(opt.label),
              value: opt.size,
              groupValue: settings.boardSize,
              onChanged: (v) {
                if (v != null) {
                  settings.setBoardSize(v);
                  game.updateBoardSize(v);
                }
              },
              secondary: Icon(Icons.grid_on, color: colorScheme.primary),
            );
          }),
          const Divider(),
          // 速度
          const _SectionHeader(title: '游戏速度'),
          ...AppConstants.speedOptions.map((opt) {
            return RadioListTile<int>(
              title: Text(opt.label),
              value: opt.ms,
              groupValue: settings.speed,
              onChanged: (v) {
                if (v != null) {
                  settings.setSpeed(v);
                  game.updateSpeed(v);
                }
              },
              secondary: Icon(Icons.speed, color: colorScheme.primary),
            );
          }),
          const Divider(),
          // 关卡
          const _SectionHeader(title: '关卡'),
          ...LevelType.values.map((level) {
            return RadioListTile<LevelType>(
              title: Text(level.label),
              subtitle: Text(level.description),
              value: level,
              groupValue: settings.level,
              onChanged: (v) {
                if (v != null) {
                  settings.setLevel(v);
                  game.updateLevel(v);
                }
              },
              secondary: Icon(levelIcon(level), color: colorScheme.primary),
            );
          }),
          const Divider(),
          // 皮肤
          const _SectionHeader(title: '皮肤'),
          ...SnakeSkin.values.map((skin) {
            return RadioListTile<SnakeSkin>(
              title: Text(skin.label),
              subtitle: Text(skin.description),
              value: skin,
              groupValue: settings.skin,
              onChanged: (v) {
                if (v != null) {
                  settings.setSkin(v);
                }
              },
              secondary: Icon(skinIcon(skin), color: colorScheme.primary),
            );
          }),
          const Divider(),
          // 关于
          const _SectionHeader(title: '关于'),
          ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.primary),
            title: const Text('版本'),
            trailing: const Text(AppConstants.version),
          ),
          // 日志目录
          if (_logDir.isNotEmpty)
            _buildDirTile(
              theme,
              icon: Icons.folder_special,
              title: '日志目录',
              path: _logDir,
              hint: '出现问题时可提供此目录下日志文件',
            ),
          ListTile(
            leading: Icon(
              Icons.description_outlined,
              color: colorScheme.primary,
            ),
            title: const Text('查看日志'),
            subtitle: const Text('查看应用运行日志'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLogDialog(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDirTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String path,
    required String hint,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            path,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.copy, color: theme.colorScheme.primary),
            tooltip: '复制路径',
            onPressed: () => _copyText(context, path),
          ),
          if (_canOpenDir)
            IconButton(
              icon: Icon(Icons.open_in_new, color: theme.colorScheme.primary),
              tooltip: '打开目录',
              onPressed: () async {
                final ok =
                    await FileSystemService.instance.openDirectory(path);
                if (!ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('当前平台不支持打开目录')),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  void _copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLogDialog(BuildContext context) {
    _loadLogs();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: const Text('应用日志'),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          _loadLogs();
                          setDialogState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: '复制全部',
                        onPressed: () => _copyText(ctx, _logContent),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _logContent.isEmpty ? '暂无日志' : _logContent,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
