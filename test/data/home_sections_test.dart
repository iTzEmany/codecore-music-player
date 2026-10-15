import 'package:codecore/data/repositories/home_sections.dart';
import 'package:codecore/data/repositories/library_queries.dart';
import 'package:flutter_test/flutter_test.dart';

AlbumSummary a(String t, {int? played, int added = 0, int plays = 0}) =>
    AlbumSummary(
      albumKey: t,
      title: t,
      artist: 'X',
      variousArtists: false,
      trackCount: 1,
      durationMs: 1,
      year: null,
      coverKey: null,
      lastPlayedAt: played,
      addedAt: added,
      playCount: plays,
    );

void main() {
  final now = DateTime(2026, 10, 15);
  int daysAgo(int d) => now.subtract(Duration(days: d)).millisecondsSinceEpoch;

  test('greeting by hour', () {
    expect(greetingForHour(7), Greeting.morning);
    expect(greetingForHour(12), Greeting.afternoon);
    expect(greetingForHour(17), Greeting.afternoon);
    expect(greetingForHour(18), Greeting.evening);
    expect(greetingForHour(2), Greeting.evening);
  });

  test('rediscover: many plays but idle for 60+ days, most played first', () {
    final r = rediscoverAlbums([
      a('old-loved', played: daysAgo(90), plays: 20),
      a('old-meh', played: daysAgo(90), plays: 1),
      a('fresh-loved', played: daysAgo(3), plays: 50),
      a('older-loved', played: daysAgo(200), plays: 30),
      a('never', plays: 0),
    ], now);
    expect(r.map((e) => e.title), ['older-loved', 'old-loved']);
  });

  test('recently played skips never-played, latest first', () {
    final r = recentlyPlayedAlbums([
      a('b', played: 5),
      a('never'),
      a('c', played: 9),
    ]);
    expect(r.map((e) => e.title), ['c', 'b']);
  });

  test('recently added orders by addedAt', () {
    final r = recentlyAddedAlbums([a('x', added: 1), a('y', added: 7)], limit: 1);
    expect(r.single.title, 'y');
  });
}
