import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/innertube_client.dart';
import 'package:codecore/services/online/ytm_lyrics_parser.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Map _json(String name) =>
    jsonDecode(File('test/fixtures/innertube/$name.json').readAsStringSync()) as Map;

/// `next` then `browse`, as the saved answers; remembers what was asked.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.next);

  final String next;
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    paths.add(o.uri.pathSegments.last);
    final body = o.uri.pathSegments.last == 'next' ? _json(next) : _json('ytm_lyrics_browse');
    return ResponseBody.fromString(jsonEncode(body), 200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('the text has plain \\n lines and not the «Fonte» footer', () {
    final text = parseLyrics(_json('ytm_lyrics_browse'))!;
    expect(text, isNot(contains('\r')));
    expect(text, isNot(contains('LyricFind')));
    expect(text.split('\n').length, greaterThan(10));
  });

  test('a song without the «Testo» tab has no lyrics page', () {
    expect(lyricsBrowseId(_json('ytm_next_no_lyrics')), isNull);
    expect(lyricsBrowseId(_json('ytm_next_lyrics_tab')), startsWith('MPLY'));
  });

  test('two lines are not lyrics', () {
    final page = {
      'musicDescriptionShelfRenderer': {
        'description': {'runs': [{'text': 'one\r\ntwo'}]}
      }
    };
    expect(parseLyrics(page), isNull);
  });

  test('the client asks next and then the lyrics page', () async {
    final a = _Adapter('ytm_next_lyrics_tab');
    final text = await InnerTubeClient(Dio()..httpClientAdapter = a).lyrics('vid');
    expect(a.paths, ['next', 'browse']);
    expect(text, isNotNull);
  });

  test('the client stops after next when there is no tab', () async {
    final a = _Adapter('ytm_next_no_lyrics');
    expect(await InnerTubeClient(Dio()..httpClientAdapter = a).lyrics('vid'), isNull);
    expect(a.paths, ['next']);
  });
}
