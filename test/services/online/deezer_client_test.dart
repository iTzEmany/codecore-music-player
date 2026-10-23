import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/deezer_client.dart';
import 'package:codecore/services/online/http_client.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_test/flutter_test.dart';

Object _fixture(String name) =>
    jsonDecode(File('test/fixtures/deezer/$name.json').readAsStringSync())
        as Object;

class _Web implements WebClient {
  _Web(this.answer);

  /// null mimics DioWebClient on a timeout.
  final Object? answer;
  int calls = 0;

  @override
  Future<Object?> getJson(
    String url, {
    Map<String, String>? query,
    CancelToken? cancel,
  }) async {
    calls++;
    return answer;
  }

  @override
  Future<List<int>?> getBytes(
    String url, {
    int maxBytes = 0,
    CancelToken? cancel,
  }) async => null;
}

void main() {
  test('ISRC found: the fields are parsed', () async {
    final t = await DeezerClient(_Web(_fixture('track_isrc_corsi')))
        .trackByIsrc('ITZ042500021');
    expect(t!.title, 'Sigarette');
    expect(t.artist, 'Lucio Corsi');
    expect(t.duration, 179);
    expect(t.isrc, 'ITZ042500021');
    expect((t.trackPosition, t.diskNumber), (2, 1));
    expect(t.album!.id, 730631321);
    expect(t.album!.title, 'Volevo essere un duro');
    expect(t.album!.releaseDate, '2025-03-20');
    expect(t.album!.coverXl, contains('1000x1000'));
  });

  test('code 800: no data, null', () async {
    expect(
      await DeezerClient(_Web(_fixture('error_no_data'))).trackByIsrc('X'),
      isNull,
    );
  });

  test(
    'code 4: RateLimitedException, then 10 minutes without asking',
    () async {
      var now = DateTime(2026);
      final web = _Web(_fixture('error_quota'));
      final c = DeezerClient(web, now: () => now);
      await expectLater(
        c.trackByIsrc('X'),
        throwsA(isA<RateLimitedException>()),
      );
      await expectLater(c.album(1), throwsA(isA<RateLimitedException>()));
      expect(web.calls, 1);
      now = now.add(DeezerClient.cooldown);
      await expectLater(c.album(1), throwsA(isA<RateLimitedException>()));
      expect(web.calls, 2);
    },
  );

  test('timeout: a network error, not null', () async {
    await expectLater(
      DeezerClient(_Web(null)).trackByIsrc('X'),
      throwsA(isA<DeezerNetworkException>()),
    );
  });

  test('album: record type, track count and genres', () async {
    final a = await DeezerClient(_Web(_fixture('album_signature_box')))
        .album(1);
    expect(a!.recordType, 'album');
    expect(a.nbTracks, 119);
  });

  test('search: the data list is parsed', () async {
    final r = await DeezerClient(_Web(_fixture('search_viva_la_vida')))
        .searchTracks('x');
    expect(r.length, greaterThan(1));
    expect(r.first.artist, 'Party Machine');
  });
}
