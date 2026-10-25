import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Credits and enrichment state of tracks. Writes only `track_credits` and
/// `track_enrich`, never `tracks` (so the library list does not re-emit).
class CreditsRepository {
  CreditsRepository(this._db);

  final AppDatabase _db;

  Future<List<TrackCreditRow>> creditsOf(int trackId) =>
      (_db.select(_db.trackCredits)..where((c) => c.trackId.equals(trackId))).get();

  Future<TrackEnrichData?> enrichOf(int trackId) =>
      (_db.select(_db.trackEnrich)..where((e) => e.trackId.equals(trackId))).getSingleOrNull();

  /// Replaces every credit of [trackId] with [credits] (their `trackId` is
  /// the one given here).
  Future<void> saveCredits(int trackId, List<TrackCreditsCompanion> credits) =>
      _db.transaction(() => _replace(trackId, credits));

  /// Upserts the enrichment row; columns absent from [row] keep their value.
  Future<void> saveEnrich(TrackEnrichCompanion row) => _upsert(row);

  /// [saveCredits] and [saveEnrich] in one transaction.
  Future<void> save(int trackId, List<TrackCreditsCompanion> credits, TrackEnrichCompanion row) =>
      _db.transaction(() async {
        await _replace(trackId, credits);
        await _upsert(row);
      });

  Future<void> _replace(int trackId, List<TrackCreditsCompanion> credits) async {
    await (_db.delete(_db.trackCredits)..where((c) => c.trackId.equals(trackId))).go();
    await _db.batch((b) => b.insertAll(
          _db.trackCredits,
          [for (final c in credits) c.copyWith(trackId: Value(trackId))],
          mode: InsertMode.insertOrReplace,
        ));
  }

  Future<void> _upsert(TrackEnrichCompanion row) =>
      _db.into(_db.trackEnrich).insert(row, onConflict: DoUpdate((_) => row));
}
