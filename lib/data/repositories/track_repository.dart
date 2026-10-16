import 'package:drift/drift.dart';

import '../../core/import_row.dart';
import '../../services/library/rules/rule_ast.dart';
import '../../services/library/rules/rule_sql.dart';
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
          replayGainDb: row.replayGainDb,
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

  /// The `ORDER BY` of [sort] in SQL (the same orders as [watchTracks]), or a
  /// shuffle that stays the same for a given [randomSeed].
  static String _orderSql(SortOption sort, int? randomSeed, {bool mostPlayed = false}) {
    if (mostPlayed) {
      return 'play_count DESC, COALESCE(last_played_at, 0) DESC, title COLLATE NOCASE';
    }
    if (randomSeed != null) {
      // Not linear in the id (a seed would only rotate the order).
      final s = randomSeed.abs() % 1000003;
      return '(((((id + $s) * (id + $s)) % 1000003) * 104729) + id * 7919) % 1000003, id';
    }
    return switch (sort) {
      SortOption.title => 'title COLLATE NOCASE',
      SortOption.artist => 'artist COLLATE NOCASE, title COLLATE NOCASE',
      SortOption.album =>
        'album COLLATE NOCASE, disc_number, track_number',
      SortOption.year => 'year DESC, title COLLATE NOCASE',
      SortOption.addedAt => 'added_at DESC',
      SortOption.duration => 'duration_ms DESC',
      SortOption.defaultOrder =>
        'album_key, disc_number, track_number, title COLLATE NOCASE',
    };
  }

  ({String sql, List<Variable> vars}) _byRules(
    RuleExpr rules,
    SortOption sort,
    int? limit,
    int? randomSeed,
    int nowMs, {
    bool mostPlayed = false,
  }) {
    final q = toSql(rules, nowMs: nowMs);
    final vars = [...q.vars];
    final lim = limit == null ? '' : ' LIMIT ?';
    if (limit != null) vars.add(Variable<int>(limit));
    return (
      sql: 'SELECT * FROM tracks WHERE ${q.where} '
          'ORDER BY ${_orderSql(sort, randomSeed, mostPlayed: mostPlayed)}$lim',
      vars: vars,
    );
  }

  Set<TableInfo> get _ruleTables => {_db.tracks, _db.trackTags, _db.userTags};

  /// Tracks matching [rules] (the rule language of the search and of the smart
  /// playlists), kept up to date. «Added» terms count back from [now] at the
  /// time of the call.
  Stream<List<Track>> watchByRules(
    RuleExpr rules, {
    SortOption sort = SortOption.defaultOrder,
    int? limit,
    int? randomSeed,
    bool mostPlayed = false,
    DateTime? now,
  }) {
    final q = _byRules(rules, sort, limit, randomSeed,
        (now ?? DateTime.now()).millisecondsSinceEpoch,
        mostPlayed: mostPlayed);
    return _db
        .customSelect(q.sql, variables: q.vars, readsFrom: _ruleTables)
        .watch()
        .map((rows) => [for (final r in rows) _db.tracks.map(r.data)]);
  }

  Future<List<Track>> tracksByRules(
    RuleExpr rules, {
    SortOption sort = SortOption.defaultOrder,
    int? limit,
    int? randomSeed,
    DateTime? now,
  }) async {
    final q = _byRules(rules, sort, limit, randomSeed,
        (now ?? DateTime.now()).millisecondsSinceEpoch);
    final rows = await _db
        .customSelect(q.sql, variables: q.vars, readsFrom: _ruleTables)
        .get();
    return [for (final r in rows) _db.tracks.map(r.data)];
  }

  /// How many tracks match (for the «37 brani» of the editor).
  Future<int> countByRules(RuleExpr rules, {DateTime? now}) async {
    final q = toSql(rules, nowMs: (now ?? DateTime.now()).millisecondsSinceEpoch);
    final rows = await _db
        .customSelect('SELECT COUNT(*) AS n FROM tracks WHERE ${q.where}',
            variables: q.vars, readsFrom: _ruleTables)
        .get();
    return rows.single.read<int>('n');
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

  Future<void> registerPlay(int id) async {
    await _db.customUpdate(
      'UPDATE tracks SET play_count = play_count + 1, last_played_at = ? WHERE id = ?',
      variables: [
        Variable.withInt(DateTime.now().millisecondsSinceEpoch),
        Variable.withInt(id),
      ],
      updates: {_db.tracks},
    );
  }

  /// Where a long track was left (see `resumePointFor`); null clears it.
  Future<void> setResumePosition(int id, int? ms) =>
      (_db.update(_db.tracks)..where((t) => t.id.equals(id)))
          .write(TracksCompanion(resumePositionMs: Value(ms)));

  Stream<List<Track>> watchMissing() =>
      (_db.select(_db.tracks)
            ..where((t) => t.missing.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.path)]))
          .watch();

  Future<void> deleteTrack(int id) =>
      (_db.delete(_db.tracks)..where((t) => t.id.equals(id))).go();

  /// Forgets cover info and forces the next scan to re-read every file.
  Future<void> resetCovers() => _db.update(_db.tracks).write(
      const TracksCompanion(
          hasCover: Value(false), coverKey: Value(null), mtimeMs: Value(0)));

  /// Id, title, artist and length of every available track, for matching an
  /// imported playlist against the library without loading whole rows.
  Future<List<LibraryEntryLite>> liteEntries() async {
    // Plain SQL: the typed query API costs ~15 µs per row, which is most of
    // the time at 50 000 tracks.
    final rows = await _db
        .customSelect(
          'SELECT id, title, artist, duration_ms, path FROM tracks '
          'WHERE missing = 0',
          readsFrom: {_db.tracks},
        )
        .get();
    return [
      for (final r in rows)
        LibraryEntryLite(
          id: r.data['id']! as int,
          title: (r.data['title'] as String?) ?? '',
          artist: r.data['artist'] as String?,
          durationMs: (r.data['duration_ms'] as int?) ?? 0,
          path: r.data['path'] as String?,
        ),
    ];
  }

  Future<int?> idForPath(String path) async {
    final t = await (_db.select(_db.tracks)..where((r) => r.path.equals(path)))
        .getSingleOrNull();
    return t?.id;
  }

  Future<void> setFavorite(int id, bool value) =>
      (_db.update(_db.tracks)..where((t) => t.id.equals(id)))
          .write(TracksCompanion(isFavorite: Value(value)));

  /// Sets the favourite flag of many tracks in one transaction.
  Future<void> setFavoriteMany(List<int> ids, bool value) async {
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      for (final chunk in _chunks(ids, 500)) {
        await (_db.update(_db.tracks)..where((t) => t.id.isIn(chunk))).write(
            TracksCompanion(isFavorite: Value(value)));
      }
    });
  }

  /// Forgets library rows, but only those whose file is gone (`missing`): a
  /// track that is still there is never touched. Returns how many went.
  Future<int> deleteMissingTracks(List<int> ids) async {
    if (ids.isEmpty) return 0;
    return _db.transaction(() async {
      var removed = 0;
      for (final chunk in _chunks(ids, 500)) {
        removed += await (_db.delete(_db.tracks)
              ..where((t) => t.id.isIn(chunk) & t.missing.equals(true)))
            .go();
      }
      return removed;
    });
  }

  Stream<Track?> watchById(int id) =>
      (_db.select(_db.tracks)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

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
