import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// The listening history (`plays`): one row per listen that counted as played.
/// The Jam does not record anything here: it plays through its own backend,
/// not through the audio handler.
class PlayHistoryRepository {
  PlayHistoryRepository(this._db);

  final AppDatabase _db;

  /// Opens a row for a listen that has just counted as played.
  Future<int> start(
    int trackId,
    int playedAt, {
    int? context,
    String? contextName,
    int msPlayed = 0,
  }) => _db.into(_db.plays).insert(
        PlaysCompanion.insert(
          trackId: trackId,
          playedAt: playedAt,
          msPlayed: Value(msPlayed),
          context: Value(context),
          contextName: Value(contextName),
        ),
      );

  /// Sets the time really spent playing (it only ever grows while the track
  /// is on, so the last call wins).
  Future<void> finish(int playId, int msPlayed) => (_db.update(_db.plays)
        ..where((p) => p.id.equals(playId)))
      .write(PlaysCompanion(msPlayed: Value(msPlayed)));

  Future<int> count() async {
    final c = _db.plays.id.count();
    final row = await (_db.selectOnly(_db.plays)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }
}
