import 'dart:io';

import 'package:codecore/services/online/deezer_client.dart';
import 'package:codecore/services/online/deezer_gw_client.dart';
import 'package:codecore/services/online/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String fx(String n) => File('test/fixtures/deezer/$n.json').readAsStringSync();

/// Answers by `method` query parameter; [pageTrack] is a queue of bodies.
class _Adapter implements HttpClientAdapter {
  final sent = <RequestOptions>[];
  final pageTrack = <ResponseBody Function()>[];
  int sessions = 0;
  bool down = false;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    sent.add(o);
    if (down) throw DioException(requestOptions: o, type: DioExceptionType.connectionError);
    if (o.queryParameters['method'] == 'deezer.getUserData') {
      sessions++;
      return ResponseBody.fromString(fx('gw_user_data'), 200, headers: {
        'set-cookie': ['sid=fr1abc; path=/; Secure; HttpOnly'],
      });
    }
    return pageTrack.removeAt(0)();
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody Function() _ok(String name) => () => ResponseBody.fromString(fx(name), 200);
ResponseBody _badToken() => ResponseBody.fromString(fx('gw_invalid_token'), 200);

void main() {
  late _Adapter adapter;
  late DateTime clock;
  late int paused;

  DeezerGwClient make() => DeezerGwClient(
        dio: Dio()..httpClientAdapter = adapter,
        now: () => clock,
        onPaused: () => paused++,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    adapter = _Adapter();
    clock = DateTime(2026, 10, 25, 12);
    paused = 0;
  });

  test('opens a session and reads the contributors, sending cookie and token', () async {
    adapter.pageTrack.add(_ok('gw_page_track_lose_yourself'));
    final r = await make().pageTrack(1109731);
    expect(r.credits, isNotEmpty);
    final call = adapter.sent.last;
    expect(call.queryParameters['api_token'], 'FAKE_CHECKFORM');
    expect(call.headers['Cookie'], 'sid=fr1abc');
    expect(call.data, '{"sng_id":"1109731"}');
  });

  test('an expired token renews the session once, then fails', () async {
    final c = make();
    adapter.pageTrack.addAll([_badToken, _ok('gw_page_track_lose_yourself')]);
    await c.pageTrack(1);
    expect(adapter.sessions, 2); // 1 initial + 1 renewal
    adapter.pageTrack.addAll([_badToken, _badToken]);
    await expectLater(c.pageTrack(1), throwsA(isA<DeezerGwTokenException>()));
    expect(adapter.sessions, 3); // initial 1 + renewal 1, then exactly one more
  });

  test('3 errors in a row pause 24 h, also for a new client; calls resume after', () async {
    adapter.down = true;
    final c = make();
    for (var i = 0; i < 3; i++) {
      await expectLater(c.pageTrack(1), throwsA(isA<DeezerNetworkException>()));
    }
    expect(paused, 1);
    expect(c.isPaused, isTrue);
    final calls = adapter.sent.length;

    await expectLater(c.pageTrack(1), throwsA(isA<DeezerGwPausedException>()));
    final fresh = make();
    await expectLater(fresh.pageTrack(1), throwsA(isA<DeezerGwPausedException>()));
    expect(adapter.sent.length, calls);

    clock = clock.add(const Duration(hours: 24, milliseconds: 1));
    adapter.down = false;
    adapter.pageTrack.add(_ok('gw_page_track_one_more_time'));
    await fresh.pageTrack(1);
    expect(fresh.isPaused, isFalse);
  });

  test('a success resets the error count; 429 is not counted and not network', () async {
    final c = make();
    adapter.down = true;
    for (var i = 0; i < 2; i++) {
      await expectLater(c.pageTrack(1), throwsA(isA<DeezerNetworkException>()));
    }
    adapter.down = false;
    adapter.pageTrack.add(_ok('gw_page_track_one_more_time'));
    await c.pageTrack(1);
    adapter.pageTrack.addAll(List.generate(3, (_) => () => ResponseBody.fromString('', 429)));
    for (var i = 0; i < 3; i++) {
      await expectLater(c.pageTrack(1), throwsA(isA<RateLimitedException>()));
    }
    adapter.down = true;
    await expectLater(c.pageTrack(1), throwsA(isA<DeezerNetworkException>()));
    expect(paused, 0);
  });

  test('G4 still paused after 23 h', () async {
    adapter.down = true;
    final c = make();
    for (var i = 0; i < 3; i++) {
      await expectLater(c.pageTrack(1), throwsA(isA<DeezerNetworkException>()));
    }
    clock = clock.add(const Duration(hours: 23));
    await expectLater(c.pageTrack(1), throwsA(isA<DeezerGwPausedException>()));
    expect(make().isPaused, isFalse); // not loaded yet
  });

  test('G10 after the pause ends one error does not pause again', () async {
    adapter.down = true;
    final c = make();
    for (var i = 0; i < 3; i++) {
      await expectLater(c.pageTrack(1), throwsA(isA<DeezerNetworkException>()));
    }
    clock = clock.add(const Duration(hours: 25));
    await expectLater(c.pageTrack(1), throwsA(isA<DeezerNetworkException>()));
    expect(paused, 1);
    expect(c.isPaused, isFalse);
  });
}
