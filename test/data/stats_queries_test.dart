import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/play_history_repository.dart';
import 'package:codecore/data/repositories/stats_queries.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

int _ms(int y, int m, int d, [int h = 12, int min = 0, int s = 0]) =>
    DateTime(y, m, d, h, min, s).millisecondsSinceEpoch;

void main() {
  late AppDatabase db;
  late PlayHistoryRepository history;
  late StatsQueries stats;
  late Map<String, int> id;

  Future<int> track(String title, {String? artist, String? album, String? albumKey, String? cover}) async {
    await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/$title.mp3', title: title, albumKey: albumKey ?? (album ?? 'none'),
          format: 'mp3', sizeBytes: 1, mtimeMs: 1, addedAt: 1,
          artist: Value(artist), album: Value(album), coverKey: Value(cover)));
    return (await (db.select(db.tracks)..where((t) => t.path.equals('/$title.mp3'))).getSingle()).id;
  }

  Future<void> listen(String title, int at, {int ms = 60000}) =>
      history.start(id[title]!, at, msPlayed: ms);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    history = PlayHistoryRepository(db);
    stats = StatsQueries(db);
    id = {
      'One More Time': await track('One More Time', artist: 'Daft Punk', album: 'Discovery', albumKey: 'daft punk|discovery', cover: 'c1'),
      'Digital Love': await track('Digital Love', artist: 'daft punk ', album: 'Discovery', albumKey: 'daft punk|discovery'),
      'Get Lucky': await track('Get Lucky', artist: 'Daft Punk', album: 'RAM', albumKey: 'daft punk|ram'),
      'Futura': await track('Futura', artist: 'Lucio Dalla', album: 'Dalla', albumKey: 'lucio dalla|dalla'),
      'Loose': await track('Loose'), // no artist, no album
    };
  });
  tearDown(() => db.close());

  test('a month: totals, distinct tracks and minutes', () async {
    await listen('One More Time', _ms(2026, 10, 3), ms: 120000);
    await listen('One More Time', _ms(2026, 10, 4), ms: 180000);
    await listen('Futura', _ms(2026, 10, 20), ms: 90000);
    final s = await stats.period(StatsPeriod.month(2026, 10));
    expect(s.plays, 3);
    expect(s.distinctTracks, 2);
    expect(s.playedMs, 390000);
    expect(s.isEmpty, isFalse);
  });

  test('the month boundaries are local midnights', () async {
    await listen('Futura', _ms(2026, 9, 30, 23, 59, 59), ms: 1000);
    await listen('Futura', _ms(2026, 10, 1, 0, 0, 0), ms: 2000);
    await listen('Futura', _ms(2026, 10, 31, 23, 59, 59), ms: 4000);
    await listen('Futura', _ms(2026, 11, 1, 0, 0, 0), ms: 8000);
    final oct = await stats.period(StatsPeriod.month(2026, 10));
    expect(oct.plays, 2);
    expect(oct.playedMs, 6000);
    final sep = await stats.period(StatsPeriod.month(2026, 9));
    expect(sep.plays, 1);
    final nov = await stats.period(StatsPeriod.month(2026, 11));
    expect(nov.playedMs, 8000);
  });

  test('top tracks: by number of listens, then by time, ten at most', () async {
    for (var i = 0; i < 3; i++) {
      await listen('Digital Love', _ms(2026, 10, 2, 10 + i));
    }
    await listen('Get Lucky', _ms(2026, 10, 5), ms: 500000);
    await listen('Get Lucky', _ms(2026, 10, 6), ms: 500000);
    await listen('Futura', _ms(2026, 10, 7), ms: 100);
    await listen('Futura', _ms(2026, 10, 8), ms: 100);
    final s = await stats.period(StatsPeriod.month(2026, 10));
    expect(s.topTracks.map((t) => t.name), ['Digital Love', 'Get Lucky', 'Futura']);
    expect(s.topTracks.first.plays, 3);
    expect(s.topTracks.first.artist, 'daft punk ');
    final many = await stats.period(StatsPeriod.month(2026, 10), top: 2);
    expect(many.topTracks, hasLength(2));
  });

  test('artists are grouped as the library groups them: case and spaces do not split one', () async {
    await listen('One More Time', _ms(2026, 10, 2));
    await listen('Digital Love', _ms(2026, 10, 3));
    await listen('Get Lucky', _ms(2026, 10, 4));
    await listen('Futura', _ms(2026, 10, 5));
    await listen('Loose', _ms(2026, 10, 6));
    final s = await stats.period(StatsPeriod.month(2026, 10));
    expect(s.topArtists.map((a) => a.key), ['daft punk', 'lucio dalla']);
    expect(s.topArtists.first.plays, 3);
    expect(s.topArtists.map((a) => a.name), isNot(contains(null)), reason: 'no «unknown artist» in the ranking');
  });

  test('albums by albumKey, tracks without an album left out', () async {
    await listen('One More Time', _ms(2026, 10, 2));
    await listen('Digital Love', _ms(2026, 10, 3));
    await listen('Get Lucky', _ms(2026, 10, 4));
    await listen('Loose', _ms(2026, 10, 6));
    final s = await stats.period(StatsPeriod.month(2026, 10));
    expect(s.topAlbums.map((a) => a.key), ['daft punk|discovery', 'daft punk|ram']);
    expect(s.topAlbums.first.plays, 2);
    expect(s.topAlbums.first.name, 'Discovery');
  });

  test('the bars: one per day of the month, one per month of the year, same total', () async {
    await listen('Futura', _ms(2026, 10, 1, 0, 0, 0), ms: 1000);
    await listen('Futura', _ms(2026, 10, 15), ms: 2000);
    await listen('Futura', _ms(2026, 10, 31, 23, 59, 59), ms: 4000);
    await listen('Futura', _ms(2026, 3, 9), ms: 8000);
    final month = await stats.period(StatsPeriod.month(2026, 10));
    expect(month.msPerBucket, hasLength(31));
    expect(month.msPerBucket[0], 1000);
    expect(month.msPerBucket[14], 2000);
    expect(month.msPerBucket[30], 4000);
    expect(month.msPerBucket.fold<int>(0, (a, b) => a + b), month.playedMs);

    final year = await stats.period(StatsPeriod.year(2026));
    expect(year.msPerBucket, hasLength(12));
    expect(year.msPerBucket[2], 8000, reason: 'March');
    expect(year.msPerBucket[9], 7000, reason: 'October');
    expect(year.playedMs, 15000);

    final sep = await stats.period(StatsPeriod.month(2026, 9));
    expect(sep.msPerBucket, hasLength(30));
    final feb = await stats.period(StatsPeriod.month(2028, 2));
    expect(feb.msPerBucket, hasLength(29), reason: 'leap year');
  });

  test('the favourite hour is the local hour with most listens', () async {
    await listen('Futura', _ms(2026, 10, 2, 21, 5));
    await listen('Futura', _ms(2026, 10, 3, 21, 40));
    await listen('Futura', _ms(2026, 10, 4, 21, 59));
    await listen('Futura', _ms(2026, 10, 5, 8, 0));
    final s = await stats.period(StatsPeriod.month(2026, 10));
    expect(s.favouriteHour, 21);
  });

  test('the first listen of the period', () async {
    await listen('Futura', _ms(2026, 10, 9, 18));
    await listen('Digital Love', _ms(2026, 10, 2, 7, 30));
    await listen('Get Lucky', _ms(2026, 10, 20));
    final s = await stats.period(StatsPeriod.month(2026, 10));
    expect(s.firstTitle, 'Digital Love');
    expect(s.firstAt, DateTime(2026, 10, 2, 7, 30));
  });

  test('a period with no listens is empty, with zeroed bars', () async {
    await listen('Futura', _ms(2026, 9, 5));
    final s = await stats.period(StatsPeriod.month(2026, 10));
    expect(s.isEmpty, isTrue);
    expect(s.playedMs, 0);
    expect(s.topTracks, isEmpty);
    expect(s.msPerBucket, List.filled(31, 0));
    expect(s.favouriteHour, isNull);
    expect(s.firstTitle, isNull);
  });

  test('playsIn counts a period cheaply', () async {
    for (var d = 1; d <= 12; d++) {
      await listen('Futura', _ms(2026, 10, d));
    }
    await listen('Futura', _ms(2026, 9, 30));
    expect(await stats.playsIn(StatsPeriod.month(2026, 10)), 12);
    expect(await stats.playsIn(StatsPeriod.month(2026, 8)), 0);
  });

  test('listens of a deleted track disappear with it', () async {
    await listen('Futura', _ms(2026, 10, 9));
    await listen('Digital Love', _ms(2026, 10, 10));
    await (db.delete(db.tracks)..where((t) => t.id.equals(id['Futura']!))).go();
    final s = await stats.period(StatsPeriod.month(2026, 10));
    expect(s.plays, 1);
  });

  group('StatsPeriod', () {
    test('previous and next cross the year', () {
      final jan = StatsPeriod.month(2026, 1);
      expect(jan.previous.start, DateTime(2025, 12));
      expect(StatsPeriod.month(2026, 12).next.start, DateTime(2027, 1));
      expect(StatsPeriod.year(2026).previous.start, DateTime(2025));
      expect(StatsPeriod.year(2026).next.end, DateTime(2028));
    });

    test('containing picks the month or the year of a date', () {
      final now = DateTime(2026, 10, 16, 9);
      expect(StatsPeriod.containing(now, year: false).start, DateTime(2026, 10));
      expect(StatsPeriod.containing(now, year: true).start, DateTime(2026));
    });
  });

  group('topArtistsSince', () {
    final from = DateTime(2026, 8, 1);

    test('ranks main artists by time played since the date, one per matchKey', () async {
      final feat = await track('Feat', artist: 'Daft Punk feat. Pharrell');
      await listen('One More Time', _ms(2026, 9, 1), ms: 100000);
      await history.start(feat, _ms(2026, 9, 2), msPlayed: 50000);
      await listen('Futura', _ms(2026, 9, 3), ms: 120000);
      await listen('Futura', _ms(2026, 6, 3), ms: 900000); // before the window
      final top = await stats.topArtistsSince(from);
      expect([for (final a in top) (a.name, a.playedMs, a.plays)], [
        ('Daft Punk', 150000, 2),
        ('Lucio Dalla', 120000, 1),
      ]);
      expect(top.first.key, 'daft punk');
      expect(await stats.topArtistsSince(from, limit: 1), hasLength(1));
    });

    test('without any history it sums play_count', () async {
      await (db.update(db.tracks)..where((t) => t.id.equals(id['One More Time']!)))
          .write(const TracksCompanion(playCount: Value(5)));
      await (db.update(db.tracks)..where((t) => t.id.equals(id['Get Lucky']!)))
          .write(const TracksCompanion(playCount: Value(3)));
      await (db.update(db.tracks)..where((t) => t.id.equals(id['Futura']!)))
          .write(const TracksCompanion(playCount: Value(6)));
      final top = await stats.topArtistsSince(from);
      expect([for (final a in top) (a.name, a.plays)], [('Daft Punk', 8), ('Lucio Dalla', 6)]);
    });
  });
}
