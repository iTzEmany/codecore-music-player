import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import 'youtube_service.dart';

/// Small `downloads.json`: `<source>:<id>` -> absolute file path. Entries
/// written before sources existed have the bare YouTube video id as key and
/// still count as `youtube:<id>`.
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

  bool contains(String id, {MediaSource source = MediaSource.youtube}) =>
      pathFor(id, source: source) != null;

  /// Where the video was downloaded, if the file is still there.
  String? pathFor(String id, {MediaSource source = MediaSource.youtube}) {
    final path = _map[downloadIndexKey(source, id)] ??
        (source == MediaSource.youtube ? _map[id] : null);
    return path != null && File(path).existsSync() ? path : null;
  }

  Future<void> _lastWrite = Future.value();

  /// Writes are chained: parallel downloads must not interleave in the file.
  Future<void> add(String id, String path,
      {MediaSource source = MediaSource.youtube}) {
    _map[downloadIndexKey(source, id)] = path;
    return _lastWrite = _lastWrite.then((_) async {
      try {
        await _file.parent.create(recursive: true);
        await _file.writeAsString(jsonEncode(_map));
      } on Object catch (e, st) {
        AppLog.w('downloads index write failed', e, st);
      }
    });
  }

  static File defaultFile(String supportDir) =>
      File(p.join(supportDir, 'downloads.json'));
}
