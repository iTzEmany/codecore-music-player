import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import '../../core/uuid.dart';
import 'tag_writer.dart';

/// One saved original of a file whose tags were rewritten.
class TagBackup {
  const TagBackup({
    required this.id,
    required this.path,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String id;

  /// Where the file lived (and where a restore puts it back).
  final String path;
  final DateTime createdAt;
  final int sizeBytes;
}

/// What a file looks like after we replaced it (for the DB row).
class FileStamp {
  const FileStamp(this.sizeBytes, this.mtimeMs);

  final int sizeBytes, mtimeMs;
}

/// Puts [src] in place of [dest] atomically. When the two are on different
/// partitions (`rename` fails) it copies next to [dest] first, so [dest] is
/// still replaced by a rename and never left half-written.
Future<void> installFile(
  String src,
  String dest, {
  Future<void> Function(String from, String to)? rename,
}) async {
  Future<void> mv(String a, String b) =>
      rename != null ? rename(a, b) : File(a).rename(b).then((_) {});
  try {
    await mv(src, dest);
    return;
  } on FileSystemException catch (e) {
    AppLog.i('rename across partitions, copying: ${e.message}');
  }
  final side = '$dest.codecore-new';
  try {
    await File(src).copy(side);
    await mv(side, dest);
  } finally {
    final f = File(side);
    if (await f.exists()) await f.delete();
  }
  await File(src).delete();
}

Future<FileStamp> stampOf(String path) async {
  final st = await File(path).stat();
  return FileStamp(st.size, st.modified.millisecondsSinceEpoch);
}

/// The last [maxCount] originals, or [maxBytes] of them, whichever is less.
class TagBackupStore {
  TagBackupStore(this.dir, {this.maxCount = 200, this.maxBytes = 2 << 30});

  final Directory dir;
  final int maxCount, maxBytes;

  final _changes = StreamController<void>.broadcast();

  /// Fires after a backup is added or deleted, so lists can refresh.
  Stream<void> get changes => _changes.stream;

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  File _data(String id) => File(p.join(dir.path, '$id.bak'));
  File _meta(String id) => File(p.join(dir.path, '$id.json'));

  Future<TagBackup> add(String originalPath) async {
    try {
      await dir.create(recursive: true);
      final id = '${DateTime.now().millisecondsSinceEpoch}-${newUuid().substring(0, 8)}';
      final src = File(originalPath);
      await src.copy(_data(id).path);
      final size = await _data(id).length();
      final b = TagBackup(
        id: id,
        path: originalPath,
        createdAt: DateTime.now(),
        sizeBytes: size,
      );
      await _meta(id).writeAsString(jsonEncode({
        'path': originalPath,
        'createdAt': b.createdAt.millisecondsSinceEpoch,
        'size': size,
      }));
      await prune(keep: id);
      _notify();
      return b;
    } on FileSystemException catch (e, st) {
      AppLog.e('tag backup failed: $originalPath', e, st);
      throw TagWriteException(TagWriteReason.backupFailed, e.message);
    }
  }

  /// Newest first.
  Future<List<TagBackup>> list() async {
    if (!await dir.exists()) return const [];
    final out = <TagBackup>[];
    await for (final f in dir.list()) {
      if (f is! File || p.extension(f.path) != '.json') continue;
      final id = p.basenameWithoutExtension(f.path);
      try {
        final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        if (!await _data(id).exists()) continue;
        out.add(TagBackup(
          id: id,
          path: m['path'] as String,
          createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
          sizeBytes: m['size'] as int,
        ));
      } on Object catch (e, st) {
        AppLog.w('unreadable tag backup entry ${f.path}', e, st);
      }
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  Future<void> delete(TagBackup b) async {
    for (final f in [_data(b.id), _meta(b.id)]) {
      if (await f.exists()) await f.delete();
    }
    _notify();
  }

  /// Puts the saved original back where it came from.
  Future<FileStamp> restore(TagBackup b) async {
    if (!await _data(b.id).exists()) {
      throw const TagWriteException(TagWriteReason.notFound, 'backup missing');
    }
    final tmp = '${b.path}.codecore-restore';
    try {
      await _data(b.id).copy(tmp);
      await installFile(tmp, b.path);
    } on FileSystemException catch (e, st) {
      AppLog.e('tag backup restore failed: ${b.path}', e, st);
      throw TagWriteException(TagWriteReason.ioError, e.message);
    } finally {
      final f = File(tmp);
      if (await f.exists()) await f.delete();
    }
    return stampOf(b.path);
  }

  Future<void> prune({String? keep}) async {
    final all = await list();
    var total = 0;
    for (var i = 0; i < all.length; i++) {
      total += all[i].sizeBytes;
      if ((i >= maxCount || total > maxBytes) && all[i].id != keep) {
        await delete(all[i]);
      }
    }
  }
}
