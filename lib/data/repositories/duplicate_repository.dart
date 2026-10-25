import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../services/library/duplicate_finder.dart';
import '../db/app_database.dart';
import 'credits_repository.dart';

/// Reads for the duplicate search, and the merge of the user's data.
class DuplicateRepository {
  /// [onStep] is told the name of each stage of a merge just before it runs
  /// (tests throw from it to prove that nothing is left half done).
  DuplicateRepository(this._db, {this.onStep});

  final AppDatabase _db;
  final void Function(String step)? onStep;

  void _step(String name) => onStep?.call(name);

  /// Every visible track as the finder sees it. Plain SQL: the typed API
  /// costs ~15 µs per row, which is most of the time at 50 000 tracks.
  Future<List<DupEntry>> entries() async {
    final rows = await _db
        .customSelect(
          'SELECT id, path, title, artist, duration_ms, format, size_bytes, '
          'bitrate_kbps, sample_rate_hz, bit_depth, has_cover, user_edited, '
          'added_at, sha256 FROM tracks WHERE missing = 0 AND ignored = 0 AND kind = 0',
          readsFrom: {_db.tracks},
        )
        .get();
    return [
      for (final r in rows)
        DupEntry(
          id: r.data['id']! as int,
          path: r.data['path']! as String,
          title: (r.data['title'] as String?) ?? '',
          artist: r.data['artist'] as String?,
          durationMs: (r.data['duration_ms'] as int?) ?? 0,
          format: (r.data['format'] as String?) ?? '',
          sizeBytes: (r.data['size_bytes'] as int?) ?? 0,
          bitrateKbps: r.data['bitrate_kbps'] as int?,
          sampleRateHz: r.data['sample_rate_hz'] as int?,
          bitDepth: r.data['bit_depth'] as int?,
          hasCover: (r.data['has_cover'] as int? ?? 0) != 0,
          userEdited: (r.data['user_edited'] as int? ?? 0) != 0,
          addedAt: (r.data['added_at'] as int?) ?? 0,
          sha256: r.data['sha256'] as String?,
        ),
    ];
  }

  /// Remembers hashes so a later search does not read the files again. The
  /// scanner clears one when the file's size or time changes.
  Future<void> saveHashes(Map<int, String> hashes) async {
    if (hashes.isEmpty) return;
    await _db.transaction(() async {
      for (final e in hashes.entries) {
        await (_db.update(_db.tracks)..where((t) => t.id.equals(e.key)))
            .write(TracksCompanion(sha256: Value(e.value)));
      }
    });
  }

  /// Folds the user's data of [dropIds] into [keepId] and hides the others,
  /// all in one transaction (an error leaves everything as it was). Rows of
  /// `tracks` are never deleted: «Brani nascosti» can bring a track back.
  ///
  /// * favourite if any was; plays summed; last played = the latest;
  /// * playlists: [keepId] takes the place of the first of the group in each
  ///   playlist, the others go (no doubles, positions renumbered);
  /// * listens, tag links and import rows move to [keepId];
  /// * lyrics, curiosities, cover and the user's edits are copied only where
  ///   [keepId] has none.
  Future<void> merge(int keepId, List<int> dropIds) async {
    final drops = dropIds.toSet()..remove(keepId);
    if (drops.isEmpty) return;
    await _db.transaction(() async {
      final keep = await _row(keepId);
      final dups = <Track>[];
      for (final id in dropIds) {
        if (id == keepId || dups.any((d) => d.id == id)) continue;
        dups.add(await _row(id));
      }
      _step('tracks');
      await _mergeTrackFields(keep, dups);
      _step('playlists');
      await _mergePlaylists(keepId, drops);
      _step('plays');
      await _db.customUpdate(
        'UPDATE plays SET track_id = ? WHERE track_id IN (${_marks(drops)})',
        variables: [Variable<int>(keepId), ..._vars(drops)],
        updates: {_db.plays},
      );
      _step('tags');
      await _db.customUpdate(
        'INSERT OR IGNORE INTO track_tags (track_id, tag_id) '
        'SELECT ?, tag_id FROM track_tags WHERE track_id IN (${_marks(drops)})',
        variables: [Variable<int>(keepId), ..._vars(drops)],
        updates: {_db.trackTags},
      );
      await _db.customUpdate(
        'DELETE FROM track_tags WHERE track_id IN (${_marks(drops)})',
        variables: _vars(drops),
        updates: {_db.trackTags},
      );
      _step('imports');
      await _db.customUpdate(
        'UPDATE playlist_import_items SET track_id = ? '
        'WHERE track_id IN (${_marks(drops)})',
        variables: [Variable<int>(keepId), ..._vars(drops)],
        updates: {_db.playlistImportItems},
      );
      _step('credits');
      await CreditsRepository(_db).moveInto(keepId, drops);
      _step('hide');
      await (_db.update(_db.tracks)..where((t) => t.id.isIn(drops)))
          .write(const TracksCompanion(ignored: Value(true)));
    });
  }

  Future<Track> _row(int id) =>
      (_db.select(_db.tracks)..where((t) => t.id.equals(id))).getSingle();

  Future<void> _mergeTrackFields(Track keep, List<Track> dups) async {
    String? firstOf(String? Function(Track) pick) =>
        pick(keep) ?? dups.map(pick).whereType<String>().firstOrNull;
    final lastPlayed = [keep, ...dups]
        .map((t) => t.lastPlayedAt)
        .whereType<int>()
        .fold<int?>(null, (a, b) => a == null || b > a ? b : a);
    // The user's edits travel only when the kept track has none of its own.
    final edited = keep.userEdited
        ? null
        : dups.where((d) => d.userEdited).firstOrNull;
    final coverFrom = keep.hasCover
        ? null
        : dups.where((d) => d.hasCover && d.coverKey != null).firstOrNull;
    await (_db.update(_db.tracks)..where((t) => t.id.equals(keep.id))).write(
      TracksCompanion(
        isFavorite: Value(keep.isFavorite || dups.any((d) => d.isFavorite)),
        playCount:
            Value(keep.playCount + dups.fold<int>(0, (n, d) => n + d.playCount)),
        lastPlayedAt: Value(lastPlayed),
        lyricsPlain: Value(firstOf((t) => t.lyricsPlain)),
        lyricsSynced: Value(firstOf((t) => t.lyricsSynced)),
        curiosities: Value(firstOf((t) => t.curiosities)),
        hasCover: coverFrom == null ? const Value.absent() : const Value(true),
        coverKey: coverFrom == null
            ? const Value.absent()
            : Value(coverFrom.coverKey),
        userEdited: edited == null ? const Value.absent() : const Value(true),
        title: edited == null ? const Value.absent() : Value(edited.title),
        artist: edited == null ? const Value.absent() : Value(edited.artist),
        album: edited == null ? const Value.absent() : Value(edited.album),
        albumArtist:
            edited == null ? const Value.absent() : Value(edited.albumArtist),
        albumKey: edited == null ? const Value.absent() : Value(edited.albumKey),
        year: edited == null ? const Value.absent() : Value(edited.year),
        trackNumber:
            edited == null ? const Value.absent() : Value(edited.trackNumber),
        genre: edited == null ? const Value.absent() : Value(edited.genre),
      ),
    );
  }

  /// In every playlist that holds any of the group, [keepId] takes the place
  /// of the first one and the rest leave; positions are renumbered.
  Future<void> _mergePlaylists(int keepId, Set<int> drops) async {
    final group = {keepId, ...drops};
    final lists = await (_db.selectOnly(_db.playlistTracks, distinct: true)
          ..addColumns([_db.playlistTracks.playlistId])
          ..where(_db.playlistTracks.trackId.isIn(group)))
        .map((r) => r.read(_db.playlistTracks.playlistId)!)
        .get();
    for (final playlistId in lists) {
      final rows = await (_db.select(_db.playlistTracks)
            ..where((t) => t.playlistId.equals(playlistId))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();
      final order = <int>[];
      var placed = false;
      for (final r in rows) {
        if (!group.contains(r.trackId)) {
          order.add(r.trackId);
        } else if (!placed) {
          order.add(keepId);
          placed = true;
        }
      }
      await (_db.delete(_db.playlistTracks)
            ..where((t) =>
                t.playlistId.equals(playlistId) & t.trackId.isIn(group)))
          .go();
      await _db.into(_db.playlistTracks).insert(PlaylistTracksCompanion.insert(
          playlistId: playlistId, trackId: keepId, position: order.length));
      for (var i = 0; i < order.length; i++) {
        await (_db.update(_db.playlistTracks)
              ..where((t) =>
                  t.playlistId.equals(playlistId) &
                  t.trackId.equals(order[i])))
            .write(PlaylistTracksCompanion(position: Value(i)));
      }
      // The playlist changed: a sync must see it.
      await (_db.update(_db.playlists)..where((p) => p.id.equals(playlistId)))
          .write(PlaylistsCompanion(updatedAt: Value(nowMs())));
    }
  }

  String _marks(Set<int> ids) => List.filled(ids.length, '?').join(',');
  List<Variable> _vars(Set<int> ids) => [for (final i in ids) Variable<int>(i)];
}
