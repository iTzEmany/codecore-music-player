import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/app_log.dart';

/// Small `downloads.json`: video id -> absolute file path.
class DownloadIndex {
  DownloadIndex(this._file);

  final File _file;
  Map<String, String> _map = {};

  Future<void> load() async {
    try {
      if (await _file.exists()) {
        final raw = jsonDecode(await _file.readAsString());
        if (raw is Map) {
          _map = {for (final e in raw.entries) '${e.key}': '${e.value}'};
        }
      }
    } on Object catch (e, st) {
      AppLog.w('downloads index unreadable', e, st);
    }
  }

  bool contains(String videoId) {
    final path = _map[videoId];
    return path != null && File(path).existsSync();
  }

  Future<void> add(String videoId, String path) async {
    _map[videoId] = path;
    try {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(jsonEncode(_map));
    } on Object catch (e, st) {
      AppLog.w('downloads index write failed', e, st);
    }
  }

  static File defaultFile(String supportDir) =>
      File(p.join(supportDir, 'downloads.json'));
}
