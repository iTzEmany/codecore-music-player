import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/innertube_client.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/online/ytm_radio_parser.dart';
import 'package:codecore/services/online/ytm_radio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real answers (2026-10-22, radio of «Mother», Pink Floyd), trimmed.
Map fixture(String name) =>
    jsonDecode(File('test/fixtures/innertube/$name.json').readAsStringSync()) as Map;

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

ResponseBody _json(Object body) => ResponseBody.fromString(jsonEncode(body), 200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });

(InnerTubeClient, _Adapter) _client(ResponseBody Function() respond) {
  final a = _Adapter(respond);
  return (InnerTubeClient(Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = a), a);
}

class _Mix implements YoutubeService {
  final urls = <String>[];

  @override
  Future<PlaylistListing> listPlaylist(String url, {int limit = 500}) async {
    urls.add(url);
    return PlaylistListing(title: 'Mix', entries: [
      for (final id in ['seed', 'b']) YtResult(id: id, title: id, channel: 'c', duration: null),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

void main() {
  test('the radio of a song: 15 songs, the first is the seed, credits read', () {
    final page = parseRadio(fixture('ytm_radio'));
    expect(page.items, hasLength(15));
    expect(page.items.every((i) => i.kind == RadioKind.song), isTrue);
    expect(page.items.where((i) => i.isSeed).map((i) => i.result.id), ['o7MlC_Qrmmc']);
    final seed = page.items.first.result;
    expect(seed.title, 'Mother');
    expect(seed.artists, ['Pink Floyd']);
    expect(seed.artistIds, ['UCO6LS_5W7vqG9mALDNzSFug']);
    expect(seed.album, 'The Wall');
    expect(seed.albumId, startsWith('MPREb_'));
    expect(seed.duration, const Duration(minutes: 5, seconds: 35));
    expect(seed.thumbnailUrl, contains('googleusercontent'));
    expect(page.continuation, isNotEmpty);
  });

  test('the radio of a video clip has no songs: artist videos and uploads', () {
    final page = parseRadio(fixture('ytm_radio_video_seed'));
    expect(page.items, hasLength(10));
    expect(page.items.where((i) => i.kind == RadioKind.song), isEmpty);
    expect(page.items.first.kind, RadioKind.upload, reason: 'the clip is a user channel');
    expect(page.items[1].kind, RadioKind.artistVideo);
    expect(page.items[1].result.album, isNull);
    expect(page.items[1].result.artists, isEmpty, reason: 'a channel is not a credit');
    expect(page.items[1].result.channel, 'PINK FLOYD');
  });

  test('a mixed page tells songs, artist videos and uploads apart', () {
    final kinds = parseRadio(fixture('ytm_radio_discover')).items.map((i) => i.kind).toSet();
    expect(kinds, containsAll([RadioKind.song, RadioKind.artistVideo]));
  });

  test('a continuation page is read and points to the next one', () {
    final page = parseRadioContinuation(fixture('ytm_radio_continuation'));
    expect(page.items, hasLength(15));
    expect(page.items.any((i) => i.isSeed), isFalse);
    expect(page.continuation, isNotEmpty);
  });

  test('an unknown answer is a changed format', () {
    expect(() => parseRadio({'contents': {'other': {}}}), throwsA(isA<InnerTubeChanged>()));
    expect(() => parseRadio(fixture('ytm_empty')), throwsA(isA<InnerTubeChanged>()));
    expect(() => parseRadioContinuation({'x': 1}), throwsA(isA<InnerTubeChanged>()));
  });

  test('radio asks with the song seed and the mask, then in full when masked is empty', () async {
    var n = 0;
    final (client, adapter) = _client(() {
      n++;
      return _json(n == 1
          ? {'contents': {'singleColumnMusicWatchNextResultsRenderer': {'tabbedRenderer': {'watchNextTabbedResultsRenderer': {'tabs': [
              {'tabRenderer': {'content': {'musicQueueRenderer': {'content': {'playlistPanelRenderer': {'contents': []}}}}}},
            ]}}}}}
          : fixture('ytm_radio'));
    });
    final page = await client.radio('o7MlC_Qrmmc');
    expect(page.items, hasLength(15));
    expect(adapter.sent, hasLength(2));
    final body = adapter.sent.first.data as Map;
    expect(body['videoId'], 'o7MlC_Qrmmc');
    expect(body['playlistId'], 'RDAMVMo7MlC_Qrmmc');
    expect(body['params'], 'wAEB');
    expect(adapter.sent.first.headers['X-Goog-FieldMask'], radioMask);
    expect(adapter.sent.last.headers.containsKey('X-Goog-FieldMask'), isFalse);
    expect(adapter.sent.first.uri.path, endsWith('/next'));
  });

  test('a continuation request carries only the token', () async {
    final (client, adapter) = _client(() => _json(fixture('ytm_radio_continuation')));
    await client.radio('o7MlC_Qrmmc', continuation: 'tok');
    expect((adapter.sent.single.data as Map)['continuation'], 'tok');
    expect((adapter.sent.single.data as Map).containsKey('videoId'), isFalse);
  });

  test('unreadable direct radio falls back to the yt-dlp mix for 10 minutes', () async {
    var now = DateTime.utc(2026, 1, 1);
    final (client, adapter) = _client(() => _json({'unexpected': true}));
    final mix = _Mix();
    final service = YtmRadioService(client, mix, now: () => now);

    final first = await service.page('seed');
    expect(first.items.map((i) => i.result.id), ['seed', 'b']);
    expect(first.items.first.isSeed, isTrue);
    expect(first.items.every((i) => i.kind == RadioKind.artistVideo), isTrue);
    expect(mix.urls.single, 'https://music.youtube.com/watch?v=seed&list=RDAMVMseed');

    final requests = adapter.sent.length;
    await service.page('seed');
    expect(adapter.sent, hasLength(requests), reason: 'direct is off during the cooldown');
    expect(mix.urls, hasLength(2));

    now = now.add(const Duration(minutes: 11));
    await service.page('seed');
    expect(adapter.sent.length, greaterThan(requests), reason: 'tried again after 10 min');
  });
}
