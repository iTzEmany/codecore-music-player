import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/app_log.dart';
import '../../services/online/credits.dart';
import '../db/app_database.dart';
import 'light_tracks.dart';

/// Credits and enrichment state of tracks. Writes only `track_credits` and
/// `track_enrich`, never `tracks` (so the library list does not re-emit).
class CreditsRepository {
  CreditsRepository(this._db);

  final AppDatabase _db;

  Future<List<TrackCreditRow>> creditsOf(int trackId) => (_db.select(
    _db.trackCredits,
  )..where((c) => c.trackId.equals(trackId))).get();

  Future<TrackEnrichData?> enrichOf(int trackId) => (_db.select(
    _db.trackEnrich,
  )..where((e) => e.trackId.equals(trackId))).getSingleOrNull();

  /// Library tracks (`kind = 0`) credited to [nameKey] (a `creditNameKey`), one
  /// entry per role; a track with two roles appears twice. Name key compared as
  /// stored (made in Dart, not lower()'d by SQLite).
  Future<List<({String role, Track track})>> creditedTracks(
    String nameKey,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT c.role AS credit_role, ${lightTrackColumns(_db, alias: 't')} '
          'FROM track_credits c JOIN tracks t ON t.id = c.track_id '
          'WHERE c.name_key = ? AND t.kind = 0 AND t.missing = 0 AND t.ignored = 0 '
          'ORDER BY c.role, t.title COLLATE NOCASE',
          variables: [Variable<String>(nameKey)],
          readsFrom: {_db.tracks, _db.trackCredits},
        )
        .get();
    return [
      for (final r in rows)
        (role: r.read<String>('credit_role'), track: _db.tracks.map(r.data)),
    ];
  }

  /// Replaces every credit of [trackId] with [credits] (their `trackId` is
  /// the one given here).
  Future<void> saveCredits(int trackId, List<TrackCreditsCompanion> credits) =>
      _db.transaction(() => _replace(trackId, credits));

  /// Upserts the enrichment row; columns absent from [row] keep their value.
  Future<void> saveEnrich(TrackEnrichCompanion row) => _upsert(row);

  /// [saveCredits] and [saveEnrich] in one transaction.
  Future<void> save(
    int trackId,
    List<TrackCreditsCompanion> credits,
    TrackEnrichCompanion row,
  ) => _db.transaction(() async {
    await _replace(trackId, credits);
    await _upsert(row);
  });

  /// For the duplicate merge, inside its transaction. Credits move only when [keepId] has none (first drop with credits wins);
  /// `track_enrich` merges column by column, the keeper's value first.
  Future<void> moveInto(int keepId, Set<int> drops) async {
    final c = _db.trackCredits;
    final keepHas = await (_db.select(
      c,
    )..where((t) => t.trackId.equals(keepId))).get();
    if (keepHas.isEmpty) {
      for (final id in drops) {
        final n = await _db.customUpdate(
          'INSERT OR IGNORE INTO track_credits '
          '(track_id, name, name_key, role, source) '
          'SELECT ?, name, name_key, role, source FROM track_credits '
          'WHERE track_id = ?',
          variables: [Variable<int>(keepId), Variable<int>(id)],
          updates: {c},
        );
        if (n > 0) break;
      }
    }
    await (_db.delete(c)..where((t) => t.trackId.isIn(drops))).go();

    // Credits and the «searched, nothing» mark never coexist.
    final hasCredits =
        (await (_db.select(c)
                  ..where((t) => t.trackId.equals(keepId))
                  ..limit(1))
                .get())
            .isNotEmpty;
    final e = _db.trackEnrich;
    final rows = <TrackEnrichData>[
      for (final id in [keepId, ...drops])
        ...await (_db.select(e)..where((t) => t.trackId.equals(id))).get(),
    ];
    final keeperMark = rows
        .where((r) => r.trackId == keepId)
        .firstOrNull
        ?.creditsNoneAt;
    if (rows.length > (rows.any((r) => r.trackId == keepId) ? 1 : 0) ||
        (hasCredits && keeperMark != null)) {
      T? first<T extends Object>(T? Function(TrackEnrichData) pick) =>
          rows.map(pick).whereType<T>().firstOrNull;
      await _db
          .into(e)
          .insertOnConflictUpdate(
            TrackEnrichCompanion.insert(
              trackId: Value(keepId),
              details: Value(first((r) => r.details)),
              deezerId: Value(first((r) => r.deezerId)),
              mbid: Value(first((r) => r.mbid)),
              metaNoneAt: Value(first((r) => r.metaNoneAt)),
              lyricsNoneAt: Value(first((r) => r.lyricsNoneAt)),
              syncedNoneAt: Value(first((r) => r.syncedNoneAt)),
              curioNoneAt: Value(first((r) => r.curioNoneAt)),
              creditsNoneAt: Value(
                hasCredits ? null : first((r) => r.creditsNoneAt),
              ),
              lyricsByUser: Value(rows.any((r) => r.lyricsByUser)),
            ),
          );
    }
    await (_db.delete(e)..where((t) => t.trackId.isIn(drops))).go();
  }

  /// Credits and details as they travel (backup, share, Jam).
  Future<({List<TrackCredit> credits, TrackDetails? details})> portableOf(
    int trackId,
  ) async => (await portableOfMany([trackId]))[trackId]!;

  /// [portableOf] for many tracks in two queries; every id has an entry.
  Future<Map<int, ({List<TrackCredit> credits, TrackDetails? details})>>
  portableOfMany(Iterable<int> ids) async {
    final credits = <int, List<TrackCredit>>{};
    final details = <int, TrackDetails?>{};
    final all = ids.toSet().toList();
    // Chunks keep the IN list under SQLite's variable limit.
    for (var i = 0; i < all.length; i += 500) {
      final chunk = all.sublist(i, i + 500 > all.length ? all.length : i + 500);
      for (final c in await (_db.select(
        _db.trackCredits,
      )..where((c) => c.trackId.isIn(chunk))).get()) {
        (credits[c.trackId] ??= []).add(TrackCredit(c.name, c.role, c.source));
      }
      for (final e in await (_db.select(
        _db.trackEnrich,
      )..where((e) => e.trackId.isIn(chunk))).get()) {
        details[e.trackId] = decodeDetails(e.trackId, e.details);
      }
    }
    return {
      for (final id in ids)
        id: (credits: credits[id] ?? const [], details: details[id]),
    };
  }

  /// For backup and received tracks: credits are written only when the track
  /// has none, details only when it has none. Saving credits clears
  /// `credits_none_at` (credits and the «searched, nothing» mark never coexist).
  Future<void> saveIfNone(
    int trackId,
    List<TrackCredit> credits,
    TrackDetails? details,
  ) => _db.transaction(() async {
    final hasCredits = (await creditsOf(trackId)).isNotEmpty;
    final saveCredits = credits.isNotEmpty && !hasCredits;
    final saveDetails =
        details != null &&
        decodeDetails(trackId, (await enrichOf(trackId))?.details) == null;
    if (saveCredits) {
      await _replace(trackId, [
        for (final c in credits)
          TrackCreditsCompanion.insert(
            trackId: trackId,
            name: c.name,
            nameKey: c.nameKey,
            role: c.role,
            source: c.source,
          ),
      ]);
    }
    if (saveCredits || saveDetails) {
      await _upsert(
        TrackEnrichCompanion(
          trackId: Value(trackId),
          details: saveDetails
              ? Value(jsonEncode(details.toJson()))
              : const Value.absent(),
          creditsNoneAt: saveCredits ? const Value(null) : const Value.absent(),
        ),
      );
    }
  });

  Future<void> _replace(
    int trackId,
    List<TrackCreditsCompanion> credits,
  ) async {
    await (_db.delete(
      _db.trackCredits,
    )..where((c) => c.trackId.equals(trackId))).go();
    await _db.batch(
      (b) => b.insertAll(_db.trackCredits, [
        for (final c in credits) c.copyWith(trackId: Value(trackId)),
      ], mode: InsertMode.insertOrReplace),
    );
  }

  Future<void> _upsert(TrackEnrichCompanion row) =>
      _db.into(_db.trackEnrich).insert(row, onConflict: DoUpdate((_) => row));
}

/// The stored details JSON; a corrupt row logs and gives null.
TrackDetails? decodeDetails(int trackId, String? raw) {
  if (raw == null) return null;
  try {
    return TrackDetails.fromJson(jsonDecode(raw) as Map);
  } on Object catch (e, st) {
    AppLog.w('track $trackId: details not readable', e, st);
    return null;
  }
}
