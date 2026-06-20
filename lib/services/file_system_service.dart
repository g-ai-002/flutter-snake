import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileSystemService {
  FileSystemService._();
  static final FileSystemService instance = FileSystemService._();

  Directory? _logRoot;

  Future<Directory> getUserRoot() async {
    Directory base;
    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      base = ext ?? await getApplicationDocumentsDirectory();
    } else {
      base = await getApplicationDocumentsDirectory();
    }
    final root = Directory('${base.path}${Platform.pathSeparator}FlutterSnake');
    try {
      if (!await root.exists()) {
        await root.create(recursive: true);
      }
    } catch (_) {}
    return root;
  }

  Future<Directory> getLogRoot() async {
    if (_logRoot != null) return _logRoot!;
    final user = await getUserRoot();
    final logDir = Directory('${user.path}${Platform.pathSeparator}logs');
    try {
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
    } catch (_) {}
    _logRoot = logDir;
    return logDir;
  }
}
