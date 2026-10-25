import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'track_kinds.dart';

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

  /// The newest [limit] listens (older than [beforePlayedAt] when given), with
  /// their track, most recent first. Missing and hidden tracks are left out.
  Stream<List<HistoryEntry>> watchHistory({int limit = 200, int? beforePlayedAt}) {
    final q = _db.select(_db.plays).join([
      innerJoin(_db.tracks, _db.tracks.id.equalsExp(_db.plays.trackId)),
    ])
      ..where(_db.tracks.missing.equals(false) &
          _db.tracks.ignored.equals(false) &
          _db.tracks.kind.isIn(listenKinds) &
          (beforePlayedAt == null
              ? const Constant(true)
              : _db.plays.playedAt.isSmallerThanValue(beforePlayedAt)))
      ..orderBy([
        OrderingTerm.desc(_db.plays.playedAt),
        OrderingTerm.desc(_db.plays.id),
      ])
      ..limit(limit);
    return q.watch().map((rows) => [
          for (final r in rows)
            HistoryEntry(r.readTable(_db.plays), r.readTable(_db.tracks)),
        ]);
  }

  /// Forgets the history. Only `plays`: play counts, favourites and
  /// playlists are not touched.
  Future<int> clear() => _db.delete(_db.plays).go();
}

/// One listen with the track it was of.
class HistoryEntry {
  const HistoryEntry(this.play, this.track);

  final Play play;
  final Track track;

  DateTime get at => DateTime.fromMillisecondsSinceEpoch(play.playedAt);
}

/// Day headers (as the date at local midnight) and entries, in the order
/// given (most recent first): the list the history screen shows.
List<Object> groupHistoryByDay(List<HistoryEntry> entries) {
  final out = <Object>[];
  DateTime? day;
  for (final e in entries) {
    final d = DateTime(e.at.year, e.at.month, e.at.day);
    if (d != day) {
      out.add(d);
      day = d;
    }
    out.add(e);
  }
  return out;
}

