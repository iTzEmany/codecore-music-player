import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import '../../core/text_utils.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/track_repository.dart';
import '../covers/cover_store.dart';
import '../tags/tag_reader.dart';

const audioExtensions = {
  'mp3', 'flac', 'wav', 'ogg', 'oga', 'opus', 'm4a', 'aac', 'aiff', 'aif',
  'wma', 'webm',
};

class ScanProgress {
  const ScanProgress({
    this.done = 0,
    this.total = 0,
    this.currentPath,
    this.finished = false,
    this.error,
  });

  const ScanProgress.failed(String message)
      : this(finished: true, error: message);

  final int done, total;
  final String? currentPath;
  final bool finished;
  final String? error;

  bool get failed => error != null;
}

class _Found {
  _Found(this.path, this.size, this.mtime);
  final String path;
  final int size, mtime;
}

class LibraryScanner {
  LibraryScanner(this._tags, this._tracks, this._covers,
      {this.useIsolate = true});

  final TagReader _tags;
  final TrackRepository _tracks;
  final CoverStore _covers;
  final bool useIsolate;

  static const _group = 50;
  static const _flushAt = 100;

  Stream<ScanProgress> scan(Folder folder) async* {
    final root = Directory(folder.path);
    if (!await root.exists()) {
      yield ScanProgress.failed('Cartella non raggiungibile: ${folder.path}');
      return;
    }
    final found = <_Found>[];
    try {
      await for (final e in root.list(recursive: true, followLinks: false)) {
        if (e is! File || _isHidden(e.path, folder.path)) continue;
        final ext = p.extension(e.path).replaceFirst('.', '').toLowerCase();
        if (!audioExtensions.contains(ext)) continue;
        try {
          final st = await e.stat();
          found.add(_Found(e.path, st.size, st.modified.millisecondsSinceEpoch));
        } on Object catch (err, st) {
          AppLog.w('stat failed: ${e.path}', err, st);
        }
      }
    } on Object catch (e, st) {
      AppLog.e('listing failed: ${folder.path}', e, st);
      yield ScanProgress.failed('Lettura cartella non riuscita: $e');
      return;
    }

    yield* _process(folder, found, markMissing: true);
  }

  /// Scans only [paths] (e.g. a freshly downloaded file); never marks
  /// anything missing.
  Stream<ScanProgress> scanFiles(Folder folder, List<String> paths) async* {
    final found = <_Found>[];
    for (final path in paths) {
      final st = await File(path).stat();
      if (st.type != FileSystemEntityType.file) continue;
      found.add(_Found(path, st.size, st.modified.millisecondsSinceEpoch));
    }
    yield* _process(folder, found, markMissing: false);
  }

  Stream<ScanProgress> _process(Folder folder, List<_Found> found,
      {required bool markMissing}) async* {
    final index = await _tracks.fileIndexForFolder(folder.id);
    final changed = found.where((f) {
      final old = index[f.path];
      return old == null || old.size != f.size || old.mtime != f.mtime;
    }).toList();

    var done = 0;
    yield ScanProgress(total: changed.length);
    final pending = <TracksCompanion>[];
    final albumCovers = <String, String?>{};

    for (var i = 0; i < changed.length; i += _group) {
      final end = i + _group > changed.length ? changed.length : i + _group;
      final batch = changed.sublist(i, end);
      final infos = await _readBatch(batch.map((f) => f.path).toList());
      for (var j = 0; j < batch.length; j++) {
        try {
          pending.add(await _toRow(folder, batch[j], infos[j], albumCovers));
        } on Object catch (e, st) {
          AppLog.e('row build failed: ${batch[j].path}', e, st);
        }
      }
      done = end;
      if (pending.length >= _flushAt) {
        await _tracks.upsertBatch(List.of(pending));
        pending.clear();
      }
      yield ScanProgress(
          done: done, total: changed.length, currentPath: batch.last.path);
    }
    if (pending.isNotEmpty) await _tracks.upsertBatch(pending);

    if (!markMissing) {
      yield ScanProgress(done: done, total: changed.length, finished: true);
      return;
    }
    final seen = {for (final f in found) f.path};
    final gone = index.keys.where((k) => !seen.contains(k)).toSet();
    await _tracks.markMissing(gone, true);
    final back = (await _tracks.missingPathsForFolder(folder.id))
        .where(seen.contains)
        .toSet();
    await _tracks.markMissing(back, false);
    yield ScanProgress(done: done, total: changed.length, finished: true);
  }

  Future<List<TagInfo>> _readBatch(List<String> paths) {
    final reader = _tags;
    if (!useIsolate) {
      return Future.wait(paths.map((path) => reader.read(path)));
    }
    return Isolate.run(
        () => Future.wait(paths.map((path) => reader.read(path))));
  }

  Future<TracksCompanion> _toRow(Folder folder, _Found f, TagInfo t,
      Map<String, String?> albumCovers) async {
    final dir = p.dirname(f.path);
    final albumKey = computeAlbumKey(
        albumArtist: t.albumArtist,
        artist: t.artist,
        album: t.album,
        directory: dir);
    String? coverKey;
    if (albumCovers.containsKey(albumKey)) {
      coverKey = albumCovers[albumKey];
    } else {
      coverKey = await _resolveCover(albumKey, dir, t);
      albumCovers[albumKey] = coverKey;
      if (coverKey != null) {
        await _tracks.setCoverForAlbum(albumKey, true, coverKey);
      }
    }
    final ext = p.extension(f.path).replaceFirst('.', '').toLowerCase();
    return TracksCompanion.insert(
      path: f.path,
      title: t.title ?? p.basenameWithoutExtension(f.path),
      albumKey: albumKey,
      format: ext,
      sizeBytes: f.size,
      mtimeMs: f.mtime,
      addedAt: DateTime.now().millisecondsSinceEpoch,
      folderId: Value(folder.id),
      artist: Value(t.artist),
      albumArtist: Value(t.albumArtist),
      album: Value(t.album),
      trackNumber: Value(t.trackNumber),
      discNumber: Value(t.discNumber),
      year: Value(t.year),
      genre: Value(t.genre),
      durationMs: Value(t.durationMs ?? 0),
      sampleRateHz: Value(t.sampleRateHz),
      bitDepth: Value(t.bitDepth),
      bitrateKbps: Value(t.bitrateKbps),
      channels: Value(t.channels),
      hasCover: Value(coverKey != null),
      coverKey: Value(coverKey),
      replayGainDb: Value(t.replayGainDb),
    );
  }

  Future<String?> _resolveCover(String albumKey, String dir, TagInfo t) async {
    final existing = CoverStore.coverKeyFor(albumKey);
    if (_covers.fileFor(existing) != null) return existing;
    final bytes = t.coverBytes;
    if (bytes != null) {
      final key = await _covers.saveFromBytes(albumKey, bytes, t.coverMime);
      if (key != null) return key;
    }
    final folderCover = await _covers.findFolderCover(dir);
    if (folderCover == null) return null;
    final data = await File(folderCover).readAsBytes();
    return _covers.saveFromBytes(
        albumKey, data, p.extension(folderCover).toLowerCase() == '.png' ? 'image/png' : 'image/jpeg');
  }

  bool _isHidden(String path, String root) {
    final rel = p.relative(path, from: root);
    return p.split(rel).any((s) => s.startsWith('.'));
  }
}
