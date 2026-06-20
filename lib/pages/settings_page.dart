import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
          // 棋盘大小
          const _SectionHeader(title: '棋盘大小'),
          RadioGroup<int>(
            groupValue: settings.boardSize,
            onChanged: (v) {
              if (v != null) {
                settings.setBoardSize(v);
                game.updateBoardSize(v);
              }
            },
            child: Column(
              children: AppConstants.boardSizes.asMap().entries.map((entry) {
                final idx = entry.key;
                final size = entry.value;
                final label = AppConstants.boardSizeLabels[idx];
                return RadioListTile<int>(
                  title: Text(label),
                  value: size,
                  secondary: Icon(Icons.grid_on, color: colorScheme.primary),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          // 速度
          const _SectionHeader(title: '游戏速度'),
          RadioGroup<int>(
            groupValue: settings.speed,
            onChanged: (v) {
              if (v != null) {
                settings.setSpeed(v);
                game.updateSpeed(v);
              }
            },
            child: Column(
              children: AppConstants.speeds.asMap().entries.map((entry) {
                final idx = entry.key;
                final speed = entry.value;
                final label = AppConstants.speedLabels[idx];
                return RadioListTile<int>(
                  title: Text(label),
                  value: speed,
                  secondary: Icon(Icons.speed, color: colorScheme.primary),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          // 关于
          const _SectionHeader(title: '关于'),
          ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.primary),
            title: const Text('版本'),
            trailing: const Text(AppConstants.version),
          ),
          const SizedBox(height: 32),
        ],
      ),
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
