import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/direct_search_service.dart';
import 'package:codecore/services/online/innertube_client.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real answers (2026-10-20, query «pink floyd mother»), trimmed of the
/// fields the parser does not read.
Map fixture(String name) =>
    jsonDecode(File('test/fixtures/innertube/$name.json').readAsStringSync()) as Map;

/// Answers every request with [respond] and remembers what was sent.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  final ResponseBody Function() respond;
  final sent = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream,
      Future<void>? cancelFuture) async {
    sent.add(options);
    return respond();
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int code = 200]) => ResponseBody.fromString(
    jsonEncode(body), code,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });

(InnerTubeClient, _Adapter) _client(ResponseBody Function() respond) {
  final adapter = _Adapter(respond);
  return (InnerTubeClient(Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter), adapter);
}

/// yt-dlp stand-in: counts the searches it is asked for.
class _YtDlp implements YoutubeService {
  final calls = <String>[];

  @override
  Future<List<YtResult>> search(String query) async {
    calls.add('search:$query');
    return [YtResult(id: 'dlp', title: query, channel: 'c', duration: null)];
  }

  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) async {
    calls.add('songs:$query');
    return [YtResult(id: 'dlp', title: query, channel: 'c', duration: null)];
  }

  @override
  Future<List<YtResult>> searchAlbums(String query, {int limit = 3}) async => const [];

  @override
  Future<List<YtResult>> albumTracks(String albumLink) async => const [];

  @override
  Future<PlaylistListing> listPlaylist(String url, {int limit = 500}) async =>
      const PlaylistListing.empty();

  @override
  Future<List<YtResult>> searchSoundCloud(String query, {int limit = 5}) async => const [];

  @override
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
          {CancelToken? cancel, DownloadOptions options = const DownloadOptions()}) =>
      const Stream.empty();

  @override
  Future<String?> toolVersion() async => null;

  @override
  void close() {}
}

void main() {
  group('YouTube videos', () {
    test('a real answer: id, title, channel, length and the small thumbnail', () {
      final res = parseVideoSearch(fixture('yt_search'));
      expect(res, hasLength(10), reason: 'as many as ytsearch10 gave');
      final first = res.first;
      expect(first.id, 'o7MlC_Qrmmc');
      expect(first.title, 'Mother');
      expect(first.channel, 'Pink Floyd');
      expect(first.duration, const Duration(minutes: 5, seconds: 35));
      expect(first.thumbnailUrl, 'https://i.ytimg.com/vi/o7MlC_Qrmmc/mqdefault.jpg');
      expect(first.source, MediaSource.youtube);
      expect(res.map((r) => r.id).toSet(), hasLength(10), reason: 'no duplicates');
    });

    test('a known answer without videos is «no results»; an unknown one is a change', () {
      expect(parseVideoSearch(fixture('yt_empty')), isEmpty);
      expect(() => parseVideoSearch({'contents': {'somethingNew': {}}}),
          throwsA(isA<InnerTubeChanged>()));
      expect(() => parseVideoSearch(fixture('ytm_songs')), throwsA(isA<InnerTubeChanged>()));
    });
  });

  group('YouTube Music songs', () {
    test('a real answer: artists, album and length from the second column', () {
      final res = parseSongSearch(fixture('ytm_songs'), limit: 20);
      expect(res, hasLength(20));
      final mother = res.first;
      expect(mother.id, 'o7MlC_Qrmmc');
      expect(mother.title, 'Mother');
      expect(mother.artists, ['Pink Floyd']);
      expect(mother.channel, 'Pink Floyd');
      expect(mother.album, 'The Wall');
      expect(mother.duration, const Duration(minutes: 5, seconds: 35));
      expect(mother.thumbnailUrl, contains('w120-h120'));
      final pinkMatter = res[1];
      expect(pinkMatter.title, 'Pink Matter (con André 3000)');
      expect(pinkMatter.artists, ['Frank Ocean']);
      expect(pinkMatter.album, 'channel ORANGE');
      expect(pinkMatter.duration, const Duration(minutes: 4, seconds: 29));
      expect(res.every((r) => r.duration != null && r.album != null), isTrue);
    });

    test('limit is honoured', () {
      expect(parseSongSearch(fixture('ytm_songs'), limit: 5), hasLength(5));
    });

    test('artists without a page of their own are still read, joiners left out', () {
      final item = {
        'playlistItemData': {'videoId': 'abc'},
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [{'text': 'Song'}]
              }
            }
          },
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Uno'},
                  {'text': ', '},
                  {'text': 'Due'},
                  {'text': ' & '},
                  {'text': 'Tre'},
                  {'text': ' • '},
                  {'text': '1:02:03'},
                ]
              }
            }
          },
        ],
      };
      final res = parseSongSearch({
        'contents': {
          'tabbedSearchResultsRenderer': {
            'list': [
              {'musicResponsiveListItemRenderer': item}
            ]
          }
        }
      });
      expect(res.single.artists, ['Uno', 'Due', 'Tre']);
      expect(res.single.album, isNull);
      expect(res.single.duration, const Duration(hours: 1, minutes: 2, seconds: 3));
      expect(res.single.thumbnailUrl, smallVideoThumbnail('abc'),
          reason: 'no cover offered: the video picture');
    });

    test('an unknown answer is a change', () {
      expect(() => parseSongSearch(fixture('yt_search')), throwsA(isA<InnerTubeChanged>()));
    });
  });

  test('parseClock', () {
    expect(parseClock('3:45'), const Duration(minutes: 3, seconds: 45));
    expect(parseClock(' 1:02:03 '), const Duration(hours: 1, minutes: 2, seconds: 3));
    expect(parseClock('LIVE'), isNull);
    expect(parseClock('54 Mln riproduzioni'), isNull);
  });

  group('requests', () {
    test('one POST to the right site with the query and the filter', () async {
      final (client, adapter) = _client(() => _json(fixture('ytm_songs')));
      final res = await client.searchSongs('pink floyd mother', limit: 3);
      expect(res, hasLength(3));
      final sent = adapter.sent.single;
      expect(sent.method, 'POST');
      expect(sent.uri.toString(), 'https://music.youtube.com/youtubei/v1/search?prettyPrint=false');
      final body = sent.data as Map;
      expect(body['query'], 'pink floyd mother');
      expect(body['params'], InnerTubeClient.songsFilter);
      expect((body['context'] as Map)['client'], containsPair('clientName', 'WEB_REMIX'));

      final (videos, adapter2) = _client(() => _json(fixture('yt_search')));
      await videos.searchVideos('x');
      expect(adapter2.sent.single.uri.host, 'www.youtube.com');
      expect((adapter2.sent.single.data as Map)['params'], InnerTubeClient.videosFilter);
    });

    test('429 is a rate limit; other refusals and odd bodies are a change', () async {
      final (limited, _) = _client(() => _json({}, 429));
      await expectLater(limited.searchVideos('x'),
          throwsA(isA<YtException>().having((e) => e.kind, 'kind', YtErrorKind.rateLimited)));
      final (refused, _) = _client(() => _json({}, 403));
      await expectLater(refused.searchVideos('x'), throwsA(isA<InnerTubeChanged>()));
      final (html, _) = _client(() => ResponseBody.fromString('<html>consent</html>', 200,
          headers: {
            Headers.contentTypeHeader: ['text/html']
          }));
      await expectLater(html.searchSongs('x'), throwsA(isA<InnerTubeChanged>()));
    });

    test('no connection is a network error (yt-dlp would fail too)', () async {
      final (client, _) = _client(() => throw const SocketException('no route'));
      await expectLater(client.searchVideos('x'),
          throwsA(isA<YtException>().having((e) => e.kind, 'kind', YtErrorKind.network)));
    });
  });

  group('DirectSearchService', () {
    test('direct answers do not start yt-dlp; addresses still go to yt-dlp', () async {
      final ytDlp = _YtDlp();
      final (client, adapter) = _client(() => _json(fixture('yt_search')));
      final svc = DirectSearchService(ytDlp, client);
      expect((await svc.search(' pink floyd mother ')).first.id, 'o7MlC_Qrmmc');
      expect(ytDlp.calls, isEmpty);
      expect((adapter.sent.single.data as Map)['query'], 'pink floyd mother');
      await svc.search('https://www.youtube.com/watch?v=o7MlC_Qrmmc');
      expect(ytDlp.calls, ['search:https://www.youtube.com/watch?v=o7MlC_Qrmmc']);
      expect(adapter.sent, hasLength(1));
    });

    test('an unreadable answer falls back to yt-dlp, which is then used alone for a while',
        () async {
      var now = DateTime(2026, 10, 20, 12);
      final ytDlp = _YtDlp();
      final (client, adapter) = _client(() => _json({'contents': {}}));
      final svc = DirectSearchService(ytDlp, client,
          cooldown: const Duration(minutes: 10), now: () => now);
      expect((await svc.searchSongs('a', limit: 3)).single.id, 'dlp');
      expect(ytDlp.calls, ['songs:a']);
      expect(adapter.sent, hasLength(1));

      now = now.add(const Duration(minutes: 9));
      await svc.search('b');
      expect(ytDlp.calls, ['songs:a', 'search:b']);
      expect(adapter.sent, hasLength(1), reason: 'not asked again during the pause');

      now = now.add(const Duration(minutes: 2));
      await svc.searchSongs('c');
      expect(adapter.sent, hasLength(2), reason: 'tried again after the pause');
      expect(ytDlp.calls.last, 'songs:c');
    });

    test('a rate limit or no connection is reported, not retried with yt-dlp', () async {
      final ytDlp = _YtDlp();
      final (client, _) = _client(() => _json({}, 429));
      final svc = DirectSearchService(ytDlp, client);
      await expectLater(svc.searchSongs('a'), throwsA(isA<YtException>()));
      expect(ytDlp.calls, isEmpty);
    });
  });
}
