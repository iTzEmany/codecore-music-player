import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import '../../core/paths.dart';
import '../memory/disk_space.dart';
import 'stream_key.dart';

const _mb = 1024 * 1024;

/// LRU cache of streamed tracks: one file per key, last use = modified time.
class StreamCache {
  StreamCache(
    this.dir, {
    this.limitBytes = 500 * _mb,
    Future<int?> Function()? freeSpace,
    Future<void> Function(File)? delete,
  })  : _freeSpace = freeSpace ?? (() async => (await diskSpaceOf(dir.path))?.freeBytes),
        _delete = delete ?? ((f) => f.delete());

  /// `<appSupportDir>/stream_cache`, outside every music folder.
  static Future<StreamCache> inAppSupport({int limitBytes = 500 * _mb}) async =>
      StreamCache(Directory(p.join(await appSupportDir(), 'stream_cache')), limitBytes: limitBytes);

  /// Space always left free on the disk (D-84).
  static const freeMargin = 500 * _mb;

  final Directory dir;

  /// The slider value; may change at runtime.
  int limitBytes;
  final Future<int?> Function() _freeSpace;
  final Future<void> Function(File) _delete;
  final _pins = <String, int>{};

  /// Bytes in the folder, measured after `open` and every `evict`.
  int usedBytes = 0;

  /// Creates the folder, drops interrupted downloads, measures what is left.
  Future<void> open() async {
    await dir.create(recursive: true);
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.part')) await _remove(e);
      // Temp folders of the preparer's interrupted downloads.
      if (e is Directory && p.basename(e.path).startsWith('.dl-')) {
        try {
          await e.delete(recursive: true);
        } on FileSystemException catch (err, st) {
          AppLog.w('stream cache: cannot delete ${e.path}', err, st);
        }
      }
    }
    await _measure();
  }

  String _stem(File f) => p.basenameWithoutExtension(f.path);

  /// The cached file (any extension), or null.
  Future<File?> fileFor(String key) async {
    final name = streamFileName(key);
    for (final e in await _files()) {
      if (_stem(e.file) == name) return e.file;
    }
    return null;
  }

  /// Moves a finished `<name>.<ext>.part` in as [key], then trims the cache.
  /// The new file is pinned during the trim so it is never its own victim.
  Future<File> put(String key, File part) async {
    await dir.create(recursive: true);
    final name = streamFileName(key);
    final ext = p.extension(p.basenameWithoutExtension(part.path));
    for (final e in await _files()) {
      if (_stem(e.file) == name) await _remove(e.file);
    }
    final f = await part.rename(p.join(dir.path, '$name$ext'));
    pin(key);
    try {
      await evict();
    } finally {
      unpin(key);
    }
    return f;
  }

  /// Marks [key] as just used.
  Future<void> touch(String key) async {
    final f = await fileFor(key);
    if (f != null) await f.setLastModified(DateTime.now());
  }

  void pin(String key) => _pins.update(key, (n) => n + 1, ifAbsent: () => 1);

  void unpin(String key) {
    final n = (_pins[key] ?? 0) - 1;
    n > 0 ? _pins[key] = n : _pins.remove(key);
  }

  /// min(slider, free space − margin), never negative (K-05). [used] defaults to [usedBytes].
  Future<int> effectiveLimit([int? used]) async {
    final free = await _freeSpace();
    // The cache's own bytes are free space too, so they count towards the room.
    final room = free == null ? limitBytes : free + (used ?? usedBytes) - freeMargin;
    return (room < limitBytes ? room : limitBytes).clamp(0, limitBytes);
  }

  /// Deletes least recently used files until under the limit, skipping pinned ones.
  Future<void> evict() async {
    await _measure();
    final limit = await effectiveLimit(usedBytes);
    final files = await _files();
    var used = usedBytes;
    files.sort((a, b) => a.time.compareTo(b.time));
    final pinned = _pins.keys.map(streamFileName).toSet();
    for (final e in files) {
      if (used <= limit) break;
      if (pinned.contains(_stem(e.file))) continue;
      if (await _remove(e.file)) used -= e.size;
    }
    await _measure(); // K-06: a failed delete is retried at the next evict
  }

  /// Deletes everything except the [keep] keys and the pinned ones.
  Future<void> clear({Set<String> keep = const {}}) async {
    final kept = {...keep, ..._pins.keys}.map(streamFileName).toSet();
    for (final e in await _files()) {
      if (!kept.contains(_stem(e.file))) await _remove(e.file);
    }
    await _measure();
  }

  Future<List<({File file, int size, DateTime time})>> _files() async {
    final out = <({File file, int size, DateTime time})>[];
    if (!await dir.exists()) return out;
    await for (final e in dir.list()) {
      if (e is! File || e.path.endsWith('.part')) continue;
      final s = await e.stat();
      if (s.type != FileSystemEntityType.file) continue;
      out.add((file: e, size: s.size, time: s.modified));
    }
    return out;
  }

  /// Re-reads the folder size into [usedBytes] without evicting.
  Future<int> measure() async => _measure();

  Future<int> _measure() async =>
      usedBytes = (await _files()).fold<int>(0, (s, e) => s + e.size);

  Future<bool> _remove(File f) async {
    try {
      await _delete(f);
      return true;
    } on PathNotFoundException {
      return true; // already gone
    } on FileSystemException catch (e, st) {
      AppLog.w('stream cache: cannot delete ${f.path}', e, st);
      return false;
    }
  }
}
