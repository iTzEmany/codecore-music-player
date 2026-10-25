import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/import_row.dart';
import '../../core/text_utils.dart';
import '../../services/share/track_meta.dart';
import '../../services/library/rules/rule_ast.dart';
import '../../services/library/rules/rule_sql.dart';
import '../../services/online/youtube_service.dart' show YtResult;
import '../db/app_database.dart';
import 'light_tracks.dart';
import 'track_kinds.dart';

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
        final existing = await (_db.select(
          _db.tracks,
        )..where((t) => t.path.equals(path))).getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.tracks).insert(row);
          continue;
        }
        final keepText = existing.userEdited;
        final keepCover =
            keepText && !(row.hasCover.present && row.hasCover.value);
        // A hash of the old bytes says nothing about the new ones.
        final changed =
            existing.sizeBytes != row.sizeBytes.value ||
            existing.mtimeMs != row.mtimeMs.value;
        await (_db.update(
          _db.tracks,
        )..where((t) => t.id.equals(existing.id))).write(
          TracksCompanion(
            folderId: row.folderId,
            title: keepText ? const Value.absent() : row.title,
            artist: keepText ? const Value.absent() : row.artist,
            albumArtist: keepText ? const Value.absent() : row.albumArtist,
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
            // An edited row keeps the cover it was given when the scan finds none.
            hasCover: keepCover ? const Value.absent() : row.hasCover,
            coverKey: keepCover ? const Value.absent() : row.coverKey,
            replayGainDb: row.replayGainDb,
            isrc: (existing.isrc ?? '').isEmpty
                ? row.isrc
                : const Value.absent(),
            missing: const Value(false),
            sha256: changed ? const Value(null) : const Value.absent(),
          ),
        );
      }
    });
  }

  /// The shadow row of the streamed track [key], if it has one.
  Future<Track?> streamRow(String key) => byPath('stream:$key');

  /// Creates or refreshes the shadow row (`kind = 2`) of the streamed track
  /// [key] whose cached [file] is ready; one row per key. Returns its id.
  Future<int> upsertStreamRow(String key, YtResult r, File file) async {
    final stat = await file.stat();
    final artist = r.artists.isEmpty ? r.channel : r.artists.join(', ');
    final path = 'stream:$key';
    final row = TracksCompanion.insert(
      path: path,
      title: r.title,
      // Own key per stream: never shares (or overwrites) a library album's cover.
      albumKey: 'stream|$key',
      format: p.extension(file.path).replaceFirst('.', '').toLowerCase(),
      sizeBytes: stat.size,
      mtimeMs: stat.modified.millisecondsSinceEpoch,
      addedAt: DateTime.now().millisecondsSinceEpoch,
      artist: Value(artist),
      album: Value(r.album),
      durationMs: Value(r.duration?.inMilliseconds ?? 0),
      kind: const Value(kStreamKind),
    );
    return _db.transaction(() async {
      final existing = await byPath(path);
      if (existing == null) return _db.into(_db.tracks).insert(row);
      await (_db.update(_db.tracks)..where((t) => t.id.equals(existing.id)))
          .write(TracksCompanion(
        sizeBytes: row.sizeBytes,
        mtimeMs: row.mtimeMs,
        format: row.format,
        missing: const Value(false),
      ));
      return existing.id;
    });
  }

  Future<Track?> byPath(String path) =>
      (_db.select(_db.tracks)..where((t) => t.path.equals(path))).getSingleOrNull();

  /// Writes the non-null fields of a received [TrackMeta] over the row (the
  /// sender's package wins over the local tags), recomputes `albumKey` and
  /// sets `userEdited` so a rescan keeps title, artist and album.
  /// `enrichStatus` is not applied: the receiver judges its own enrichment.
  /// shortcut: year/genre/numbers come back from the file on a rescan if it
  /// changes outside Codecore; fixed by writing tags (37.4).
  /// Returns the new `albumKey`, or null when the row does not exist.
  Future<String?> applyReceivedMeta(int trackId, TrackMeta m) async {
    final t = await (_db.select(_db.tracks)..where((r) => r.id.equals(trackId))).getSingleOrNull();
    if (t == null) return null;
    final albumArtist = m.albumArtist ?? t.albumArtist;
    final artist = m.artist ?? t.artist;
    final album = m.album ?? t.album;
    final key = computeAlbumKey(
      albumArtist: albumArtist,
      artist: artist,
      album: album,
      directory: p.dirname(t.path),
    );
    await (_db.update(_db.tracks)..where((r) => r.id.equals(trackId))).write(
      TracksCompanion(
        title: Value(m.title ?? t.title),
        artist: Value(artist),
        albumArtist: Value(albumArtist),
        album: Value(album),
        albumKey: Value(key),
        year: Value(m.year ?? t.year),
        genre: Value(m.genre ?? t.genre),
        trackNumber: Value(m.trackNumber ?? t.trackNumber),
        discNumber: Value(m.discNumber ?? t.discNumber),
        isrc: Value(m.isrc ?? t.isrc),
        lyricsPlain: Value(m.lyricsPlain ?? t.lyricsPlain),
        lyricsSynced: Value(m.lyricsSynced ?? t.lyricsSynced),
        userEdited: const Value(true),
      ),
    );
    return key;
  }

  Future<Map<String, ({int size, int mtime})>> fileIndexForFolder(
    int folderId,
  ) async {
    final rows = await (_db.select(
      _db.tracks,
    )..where((t) => t.folderId.equals(folderId))).get();
    return {
      for (final r in rows) r.path: (size: r.sizeBytes, mtime: r.mtimeMs),
    };
  }

  Future<Set<String>> missingPathsForFolder(int folderId) async {
    final rows =
        await (_db.select(_db.tracks)..where(
              (t) => t.folderId.equals(folderId) & t.missing.equals(true),
            ))
            .get();
    return rows.map((r) => r.path).toSet();
  }

  Future<void> markMissing(Set<String> paths, bool missing) async {
    if (paths.isEmpty) return;
    await _db.transaction(() async {
      for (final chunk in _chunks(paths.toList(), 500)) {
        await (_db.update(_db.tracks)..where((t) => t.path.isIn(chunk))).write(
          TracksCompanion(missing: Value(missing)),
        );
      }
    });
  }

  Future<void> setCoverForAlbum(
    String albumKey,
    bool hasCover,
    String? coverKey,
  ) async {
    await (_db.update(
      _db.tracks,
    )..where((t) => t.albumKey.equals(albumKey))).write(
      TracksCompanion(hasCover: Value(hasCover), coverKey: Value(coverKey)),
    );
  }

  Stream<List<Track>> watchTracks({
    String query = '',
    SortOption sort = SortOption.defaultOrder,
    bool favoritesOnly = false,
  }) {
    final q = _db.select(_db.tracks)
      ..where((t) {
        Expression<bool> cond =
            t.missing.equals(false) &
            t.ignored.equals(false) &
            t.kind.equals(0);
        if (favoritesOnly) cond = cond & t.isFavorite.equals(true);
        final text = query.trim();
        if (text.isNotEmpty) {
          final pattern = '%${_escapeLike(text)}%';
          cond =
              cond &
              (t.title.like(pattern, escapeChar: r'\') |
                  t.artist.like(pattern, escapeChar: r'\') |
                  t.album.like(pattern, escapeChar: r'\'));
        }
        return cond;
      })
      ..orderBy(_orderFor(sort));
    return lightSelect(_db, q).watch();
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
  static String _orderSql(
    SortOption sort,
    int? randomSeed, {
    bool mostPlayed = false,
  }) {
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
      SortOption.album => 'album COLLATE NOCASE, disc_number, track_number',
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
      sql:
          'SELECT ${lightTrackColumns(_db)} FROM tracks WHERE ${q.where} '
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
    final q = _byRules(
      rules,
      sort,
      limit,
      randomSeed,
      (now ?? DateTime.now()).millisecondsSinceEpoch,
      mostPlayed: mostPlayed,
    );
    return _db
        .customSelect(q.sql, variables: q.vars, readsFrom: _ruleTables)
        .watch()
        .map((rows) => [for (final r in rows) _db.tracks.map(r.data)]);
  }

  /// How many tracks match (for the «37 brani» of the editor).
  Future<int> countByRules(RuleExpr rules, {DateTime? now}) async {
    final q = toSql(
      rules,
      nowMs: (now ?? DateTime.now()).millisecondsSinceEpoch,
    );
    final rows = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM tracks WHERE ${q.where}',
          variables: q.vars,
          readsFrom: _ruleTables,
        )
        .get();
    return rows.single.read<int>('n');
  }

  Future<Track?> getById(int id) =>
      (_db.select(_db.tracks)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// The visible tracks of the albums [keys], album by album, in album order.
  Future<List<Track>> tracksOfAlbums(Iterable<String> keys) =>
      _db.transaction(() async {
        final out = <Track>[];
        for (final key in keys) {
          out.addAll(
            await (_db.select(_db.tracks)
                  ..where(
                    (t) =>
                        t.albumKey.equals(key) &
                        t.missing.equals(false) &
                        t.ignored.equals(false) &
                        t.kind.equals(0),
                  )
                  ..orderBy([
                    (t) => OrderingTerm.asc(t.discNumber),
                    (t) => OrderingTerm.asc(t.trackNumber),
                  ]))
                .get(),
          );
        }
        return out;
      });

  /// [getByIds] as list rows (without the long texts): for the play queue.
  Future<List<Track>> getByIdsLight(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await lightSelect(
      _db,
      _db.select(_db.tracks)..where((t) => t.id.isIn(ids)),
    ).get();
    final byId = {for (final r in rows) r.id: r};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<List<Track>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(
      _db.tracks,
    )..where((t) => t.id.isIn(ids))).get();
    final byId = {for (final r in rows) r.id: r};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
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
      (_db.update(_db.tracks)..where((t) => t.id.equals(id))).write(
        TracksCompanion(resumePositionMs: Value(ms)),
      );

  /// The length the player measured (an episode's tags or feed can be wrong).
  Future<void> setDurationMs(int id, int ms) =>
      (_db.update(_db.tracks)..where((t) => t.id.equals(id))).write(
        TracksCompanion(durationMs: Value(ms)),
      );

  /// Hides or shows tracks (the duplicates a merge leaves behind). The
  /// scanner never touches the flag, so a hidden file stays hidden.
  Future<void> setIgnored(Set<int> ids, bool value) async {
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      for (final chunk in _chunks(ids.toList(), 500)) {
        await (_db.update(_db.tracks)..where((t) => t.id.isIn(chunk))).write(
          TracksCompanion(ignored: Value(value)),
        );
      }
    });
  }

  Stream<List<Track>> watchIgnored() =>
      (_db.select(_db.tracks)
            ..where((t) => t.ignored.equals(true) & t.kind.isNotValue(kStreamKind))
            ..orderBy([
              (t) => OrderingTerm(expression: t.title.collate(Collate.noCase)),
            ]))
          .watch();

  /// Tracks left in the middle, newest first (the Home «Riprendi» rows).
  Stream<List<Track>> watchResumable({int limit = 3}) =>
      (_db.select(_db.tracks)
            ..where(
              (t) =>
                  t.resumePositionMs.isNotNull() &
                  t.missing.equals(false) &
                  t.ignored.equals(false) &
                  t.kind.equals(0),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
            ..limit(limit))
          .watch();

  Stream<List<Track>> watchMissing() =>
      (_db.select(_db.tracks)
            ..where((t) =>
                t.missing.equals(true) &
                t.ignored.equals(false) &
                t.kind.isNotValue(kStreamKind))
            ..orderBy([(t) => OrderingTerm.asc(t.path)]))
          .watch();

  Future<void> deleteTrack(int id) =>
      (_db.delete(_db.tracks)..where((t) => t.id.equals(id))).go();

  /// Forgets cover info and forces the next scan to re-read every file.
  Future<void> resetCovers() => _db
      .update(_db.tracks)
      .write(
        const TracksCompanion(
          hasCover: Value(false),
          coverKey: Value(null),
          mtimeMs: Value(0),
        ),
      );

  /// Id, title, artist and length of every available track, for matching an
  /// imported playlist against the library without loading whole rows.
  Future<List<LibraryEntryLite>> liteEntries() async {
    // Plain SQL: the typed query API costs ~15 µs per row, which is most of
    // the time at 50 000 tracks.
    final rows = await _db
        .customSelect(
          'SELECT id, title, artist, duration_ms, path FROM tracks '
          'WHERE missing = 0 AND ignored = 0 AND kind = 0',
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
    final t = await (_db.select(
      _db.tracks,
    )..where((r) => r.path.equals(path))).getSingleOrNull();
    return t?.id;
  }

  Future<void> setFavorite(int id, bool value) =>
      (_db.update(_db.tracks)..where((t) => t.id.equals(id))).write(
        TracksCompanion(isFavorite: Value(value)),
      );

  /// Stores the lyrics of one track; a missing synced version clears the column.
  Future<void> setLyrics(int id, {String? plain, String? synced}) =>
      (_db.update(_db.tracks)..where((t) => t.id.equals(id))).write(
        TracksCompanion(lyricsPlain: Value(plain), lyricsSynced: Value(synced)),
      );

  /// Stores the «curiosities» text of one track (null clears it).
  Future<void> setCuriosities(int id, String? text) =>
      (_db.update(_db.tracks)..where((t) => t.id.equals(id))).write(
        TracksCompanion(curiosities: Value(text)),
      );

  /// Sets the favourite flag of many tracks in one transaction.
  Future<void> setFavoriteMany(List<int> ids, bool value) async {
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      for (final chunk in _chunks(ids, 500)) {
        await (_db.update(_db.tracks)..where((t) => t.id.isIn(chunk))).write(
          TracksCompanion(isFavorite: Value(value)),
        );
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
        removed += await (_db.delete(
          _db.tracks,
        )..where((t) => t.id.isIn(chunk) & t.missing.equals(true))).go();
      }
      return removed;
    });
  }

  /// Deletes library rows whatever their state (the caller has already made
  /// sure the files are gone). Playlist entries, history and tags go with them
  /// (cascade). Returns how many rows went.
  Future<int> deleteTracks(List<int> ids) async {
    if (ids.isEmpty) return 0;
    return _db.transaction(() async {
      var removed = 0;
      for (final chunk in _chunks(ids, 500)) {
        removed += await (_db.delete(
          _db.tracks,
        )..where((t) => t.id.isIn(chunk))).go();
      }
      return removed;
    });
  }

  Stream<Track?> watchById(int id) => (_db.select(
    _db.tracks,
  )..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// How many music tracks there are (podcast episodes are not counted).
  Future<int> countAll() async {
    final c = _db.tracks.id.count();
    final row =
        await (_db.selectOnly(_db.tracks)
              ..addColumns([c])
              ..where(_db.tracks.kind.equals(0)))
            .getSingle();
    return row.read(c) ?? 0;
  }

  /// Live [countAll].
  Stream<int> watchCount() {
    final c = _db.tracks.id.count();
    return (_db.selectOnly(_db.tracks)
          ..addColumns([c])
          ..where(_db.tracks.kind.equals(0)))
        .watchSingle()
        .map((r) => r.read(c) ?? 0);
  }

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  static Iterable<List<T>> _chunks<T>(List<T> list, int size) sync* {
    for (var i = 0; i < list.length; i += size) {
      yield list.sublist(i, i + size > list.length ? list.length : i + size);
    }
  }
}
