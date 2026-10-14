import 'package:drift/drift.dart';

import '../db/app_database.dart';

enum SortOption { defaultOrder, title, artist, album, year, addedAt, duration }

class TrackRepository {
  TrackRepository(this._db);

  final AppDatabase _db;

  /// Inserts new rows; for existing paths only file-derived fields change, so
  /// favourites, lyrics, counters and user edits survive a rescan.
  Future<void> upsertBatch(List<TracksCompanion> rows) async {
    if (rows.isEmpty) return;
    await _db.transaction(() async {
      for (final row in rows) {
        final path = row.path.value;
        final existing = await (_db.select(_db.tracks)
              ..where((t) => t.path.equals(path)))
            .getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.tracks).insert(row);
          continue;
        }
        final keepText = existing.userEdited;
        await (_db.update(_db.tracks)..where((t) => t.id.equals(existing.id)))
            .write(TracksCompanion(
          folderId: row.folderId,
          title: keepText ? const Value.absent() : row.title,
          artist: keepText ? const Value.absent() : row.artist,
          albumArtist: row.albumArtist,
          album: keepText ? const Value.absent() : row.album,
          albumKey: keepText ? const Value.absent() : row.albumKey,
          trackNumber: row.trackNumber,
          discNumber: row.discNumber,
          year: row.year,
          genre: row.genre,
          durationMs: row.durationMs,
          format: row.format,
          sampleRateHz: row.sampleRateHz,
          bitDepth: row.bitDepth,
          bitrateKbps: row.bitrateKbps,
          channels: row.channels,
          sizeBytes: row.sizeBytes,
          mtimeMs: row.mtimeMs,
          hasCover: row.hasCover,
          coverKey: row.coverKey,
          missing: const Value(false),
        ));
      }
    });
  }

  Future<Map<String, ({int size, int mtime})>> fileIndexForFolder(
      int folderId) async {
    final rows = await (_db.select(_db.tracks)
          ..where((t) => t.folderId.equals(folderId)))
        .get();
    return {
      for (final r in rows) r.path: (size: r.sizeBytes, mtime: r.mtimeMs),
    };
  }

  Future<Set<String>> missingPathsForFolder(int folderId) async {
    final rows = await (_db.select(_db.tracks)
          ..where((t) => t.folderId.equals(folderId) & t.missing.equals(true)))
        .get();
    return rows.map((r) => r.path).toSet();
  }

  Future<void> markMissing(Set<String> paths, bool missing) async {
    if (paths.isEmpty) return;
    await _db.transaction(() async {
      for (final chunk in _chunks(paths.toList(), 500)) {
        await (_db.update(_db.tracks)..where((t) => t.path.isIn(chunk)))
            .write(TracksCompanion(missing: Value(missing)));
      }
    });
  }

  Future<void> setCoverForAlbum(
      String albumKey, bool hasCover, String? coverKey) async {
    await (_db.update(_db.tracks)..where((t) => t.albumKey.equals(albumKey)))
        .write(TracksCompanion(
            hasCover: Value(hasCover), coverKey: Value(coverKey)));
  }

  Stream<List<Track>> watchTracks({
    String query = '',
    SortOption sort = SortOption.defaultOrder,
    bool favoritesOnly = false,
  }) {
    final q = _db.select(_db.tracks)
      ..where((t) {
        Expression<bool> cond = t.missing.equals(false);
        if (favoritesOnly) cond = cond & t.isFavorite.equals(true);
        final text = query.trim();
        if (text.isNotEmpty) {
          final pattern = '%${_escapeLike(text)}%';
          cond = cond &
              (t.title.like(pattern, escapeChar: r'\') |
                  t.artist.like(pattern, escapeChar: r'\') |
                  t.album.like(pattern, escapeChar: r'\'));
        }
        return cond;
      })
      ..orderBy(_orderFor(sort));
    return q.watch();
  }

  List<OrderingTerm Function($TracksTable)> _orderFor(SortOption sort) {
    OrderingTerm nocase(Expression<String> e) =>
        OrderingTerm(expression: e.collate(Collate.noCase));
    return switch (sort) {
      SortOption.title => [(t) => nocase(t.title)],
      SortOption.artist => [(t) => nocase(t.artist), (t) => nocase(t.title)],
      SortOption.album => [
          (t) => nocase(t.album),
          (t) => OrderingTerm.asc(t.discNumber),
          (t) => OrderingTerm.asc(t.trackNumber),
        ],
      SortOption.year => [
          (t) => OrderingTerm.desc(t.year),
          (t) => nocase(t.title),
        ],
      SortOption.addedAt => [(t) => OrderingTerm.desc(t.addedAt)],
      SortOption.duration => [(t) => OrderingTerm.desc(t.durationMs)],
      SortOption.defaultOrder => [
          (t) => OrderingTerm.asc(t.albumKey),
          (t) => OrderingTerm.asc(t.discNumber),
          (t) => OrderingTerm.asc(t.trackNumber),
          (t) => nocase(t.title),
        ],
    };
  }

  Future<Track?> getById(int id) =>
      (_db.select(_db.tracks)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<Track>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(_db.tracks)..where((t) => t.id.isIn(ids)))
        .get();
    final byId = {for (final r in rows) r.id: r};
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  Future<int> countAll() async {
    final c = _db.tracks.id.count();
    final row = await (_db.selectOnly(_db.tracks)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }

  static String _escapeLike(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  static Iterable<List<T>> _chunks<T>(List<T> list, int size) sync* {
    for (var i = 0; i < list.length; i += size) {
      yield list.sublist(i, i + size > list.length ? list.length : i + size);
    }
  }
}
