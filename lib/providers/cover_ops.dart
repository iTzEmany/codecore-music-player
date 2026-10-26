import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/app_log.dart';
import '../data/repositories/track_repository.dart';
import '../services/covers/cover_store.dart';
import '../services/scanner/library_scanner.dart';
import 'database_providers.dart';
import 'library_providers.dart';
import 'playlist_ops.dart';

final coverOpsProvider = Provider<CoverOps>((ref) => CoverOps(ref));

/// Hand-picked covers: save a new one (the previous hand-picked file goes, the
/// original `sha1(albumKey)` never) and go back to the original.
class CoverOps {
  CoverOps(this._ref);

  final Ref _ref;

  TrackRepository get _tracks => _ref.read(trackRepositoryProvider);
  CoverStore get _store => _ref.read(coverStoreProvider);
  LibraryScanner get _scanner => _ref.read(libraryScannerProvider);

  /// A new key per pick, so the image cache never shows the old picture.
  Future<String?> _save(String kind, Object id, List<int> bytes, String? mime) =>
      _store.saveFromBytes('manual:$kind:$id:${DateTime.now().microsecondsSinceEpoch}', bytes, mime);

  /// Deletes hand-picked files (never an original: callers pass only keys of rows
  /// with `cover_source > 0`) and their thumbnails, once no row uses them.
  Future<void> _drop(Iterable<String?> keys) async {
    for (final key in keys.whereType<String>().toSet()) {
      if (await _tracks.countWithCoverKey(key) > 0) continue;
      try {
        await _store.fileFor(key)?.delete();
        final thumb = File(p.join(_store.dir.path, CoverStore.thumbName(key)));
        if (await thumb.exists()) await thumb.delete();
      } on Object catch (e, st) {
        AppLog.w('old cover not deleted: $key', e, st);
      }
    }
  }

  /// Returns false when nothing was saved (empty or too large).
  Future<bool> setTrackCover(int trackId, List<int> bytes, String? mime) async {
    final key = await _save('track', trackId, bytes, mime);
    if (key == null) return false;
    final before = await _tracks.getById(trackId);
    final old = (before?.coverSource ?? 0) > 0 ? before?.coverKey : null;
    await _tracks.setManualCover(trackId, key);
    await _drop([old]);
    return true;
  }

  Future<bool> setAlbumCover(String albumKey, List<int> bytes, String? mime) async {
    final key = await _save('album', albumKey, bytes, mime);
    if (key == null) return false;
    final old = (await _tracks.albumManualRow(albumKey))?.coverKey;
    await _tracks.setManualAlbumCover(albumKey, key);
    await _drop([old]);
    return true;
  }

  Future<bool> setPlaylistCover(int playlistId, List<int> bytes, String? mime) async {
    final key = await _save('playlist', playlistId, bytes, mime);
    if (key == null) return false;
    final old = (await _ref.read(playlistsProvider.future))
        .where((s) => s.playlist.id == playlistId)
        .firstOrNull
        ?.playlist
        .coverKey;
    await _ref.read(playlistOpsProvider).setCover(playlistId, key);
    // Playlist covers are never shared with tracks: delete the old file as before.
    if (old != null) await _store.fileFor(old)?.delete();
    return true;
  }

  Future<void> restoreTrackCover(int trackId) async {
    final t = await _tracks.getById(trackId);
    if (t == null || t.coverSource == 0) return;
    final key = await _scanner.originalCoverKey(t.albumKey, t.path);
    await _tracks.restoreCover(trackId: trackId, coverKey: key);
    await _drop([t.coverKey]);
  }

  Future<void> restoreAlbumCover(String albumKey) async {
    final row = await _tracks.albumManualRow(albumKey);
    if (row == null) return;
    final key = await _scanner.originalCoverKey(albumKey, row.path);
    await _tracks.restoreCover(albumKey: albumKey, coverKey: key);
    await _drop([row.coverKey]);
  }
}
