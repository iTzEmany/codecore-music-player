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

    // One pass over the listens, grouped by track (at most one row per track
    // of the library); rankings are worked out from those rows. Joining 100 000
    // listens to their tracks for each ranking was the slow part, and only the
    // columns the rankings need are read.
    final perTrack = await _q(
      'SELECT t.id AS id, t.artist AS artist, t.album AS album, '
      't.album_key AS album_key, a.n AS n, a.ms AS ms '
      'FROM (SELECT p.track_id AS tid, COUNT(*) AS n, SUM(p.ms_played) AS ms '
      // A year is most of the table: read it in track order straight from the
      // covering index. A month is better served by the range on `played_at`.
      'FROM plays p ${p.isYear ? 'INDEXED BY plays_track ' : ''}'
      'WHERE $where GROUP BY p.track_id) a '
      'JOIN tracks t ON t.id = a.tid',
      range,
    );
    // One pass over the rows (raw maps: this loop runs once per track of the
    // library). The best [top] tracks are kept in a short sorted list.
    var plays = 0, playedMs = 0;
    final best = <({int id, int n, int ms})>[];
    int cmp(({int id, int n, int ms}) a, ({int id, int n, int ms}) b) {
      final c = b.n.compareTo(a.n);
      if (c != 0) return c;
      final m = b.ms.compareTo(a.ms);
      return m != 0 ? m : a.id.compareTo(b.id);
    }

    final artistGroups = <String, ({int n, int ms, String? name})>{};
    final albumGroups = <String, ({int n, int ms, String? name, String? artist})>{};
    for (final r in perTrack) {
      final d = r.data;
      final n = d['n']! as int;
      final ms = (d['ms'] as int?) ?? 0;
      plays += n;
      playedMs += ms;
      final entry = (id: d['id']! as int, n: n, ms: ms);
      if (best.length < top || cmp(entry, best.last) < 0) {
        var at = best.length;
        while (at > 0 && cmp(entry, best[at - 1]) < 0) {
          at--;
        }
        best.insert(at, entry);
        if (best.length > top) best.removeLast();
      }
      final artist = d['artist'] as String?;
      final key = _artistKey(artist);
      if (key.isNotEmpty) {
        final cur = artistGroups[key];
        artistGroups[key] = (
          n: (cur?.n ?? 0) + n,
          ms: (cur?.ms ?? 0) + ms,
          name: _minText(cur?.name, artist),
        );
      }
      final album = d['album'] as String?;
      if (album != null) {
        final k = d['album_key']! as String;
        final cur = albumGroups[k];
        albumGroups[k] = (
          n: (cur?.n ?? 0) + n,
          ms: (cur?.ms ?? 0) + ms,
          name: _minText(cur?.name, album),
          artist: _minText(cur?.artist, artist),
        );
      }
    }
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

    // Tracks: by listens, then time, then the order they were added.
    final tracks = best;
    final topIds = [for (final t in tracks.take(top)) t.id];
    final info = {
      for (final r in await _q(
        'SELECT id, title, artist, cover_key FROM tracks WHERE id IN '
        '(${List.filled(topIds.length, '?').join(',')})',
        [for (final id in topIds) Variable.withInt(id)],
      ))
        r.read<int>('id'): r,
    };
    final topTracks = [
      for (final t in tracks.take(top))
        RankedItem(
          key: '${t.id}',
          name: info[t.id]!.read<String>('title'),
          plays: t.n,
          playedMs: t.ms,
          artist: info[t.id]!.read<String?>('artist'),
          coverKey: info[t.id]!.read<String?>('cover_key'),
        ),
    ];

    // Artists and albums were grouped above, as the library groups them.
    final topArtists = [
      for (final e in (artistGroups.entries.toList()
        ..sort((a, b) => _byCount(a.value.n, a.value.ms, a.key, b.value.n,
            b.value.ms, b.key))).take(top))
        RankedItem(key: e.key, name: e.value.name, plays: e.value.n, playedMs: e.value.ms),
    ];
    final albumEntries = (albumGroups.entries.toList()
          ..sort((a, b) => _byCount(
              a.value.n, a.value.ms, (a.value.name ?? '').toLowerCase(),
              b.value.n, b.value.ms, (b.value.name ?? '').toLowerCase())))
        .take(top)
        .toList();
    final covers = albumEntries.isEmpty
        ? const <String, String?>{}
        : {
            for (final r in await _q(
              'SELECT album_key, MIN(cover_key) AS cover FROM tracks WHERE album_key IN '
              '(${List.filled(albumEntries.length, '?').join(',')}) GROUP BY album_key',
              [for (final e in albumEntries) Variable.withString(e.key)],
            ))
              r.read<String>('album_key'): r.read<String?>('cover'),
          };
    final topAlbums = [
      for (final e in albumEntries)
        RankedItem(
          key: e.key,
          name: e.value.name,
          plays: e.value.n,
          playedMs: e.value.ms,
          artist: e.value.artist,
          coverKey: covers[e.key],
        ),
    ];

    // The bars: one range sum per day or month, bounded by the local midnights
    // (exact, and the clock changes cannot misplace a listen). Each is an
    // index range, so all together they read the period once.
    final bounds = [...p.bucketStarts.map((d) => d.millisecondsSinceEpoch), p.endMs];
    final sums = [
      for (var i = 0; i + 1 < bounds.length; i++)
        '(SELECT SUM(ms_played) FROM plays WHERE played_at >= ? AND played_at < ?) AS b$i',
    ];
    final bucketRow = (await _q(
      'SELECT ${sums.join(', ')}',
      [
        for (var i = 0; i + 1 < bounds.length; i++) ...[
          Variable.withInt(bounds[i]),
          Variable.withInt(bounds[i + 1]),
        ],
      ],
    ))
        .single;
    final perBucket = [
      for (var i = 0; i + 1 < bounds.length; i++) bucketRow.read<int?>('b$i') ?? 0,
    ];

    // The hour of the day: listens grouped by hour since the epoch in SQL (at
    // most one row per hour of the period), turned into a local hour here, so
    // the clock changes are honoured without a date function per listen. In a
    // zone with a half-hour offset the listens of the first half hour count
    // for the previous hour: it only matters to a tie between two hours.
    final hours = await _q(
      'SELECT p.played_at / 3600000 AS h, COUNT(*) AS n FROM plays p '
      'WHERE $where GROUP BY h',
      range,
    );
    final perHour = List.filled(24, 0);
    for (final r in hours) {
      final at = DateTime.fromMillisecondsSinceEpoch(r.read<int>('h') * 3600000);
      perHour[at.hour] += r.read<int>('n');
    }
    var favouriteHour = 0;
    for (var h = 1; h < 24; h++) {
      if (perHour[h] > perHour[favouriteHour]) favouriteHour = h;
    }

    final first = await _q(
      'SELECT t.title AS title, p.played_at AS at FROM plays p '
      'JOIN tracks t ON t.id = p.track_id WHERE $where '
      'ORDER BY p.played_at, p.id LIMIT 1',
      range,
    );

    return PeriodStats(
      period: p,
      plays: plays,
      playedMs: playedMs,
      distinctTracks: perTrack.length,
      topTracks: topTracks,
      topArtists: topArtists,
      topAlbums: topAlbums,
      msPerBucket: perBucket,
      favouriteHour: favouriteHour,
      firstTitle: first.isEmpty ? null : first.single.read<String>('title'),
      firstAt: first.isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(first.single.read<int>('at')),
    );
  }
}

/// The artist key of the library: lower-cased (ASCII only, as SQLite's
/// `lower()`) and trimmed; empty for no artist.
String _artistKey(String? artist) {
  final t = (artist ?? '').trim();
  final b = StringBuffer();
  for (final c in t.codeUnits) {
    b.writeCharCode(c >= 65 && c <= 90 ? c + 32 : c);
  }
  return b.toString();
}

/// The smaller of two texts (SQLite's `MIN()`, which the old query used), null
/// ignored.
String? _minText(String? a, String? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.compareTo(b) <= 0 ? a : b;
}

/// Most listens first, then most time, then by name.
int _byCount(int an, int ams, String asort, int bn, int bms, String bsort) {
  final c = bn.compareTo(an);
  if (c != 0) return c;
  final m = bms.compareTo(ams);
  return m != 0 ? m : asort.compareTo(bsort);
}

