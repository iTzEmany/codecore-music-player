import 'package:codecore/services/online/itunes_client.dart';
import 'package:codecore/services/online/lrc_parser.dart';
import 'package:codecore/services/online/lrclib_client.dart';
import 'package:codecore/services/online/wikipedia_client.dart';
import 'package:codecore/services/online/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeWeb implements WebClient {
  FakeWeb(this.handler);

  final Object? Function(String url, Map<String, String> q) handler;
  final calls = <String>[];

  @override
  Future<Object?> getJson(String url,
      {Map<String, String>? query, CancelToken? cancel}) async {
    calls.add('$url ${query ?? {}}');
    return handler(url, query ?? {});
  }

  @override
  Future<List<int>?> getBytes(String url,
          {int maxBytes = 0, CancelToken? cancel}) async =>
      null;
}

Map<String, Object?> song(String t, String a, {String? album}) => {
      'trackName': t,
      'artistName': a,
      'collectionName': album ?? 'Alb (Deluxe Edition)',
      'releaseDate': '2015-05-01T07:00:00Z',
      'primaryGenreName': 'Alternative',
      'trackNumber': 3,
      'artworkUrl100': 'https://x/100x100bb.jpg',
    };

void main() {
  group('iTunes', () {
    test('exact match', () async {
      final web = FakeWeb((_, _) => {
            'results': [song('Car Radio', 'twenty one pilots')]
          });
      final m = await ItunesClient(web).search('Car Radio', 'twenty one pilots');
      expect(m!.album, 'Alb');
      expect(m.year, 2015);
      expect(m.artworkUrl, 'https://x/600x600bb.jpg');
    });

    test('same title different artist -> null', () async {
      final web = FakeWeb((_, _) => {
            'results': [song('Car Radio', 'Someone Else')]
          });
      expect(await ItunesClient(web).search('Car Radio', 'twenty one pilots'),
          isNull);
    });

    test('no results -> null', () async {
      final web = FakeWeb((_, _) => {'results': []});
      expect(await ItunesClient(web).search('X Y', 'Z'), isNull);
    });

    test('generic title with unknown artist never takes another artist',
        () async {
      final web = FakeWeb((_, _) => {
            'results': [song('Intro', 'Other Band')]
          });
      expect(await ItunesClient(web).search('Intro', ''), isNull);
    });

    test('query order and dedupe', () {
      final q = ItunesClient(FakeWeb((_, _) => null))
          .buildQueries('Song (Live)', 'A & B');
      expect(q.first, 'A & B Song (Live)');
      expect(q, contains('A Song'));
      expect(q.toSet().length, q.length);
    });
  });

  group('LRC', () {
    test('multiple stamps, ms digits, offset, tags', () {
      const raw = '[ar:Someone]\n[offset:500]\n[00:10.50]Hello\n'
          '[00:20.123][01:00.00]Again\n\n[00:05]First\n';
      final l = parseLrc(raw);
      expect(l.map((e) => e.text), ['First', 'Hello', 'Again', 'Again']);
      expect(l[0].time, const Duration(milliseconds: 4500));
      expect(l[1].time, const Duration(milliseconds: 10000));
      expect(l[2].time, const Duration(milliseconds: 19623));
    });

    test('currentLrcIndex', () {
      final l = parseLrc('[00:01.00]a\n[00:03.00]b');
      expect(currentLrcIndex(l, Duration.zero), -1);
      expect(currentLrcIndex(l, const Duration(seconds: 2)), 0);
      expect(currentLrcIndex(l, const Duration(seconds: 9)), 1);
    });
  });

  group('LRCLIB', () {
    test('accepts matching artist/duration', () async {
      final web = FakeWeb((u, _) => u.endsWith('/get')
          ? {
              'artistName': 'Queen',
              'duration': 355,
              'plainLyrics': 'x',
              'syncedLyrics': '[00:01.00]x'
            }
          : null);
      final r = await LrclibClient(web)
          .find(title: 'Bohemian', artist: 'Queen', durationSec: 354);
      expect(r!.synced, isNotNull);
    });

    test('rejects other artist or far duration', () async {
      final web = FakeWeb((u, _) => {
            'artistName': 'Other',
            'duration': 100,
            'plainLyrics': 'x'
          });
      expect(
          await LrclibClient(web)
              .find(title: 'T', artist: 'Queen', durationSec: 100),
          isNull);
      final web2 = FakeWeb((u, _) =>
          {'artistName': 'Queen', 'duration': 200, 'plainLyrics': 'x'});
      expect(
          await LrclibClient(web2)
              .find(title: 'T', artist: 'Queen', durationSec: 100),
          isNull);
    });
  });

  test('Wikipedia skips short and disambiguation pages', () async {
    final long = 'A song by the band. ' * 10;
    final web = FakeWeb((u, q) {
      if (q['list'] == 'search') {
        return {
          'query': {
            'search': [
              {'title': 'Short'},
              {'title': 'Real Song'}
            ]
          }
        };
      }
      final title = q['titles'];
      return {
        'query': {
          'pages': {
            '1': {'extract': title == 'Short' ? 'tiny' : long}
          }
        }
      };
    });
    final c = await WikipediaClient(web).find('Real Song', 'Band', 'en');
    expect(c!.source.toString(), 'https://en.wikipedia.org/wiki/Real_Song');
    expect(c.text.length, lessThanOrEqualTo(1000));
  });
}
