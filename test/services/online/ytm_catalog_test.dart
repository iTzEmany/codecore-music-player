import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/catalog_cache.dart';
import 'package:codecore/services/online/direct_search_service.dart';
import 'package:codecore/services/online/innertube_client.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/online/ytm_catalog.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Map fixture(String name) =>
    jsonDecode(File('test/fixtures/innertube/$name.json').readAsStringSync()) as Map;

const pinkFloyd = 'UCO6LS_5W7vqG9mALDNzSFug';

/// Answers each request with [respond]; remembers what was sent.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  Object? Function(RequestOptions o) respond;
  final sent = <RequestOptions>[];
  bool offline = false;
  int status = 200;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream,
      Future<void>? cancelFuture) async {
    sent.add(options);
    if (offline) {
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError, error: const SocketException('x'));
    }
    return ResponseBody.fromString(jsonEncode(respond(options)), status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

class _YtDlp implements YoutubeService {
  final links = <String>[];

  @override
  Future<List<YtResult>> albumTracks(String albumLink) async {
    links.add(albumLink);
    return [
      for (final t in ['One', 'Two'])
        YtResult(id: t, title: t, channel: 'c', duration: null, artists: const ['Band'], album: 'Rec'),
    ];
  }

  @override
  Future<List<YtResult>> search(String query) async => const [];

  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) async => const [];

  @override
  Future<List<YtResult>> searchAlbums(String query, {int limit = 3}) async => const [];

  @override
  Future<PlaylistListing> listPlaylist(String url, {int limit = 500}) async =>
      const PlaylistListing.empty();


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
  late Directory dir;
  late _Adapter adapter;
  late _YtDlp ytDlp;
  late YtmCatalog catalog;
  late CatalogCache cache;
  late InnerTubeClient client;
  var clock = DateTime(2026, 10, 1);

  bool masked(RequestOptions o) => o.headers['X-Goog-FieldMask'] != null;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_ytm');
    clock = DateTime(2026, 10, 1);
    adapter = _Adapter((o) => fixture('ytm_artist_page'));
    ytDlp = _YtDlp();
    cache = CatalogCache(
        file: () async => File('${dir.path}/c.json'),
        now: () => clock,
        writeDelay: Duration.zero);
    client = InnerTubeClient(Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter);
    catalog = YtmCatalog(client, ytDlp, cache, now: () => clock);
  });
  tearDown(() async {
    // A write still running keeps the file open, which Windows cannot delete.
    await cache.dispose();
    dir.deleteSync(recursive: true);
  });

  test('the top card of a search is read from the masked answer, one request', () async {
    adapter.respond = (o) => fixture('ytm_top_album_card');
    final card = await catalog.topCard('the wall', 'en');
    expect(card, isA<TopAlbum>());
    expect(adapter.sent, hasLength(1));
    expect(adapter.sent.single.headers['X-Goog-FieldMask'], contains('musicCardShelfRenderer'));
  });

  test('an empty masked answer is asked again in full, in the language given', () async {
    adapter.respond = (o) => masked(o) ? {} : fixture('ytm_artist_page_it');
    final r = await catalog.artist('UCmUrlA_x25EXhvlsRHmC3bw', 'it');
    expect(r.value.shelves, isNotEmpty);
    expect(adapter.sent.map(masked), [true, false]);
    final body = adapter.sent.first.data as Map;
    expect(body['browseId'], 'UCmUrlA_x25EXhvlsRHmC3bw');
    expect(((body['context'] as Map)['client'] as Map)['hl'], 'it');
  });

  test('an artist that does not exist is final: no yt-dlp, nothing cached', () async {
    adapter.respond = (o) => fixture('ytm_artist_missing');
    await expectLater(catalog.artist('nope', 'en'), throwsA(isA<ArtistNotFound>()));
    expect(ytDlp.links, isEmpty);
    adapter.sent.clear();
    await expectLater(catalog.artist('nope', 'en'), throwsA(isA<ArtistNotFound>()));
    expect(adapter.sent, isNotEmpty, reason: 'nothing was kept');
  });

  test('an album page that cannot be read comes from yt-dlp, once', () async {
    adapter.respond = (o) => {'contents': {'somethingNew': {}}};
    final r = await catalog.album('MPREb_x', 'en');
    expect(ytDlp.links, ['https://music.youtube.com/browse/MPREb_x']);
    expect(r.value.title, 'Rec');
    expect(r.value.tracks.map((t) => t.result.id), ['One', 'Two']);
    expect(r.value.tracks.every((t) => t.number == null), isTrue);
    await catalog.album('MPREb_x', 'en');
    expect(ytDlp.links, hasLength(1), reason: 'the second opening comes from the cache');
  });

  test('the second opening needs no request; refresh asks again', () async {
    final first = await catalog.artist(pinkFloyd, 'en');
    expect(first.stale, isFalse);
    final sentBefore = adapter.sent.length;
    final again = await catalog.artist(pinkFloyd, 'en');
    expect(adapter.sent, hasLength(sentBefore));
    expect(again.fetchedAt, first.fetchedAt);
    await catalog.artist(pinkFloyd, 'en', refresh: true);
    expect(adapter.sent.length, greaterThan(sentBefore));
  });

  test('offline: an expired copy is shown as stale, no copy is the error', () async {
    await catalog.artist(pinkFloyd, 'en');
    clock = clock.add(const Duration(days: 5));
    adapter.offline = true;
    final r = await catalog.artist(pinkFloyd, 'en');
    expect(r.stale, isTrue);
    expect(r.fetchedAt, DateTime(2026, 10, 1));
    expect(r.value.ref.id, pinkFloyd);
    await expectLater(catalog.artist('other', 'en'),
        throwsA(isA<YtException>().having((e) => e.kind, 'kind', YtErrorKind.network)));
  });

  test('offline: the artist lookup by name finds an artist whose page was opened', () async {
    final page = await catalog.artist(pinkFloyd, 'en');
    adapter.offline = true;
    final found = await catalog.searchArtists(page.value.ref.name.toUpperCase(), 'en');
    expect(found.single.id, pinkFloyd);
    await expectLater(catalog.searchArtists('Unknown Band', 'en'),
        throwsA(isA<YtException>().having((e) => e.kind, 'kind', YtErrorKind.network)));
  });

  test('a rate limit with a saved copy shows the copy', () async {
    await catalog.artist(pinkFloyd, 'en');
    clock = clock.add(const Duration(days: 5));
    adapter.status = 429;
    final r = await catalog.artist(pinkFloyd, 'en');
    expect(r.stale, isTrue);
  });

  group('DirectSearchService.albumTracks', () {
    test('an MPREb_ link is read directly, in album order', () async {
      adapter.respond = (o) => fixture('ytm_album_page');
      final svc = DirectSearchService(ytDlp, client, catalog: catalog);
      final tracks = await svc.albumTracks('https://music.youtube.com/browse/MPREb_tc3z4MYeOpY');
      expect(tracks, hasLength(26));
      expect(tracks.first.title, 'In the Flesh?');
      expect(ytDlp.links, isEmpty);
    });

    test('any other link still goes to yt-dlp', () async {
      final svc = DirectSearchService(ytDlp, client, catalog: catalog);
      await svc.albumTracks('https://music.youtube.com/playlist?list=OLAK5uy_x');
      expect(ytDlp.links, hasLength(1));
      expect(adapter.sent, isEmpty);
    });
  });
}
