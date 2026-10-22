import 'package:codecore/services/online/query_match.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'smart_cases.dart';

double confidenceOf(SmartCase c, String id) =>
    c.scored().firstWhere((s) => s.result.id == id).confidence;

void main() {
  test('the first result of each recorded search is one of the expected ones', () {
    for (final c in loadSmartCases().where((c) => c.expectedFirst != null)) {
      final first = ranked(c.scored()).first;
      expect(c.expectedFirst, contains(first.result.id),
          reason: '${c.query}: got ${first.result.title} (${first.result.id})');
    }
  });

  test('a remix is first when the phrase asks for one, the original after it', () {
    final c = smartCase('fleetwood mac dreams remix');
    final list = ranked(c.scored());
    expect(list.first.result.title.toLowerCase(), contains('remix'));
    const original = '5oWyMakvQew';
    expect(list.indexWhere((s) => s.result.id == original),
        greaterThan(list.indexWhere((s) => s.result.title.toLowerCase().contains('remix'))));
    // The same phrase without the word keeps the original on top of the remixes.
    expect(queryConfidence('fleetwood mac dreams', c.songs[1]),
        greaterThan(confidenceOf(c, original)));
  });

  test('covers by other artists fall under the threshold, the artist\'s own stay over', () {
    final c = smartCase('bob dylan girl from the north country');
    expect(confidenceOf(c, 'Z6sSqT1lzjw'), lessThan(kBestThreshold)); // Neil Young
    expect(confidenceOf(c, '8b_6qbAAQDI'), lessThan(kBestThreshold)); // Wylie & The Wild West
    expect(confidenceOf(c, 'JncbFS5ek74'), greaterThanOrEqualTo(kBestThreshold));
    expect(confidenceOf(c, '-PfDSQSWuGI'), greaterThanOrEqualTo(kBestThreshold));
  });

  test('a preview of 32 s and a video of 70 minutes of the song are not best results', () {
    final c = smartCase('lucio corsi sigarette');
    YtResult upload(String id, String title, Duration d) => YtResult(
        id: id, title: title, channel: 'Lucio Corsi', duration: d, artists: const ['Lucio Corsi']);
    final scored = scoreAll(c.query,
        songs: [...c.songs, upload('short', 'Sigarette', const Duration(seconds: 32))],
        videos: [...c.videos, upload('long', 'Sigarette', const Duration(minutes: 70))]);
    expect(scored.firstWhere((s) => s.result.id == 'InRdKLk1BTU').confidence,
        greaterThanOrEqualTo(kBestThreshold));
    expect(scored.firstWhere((s) => s.result.id == 'short').confidence, lessThan(kBestThreshold));
    expect(scored.firstWhere((s) => s.result.id == 'long').confidence, lessThan(kBestThreshold));
  });

  test('sets stay on top when YouTube Music has no song for the phrase', () {
    final fred = smartCase('fred again boiler room london');
    expect(confidenceOf(fred, 'c0-hvjV2A5Y'), greaterThanOrEqualTo(kBestThreshold));
    expect(fred.scored().where((s) => s.source == MediaKind.ytmSong && s.confidence >= kBestThreshold),
        isEmpty);

    final charlotte = smartCase('charlotte de witte tomorrowland 2023');
    for (final id in charlotte.expectedFirst!.take(3)) {
      expect(confidenceOf(charlotte, id), greaterThanOrEqualTo(kBestThreshold), reason: id);
    }
  });

  test('a phrase with only the title puts the studio original over the live card', () {
    final c = smartCase('bohemian rhapsody');
    const live = 'fJ9rUzIMcZQ'; // the card's video
    expect(confidenceOf(c, 'BSTsnWoslP4'), greaterThanOrEqualTo(kBestThreshold));
    expect(confidenceOf(c, 'BSTsnWoslP4'), greaterThan(confidenceOf(c, live)));
  });

  test('the first two songs and the card\'s song get a small bonus, a video none', () {
    const r = YtResult(
        id: 'x', title: 'Mother (Live)', channel: 'Pink Floyd', duration: Duration(minutes: 6),
        artists: ['Pink Floyd']);
    final base = queryConfidence('pink floyd mother', r);
    expect(base, lessThan(0.8));
    expect(queryConfidence('pink floyd mother', r, rank: 0), closeTo(base + 0.05, 1e-9));
    expect(queryConfidence('pink floyd mother', r, rank: 1), closeTo(base + 0.03, 1e-9));
    expect(queryConfidence('pink floyd mother', r, rank: 2), base);
    expect(queryConfidence('pink floyd mother', r, fromTopCard: true), closeTo(base + 0.10, 1e-9));
  });

  group('library artist affinity', () {
    YtResult song(String id, String artist) => YtResult(
        id: id,
        title: 'All of Me',
        channel: artist,
        duration: const Duration(minutes: 3),
        artists: [artist]);
    final songs = [song('legend', 'John Legend'), song('billie', 'Billie Holiday')];
    final library = {libraryArtistKey('Billie Holiday')};

    double conf(List<ScoredResult> l, String id) =>
        l.firstWhere((s) => s.result.id == id).confidence;

    test('a title-only phrase puts the library artist\'s version first', () {
      final without = scoreAll('all of me', songs: songs, videos: const []);
      final withLib =
          scoreAll('all of me', songs: songs, videos: const [], libraryArtists: library);
      expect(conf(without, 'legend'), greaterThanOrEqualTo(conf(without, 'billie')));
      expect(conf(withLib, 'billie'), greaterThan(conf(withLib, 'legend')));
    });

    test('a phrase that names an artist is not changed', () {
      final a = scoreAll('john legend all of me', songs: songs, videos: const []);
      final b = scoreAll('john legend all of me',
          songs: songs, videos: const [], libraryArtists: library);
      expect(conf(b, 'legend'), conf(a, 'legend'));
      expect(conf(b, 'billie'), conf(a, 'billie'));
    });

    test('junk below the floor is not lifted by the bonus', () {
      final junk = YtResult(
          id: 'junk',
          title: 'Something else entirely',
          channel: 'Billie Holiday',
          duration: const Duration(minutes: 3),
          artists: const ['Billie Holiday']);
      final scored = scoreAll('all of me',
          songs: [...songs, junk], videos: const [], libraryArtists: library);
      expect(conf(scored, 'junk'), lessThan(kBestThreshold));
    });
  });
}
