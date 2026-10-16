import 'dart:io';

import 'package:codecore/services/online/cached_youtube_service.dart';
import 'package:codecore/services/online/search_cache.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_test/flutter_test.dart';

YtResult yr(String id) => YtResult(
    id: id,
    title: 'T $id',
    channel: 'C',
    duration: const Duration(seconds: 200),
    artists: const ['A'],
    album: 'Alb');

class Counting implements YoutubeService {
  int songsCalls = 0, plainCalls = 0;

  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) async {
    songsCalls++;
    return query.contains('nothing') ? const [] : [yr('s-$query')];
  }

  @override
  Future<List<YtResult>> search(String query) async {
    plainCalls++;
    return [yr('p-$query')];
  }

  @override
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
          {CancelToken? cancel,
          DownloadOptions options = const DownloadOptions()}) =>
      const Stream.empty();

  @override
  Future<String?> toolVersion() async => null;

  @override
  void close() {}
}

void main() {
  late Directory dir;
  late File file;
  var clock = DateTime(2026, 10, 1);

  SearchCache make({int max = 2000, Duration ttl = const Duration(days: 30)}) =>
      SearchCache(
          file: () async => file,
          max: max,
          ttl: ttl,
          now: () => clock,
          writeDelay: Duration.zero);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_cache');
    file = File('${dir.path}/search_cache.json');
    clock = DateTime(2026, 10, 1);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('hit, miss, and the entry survives a restart', () async {
    final c = make();
    expect(await c.get('k'), isNull);
    await c.put('k', [yr('a'), yr('b')]);
    expect((await c.get('k'))!.map((r) => r.id), ['a', 'b']);
    await c.flush();
    final again = make();
    final back = (await again.get('k'))!;
    expect(back.first.album, 'Alb');
    expect(back.first.duration, const Duration(seconds: 200));
    expect(back.first.artists, ['A']);
  });

  test('entries expire after the time to live', () async {
    final c = make(ttl: const Duration(days: 30));
    await c.put('k', [yr('a')]);
    clock = clock.add(const Duration(days: 29));
    expect(await c.get('k'), isNotNull);
    clock = clock.add(const Duration(days: 2));
    expect(await c.get('k'), isNull);
    expect(await c.count(), 0);
  });

  test('beyond the limit the least recently used entries go', () async {
    final c = make(max: 3);
    for (final k in ['a', 'b', 'c']) {
      clock = clock.add(const Duration(minutes: 1));
      await c.put(k, [yr(k)]);
    }
    clock = clock.add(const Duration(minutes: 1));
    await c.get('a'); // a is now the freshest
    clock = clock.add(const Duration(minutes: 1));
    await c.put('d', [yr('d')]);
    expect(await c.count(), 3);
    expect(await c.get('b'), isNull, reason: 'b was the least recently used');
    expect(await c.get('a'), isNotNull);
    expect(await c.get('d'), isNotNull);
  });

  test('a corrupt file starts an empty cache', () async {
    file.writeAsStringSync('{ this is not json');
    final c = make();
    expect(await c.count(), 0);
    await c.put('k', [yr('a')]);
    await c.flush();
    expect(make().get('k'), completion(isNotNull));
  });

  test('malformed entries are skipped, good ones kept', () async {
    file.writeAsStringSync(
        '{"bad":{"s":"x"},"ok":{"s":1,"u":1,"r":[{"id":"i","title":"t"}]}}');
    final c = make(ttl: const Duration(days: 100000));
    expect(await c.count(), 1);
    expect((await c.get('ok'))!.single.id, 'i');
  });

  test('empty answers are not cached', () async {
    final c = make();
    await c.put('k', const []);
    expect(await c.count(), 0);
  });

  group('CachedYoutubeService', () {
    test('importing the same playlist again makes no network calls', () async {
      final inner = Counting();
      final svc = CachedYoutubeService(inner, make());
      for (var round = 0; round < 2; round++) {
        await svc.searchSongs('band one', limit: 5);
        await svc.search('Band - One');
      }
      expect(inner.songsCalls, 1);
      expect(inner.plainCalls, 1);
    });

    test('queries are normalised, limits and kinds are separate keys',
        () async {
      final inner = Counting();
      final svc = CachedYoutubeService(inner, make());
      await svc.searchSongs('Band  One ', limit: 5);
      await svc.searchSongs('band one', limit: 5);
      await svc.searchSongs('band one', limit: 3);
      expect(inner.songsCalls, 2);
    });

    test('«nothing found» is asked again next time', () async {
      final inner = Counting();
      final svc = CachedYoutubeService(inner, make());
      await svc.searchSongs('nothing here');
      await svc.searchSongs('nothing here');
      expect(inner.songsCalls, 2);
    });

    test('forget drops every answer to those queries', () async {
      final inner = Counting();
      final svc = CachedYoutubeService(inner, make());
      await svc.searchSongs('band one', limit: 5);
      await svc.searchSongs('GBX1', limit: 3);
      await svc.search('Band - One');
      await svc.forget(['band one', 'Band - One']);
      await svc.searchSongs('band one', limit: 5);
      await svc.searchSongs('GBX1', limit: 3);
      await svc.search('Band - One');
      expect(inner.songsCalls, 3, reason: 'only the ISRC answer stayed cached');
      expect(inner.plainCalls, 2);
    });
  });
}
