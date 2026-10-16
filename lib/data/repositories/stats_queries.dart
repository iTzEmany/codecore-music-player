import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// A month or a year, in local time: [start] inclusive, [end] exclusive.
class StatsPeriod {
  const StatsPeriod._(this.start, this.end, this.isYear);

  factory StatsPeriod.month(int year, int month) =>
      StatsPeriod._(DateTime(year, month), DateTime(year, month + 1), false);

  factory StatsPeriod.year(int year) =>
      StatsPeriod._(DateTime(year), DateTime(year + 1), true);

  /// The month or the year [now] falls in.
  factory StatsPeriod.containing(DateTime now, {required bool year}) =>
      year ? StatsPeriod.year(now.year) : StatsPeriod.month(now.year, now.month);

  final DateTime start, end;
  final bool isYear;

  int get startMs => start.millisecondsSinceEpoch;
  int get endMs => end.millisecondsSinceEpoch;

  StatsPeriod get previous => isYear
      ? StatsPeriod.year(start.year - 1)
      : StatsPeriod.month(start.year, start.month - 1);

  StatsPeriod get next => isYear
      ? StatsPeriod.year(start.year + 1)
      : StatsPeriod.month(start.year, start.month + 1);

  /// Days of a month or months of a year: where each bar of the chart starts
  /// (local midnights, so a day is 23 or 25 hours long when the clock moves).
  List<DateTime> get bucketStarts => isYear
      ? [for (var m = 1; m <= 12; m++) DateTime(start.year, m)]
      : [
          for (var d = 1; DateTime(start.year, start.month, d).isBefore(end); d++)
            DateTime(start.year, start.month, d),
        ];
}

/// A track, artist or album in a ranking.
class RankedItem {
  const RankedItem({
    required this.key,
    required this.name,
    required this.plays,
    required this.playedMs,
    this.artist,
    this.coverKey,
  });

  /// Track id, artist key or album key.
  final String key;
  final String? name;
  final int plays, playedMs;
  final String? artist;
  final String? coverKey;
}

class PeriodStats {
  const PeriodStats({
    required this.period,
    required this.plays,
    required this.playedMs,
    required this.distinctTracks,
    required this.topTracks,
    required this.topArtists,
    required this.topAlbums,
    required this.msPerBucket,
    this.favouriteHour,
    this.firstTitle,
    this.firstAt,
  });

  final StatsPeriod period;
  final int plays, playedMs, distinctTracks;
  final List<RankedItem> topTracks, topArtists, topAlbums;

  /// Milliseconds played in each day (month) or month (year) of the period.
  final List<int> msPerBucket;

  /// Local hour (0–23) with the most listens.
  final int? favouriteHour;

  /// The first listen of the period.
  final String? firstTitle;
  final DateTime? firstAt;

  bool get isEmpty => plays == 0;
  int get playedMinutes => (playedMs / 60000).round();
}

/// Aggregates over the listening history (`plays`), all in SQL. Artists and
/// albums are grouped as the library does: by the lower-cased trimmed artist
/// and by `albumKey`, not by the raw tag text.
class StatsQueries {
  StatsQueries(this._db);

  final AppDatabase _db;

  Future<List<QueryRow>> _q(String sql, List<Variable> vars) => _db
      .customSelect(sql, variables: vars, readsFrom: {_db.plays, _db.tracks}).get();

  /// The stats of [p], computed again whenever the history changes.
  Stream<PeriodStats> watchPeriod(StatsPeriod p) async* {
    yield await period(p);
    await for (final _ in _db.tableUpdates(TableUpdateQuery.onTable(_db.plays))) {
      yield await period(p);
    }
  }

  Stream<int> watchPlaysIn(StatsPeriod p) async* {
    yield await playsIn(p);
    await for (final _ in _db.tableUpdates(TableUpdateQuery.onTable(_db.plays))) {
      yield await playsIn(p);
    }
  }

  Future<int> playsIn(StatsPeriod p) async {
    final r = await _q(
      'SELECT COUNT(*) AS n FROM plays WHERE played_at >= ? AND played_at < ?',
      [Variable.withInt(p.startMs), Variable.withInt(p.endMs)],
    );
    return r.single.read<int>('n');
  }

  Future<PeriodStats> period(StatsPeriod p, {int top = 10}) async {
    final range = [Variable.withInt(p.startMs), Variable.withInt(p.endMs)];
    const where = 'p.played_at >= ? AND p.played_at < ?';

    final totals = (await _q(
      'SELECT COUNT(*) AS n, COALESCE(SUM(ms_played), 0) AS ms, '
      'COUNT(DISTINCT track_id) AS d FROM plays p WHERE $where',
      range,
    ))
        .single;
    final plays = totals.read<int>('n');
    if (plays == 0) {
      return PeriodStats(
        period: p,
        plays: 0,
        playedMs: 0,
        distinctTracks: 0,
        topTracks: const [],
        topArtists: const [],
        topAlbums: const [],
        msPerBucket: List.filled(p.bucketStarts.length, 0),
      );
    }

    final tracks = await _q(
      'SELECT t.id AS k, t.title AS name, t.artist AS artist, '
      't.cover_key AS cover, COUNT(*) AS n, SUM(p.ms_played) AS ms '
      'FROM plays p JOIN tracks t ON t.id = p.track_id WHERE $where '
      'GROUP BY t.id ORDER BY n DESC, ms DESC, t.title COLLATE NOCASE LIMIT $top',
      range,
    );
    final artists = await _q(
      "SELECT lower(trim(COALESCE(t.artist, ''))) AS k, MIN(t.artist) AS name, "
      'MIN(t.cover_key) AS cover, COUNT(*) AS n, SUM(p.ms_played) AS ms '
      'FROM plays p JOIN tracks t ON t.id = p.track_id '
      "WHERE $where AND trim(COALESCE(t.artist, '')) <> '' "
      'GROUP BY k ORDER BY n DESC, ms DESC, k LIMIT $top',
      range,
    );
    final albums = await _q(
      'SELECT t.album_key AS k, MIN(t.album) AS name, MIN(t.artist) AS artist, '
      'MIN(t.cover_key) AS cover, COUNT(*) AS n, SUM(p.ms_played) AS ms '
      'FROM plays p JOIN tracks t ON t.id = p.track_id '
      'WHERE $where AND t.album IS NOT NULL '
      'GROUP BY t.album_key ORDER BY n DESC, ms DESC, name COLLATE NOCASE LIMIT $top',
      range,
    );

    // One scan for every bar: a SUM per day or month, bounded by the local
    // midnights (so the clock changes cannot misplace a listen).
    final bounds = [...p.bucketStarts.map((d) => d.millisecondsSinceEpoch), p.endMs];
    final cols = [
      for (var i = 0; i + 1 < bounds.length; i++)
        'SUM(CASE WHEN played_at >= ? AND played_at < ? THEN ms_played ELSE 0 END) AS b$i',
    ];
    final bucketRow = (await _q(
      'SELECT ${cols.join(', ')} FROM plays p WHERE $where',
      [
        for (var i = 0; i + 1 < bounds.length; i++) ...[
          Variable.withInt(bounds[i]),
          Variable.withInt(bounds[i + 1]),
        ],
        ...range,
      ],
    ))
        .single;
    final perBucket = [
      for (var i = 0; i + 1 < bounds.length; i++)
        bucketRow.read<int?>('b$i') ?? 0,
    ];

    final hour = await _q(
      "SELECT CAST(strftime('%H', p.played_at / 1000, 'unixepoch', 'localtime') AS INTEGER) AS h, "
      'COUNT(*) AS n FROM plays p WHERE $where GROUP BY h ORDER BY n DESC, h LIMIT 1',
      range,
    );
    final first = await _q(
      'SELECT t.title AS title, p.played_at AS at FROM plays p '
      'JOIN tracks t ON t.id = p.track_id WHERE $where '
      'ORDER BY p.played_at, p.id LIMIT 1',
      range,
    );

    List<RankedItem> ranked(List<QueryRow> rows, {bool track = false}) => [
          for (final r in rows)
            RankedItem(
              key: track ? '${r.read<int>('k')}' : r.read<String>('k'),
              name: r.read<String?>('name'),
              plays: r.read<int>('n'),
              playedMs: r.read<int?>('ms') ?? 0,
              artist: r.data.containsKey('artist') ? r.read<String?>('artist') : null,
              coverKey: r.read<String?>('cover'),
            ),
        ];

    return PeriodStats(
      period: p,
      plays: plays,
      playedMs: totals.read<int>('ms'),
      distinctTracks: totals.read<int>('d'),
      topTracks: ranked(tracks, track: true),
      topArtists: ranked(artists),
      topAlbums: ranked(albums),
      msPerBucket: perBucket,
      favouriteHour: hour.isEmpty ? null : hour.single.read<int>('h'),
      firstTitle: first.isEmpty ? null : first.single.read<String>('title'),
      firstAt: first.isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(first.single.read<int>('at')),
    );
  }
}
