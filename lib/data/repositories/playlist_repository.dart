import 'package:drift/drift.dart';

import '../db/app_database.dart';

class PlaylistSummary {
  const PlaylistSummary(this.playlist, this.trackCount);

  final Playlist playlist;
  final int trackCount;
}

class PlaylistRepository {
  PlaylistRepository(this._db);

  final AppDatabase _db;

  Future<int> create(String name) => _db.into(_db.playlists).insert(
      PlaylistsCompanion.insert(
          name: name.trim(),
          createdAt: DateTime.now().millisecondsSinceEpoch));

  Future<void> rename(int id, String name) =>
      (_db.update(_db.playlists)..where((p) => p.id.equals(id)))
          .write(PlaylistsCompanion(name: Value(name.trim())));

  Future<void> delete(int id) =>
      (_db.delete(_db.playlists)..where((p) => p.id.equals(id))).go();

  Stream<List<PlaylistSummary>> watchAll() {
    return _db
        .customSelect(
          'SELECT p.id, p.name, p.created_at, COUNT(pt.track_id) AS n '
          'FROM playlists p LEFT JOIN playlist_tracks pt ON pt.playlist_id = p.id '
          'GROUP BY p.id ORDER BY p.name COLLATE NOCASE',
          readsFrom: {_db.playlists, _db.playlistTracks},
        )
        .watch()
        .map((rows) => [
              for (final r in rows)
                PlaylistSummary(
                  Playlist(
                    id: r.read<int>('id'),
                    name: r.read<String>('name'),
                    createdAt: r.read<int>('created_at'),
                  ),
                  r.read<int>('n'),
                ),
            ]);
  }

  Stream<List<Track>> watchTracks(int playlistId) {
    final q = _db.select(_db.playlistTracks).join([
      innerJoin(_db.tracks, _db.tracks.id.equalsExp(_db.playlistTracks.trackId)),
    ])
      ..where(_db.playlistTracks.playlistId.equals(playlistId) &
          _db.tracks.missing.equals(false))
      ..orderBy([OrderingTerm.asc(_db.playlistTracks.position)]);
    return q.watch().map((rows) => [for (final r in rows) r.readTable(_db.tracks)]);
  }

  /// Returns how many tracks were actually added (duplicates are ignored).
  Future<int> addTracks(int playlistId, List<int> trackIds) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.playlistTracks)
            ..where((t) => t.playlistId.equals(playlistId)))
          .get();
      final have = existing.map((e) => e.trackId).toSet();
      var next = existing.isEmpty
          ? 0
          : existing.map((e) => e.position).reduce((a, b) => a > b ? a : b) + 1;
      var added = 0;
      for (final id in trackIds) {
        if (!have.add(id)) continue;
        await _db.into(_db.playlistTracks).insert(PlaylistTracksCompanion.insert(
            playlistId: playlistId, trackId: id, position: next++));
        added++;
      }
      return added;
    });
  }

  Future<void> removeTrack(int playlistId, int trackId) =>
      _db.transaction(() async {
        await (_db.delete(_db.playlistTracks)
              ..where((t) =>
                  t.playlistId.equals(playlistId) & t.trackId.equals(trackId)))
            .go();
        await _renumber(playlistId);
      });

  /// Indices refer to the displayed order; `newIndex` is the final position.
  Future<void> reorder(int playlistId, int oldIndex, int newIndex) =>
      _db.transaction(() async {
        final rows = await (_db.select(_db.playlistTracks)
              ..where((t) => t.playlistId.equals(playlistId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
        if (oldIndex < 0 || oldIndex >= rows.length) return;
        final ids = rows.map((r) => r.trackId).toList();
        final moved = ids.removeAt(oldIndex);
        ids.insert(newIndex.clamp(0, ids.length), moved);
        await _writeOrder(playlistId, ids);
      });

  Future<void> _renumber(int playlistId) async {
    final rows = await (_db.select(_db.playlistTracks)
          ..where((t) => t.playlistId.equals(playlistId))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    await _writeOrder(playlistId, rows.map((r) => r.trackId).toList());
  }

  Future<void> _writeOrder(int playlistId, List<int> ids) async {
    for (var i = 0; i < ids.length; i++) {
      await (_db.update(_db.playlistTracks)
            ..where((t) =>
                t.playlistId.equals(playlistId) & t.trackId.equals(ids[i])))
          .write(PlaylistTracksCompanion(position: Value(i)));
    }
  }
}
