import 'package:codecore/services/online/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers from a script: each entry is a status (and a retry-after).
class _Adapter implements HttpClientAdapter {
  _Adapter(this.script);

  final List<(int, String?)> script;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    final (code, retry) = script[calls < script.length ? calls : script.length - 1];
    calls++;
    return ResponseBody.fromString(
      code == 200 ? '{"ok":true}' : 'too many requests',
      code,
      headers: {
        Headers.contentTypeHeader: [code == 200 ? 'application/json' : 'text/plain'],
        if (retry != null) 'retry-after': [retry],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(DioWebClient, _Adapter, List<Duration>) _client(List<(int, String?)> script) {
  final adapter = _Adapter(script);
  final dio = Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter;
  final waits = <Duration>[];
  return (DioWebClient(dio, (d) async => waits.add(d)), adapter, waits);
}

void main() {
  test('a 429 with a short retry-after is waited out and the request retried', () async {
    final (web, adapter, waits) = _client([(429, '4'), (200, null)]);
    expect(await web.getJson('https://x/api'), {'ok': true});
    expect(adapter.calls, 2);
    expect(waits, [const Duration(seconds: 4)]);
  });

  test('without retry-after it waits 2 s; after two retries it gives up with RateLimited', () async {
    final (web, adapter, waits) = _client([(429, null)]);
    await expectLater(web.getJson('https://x/api'), throwsA(isA<RateLimitedException>()));
    expect(adapter.calls, 3, reason: 'the first try and two retries');
    expect(waits, [const Duration(seconds: 2), const Duration(seconds: 2)]);
  });

  test('a long retry-after is not waited: reported at once', () async {
    final (web, adapter, waits) = _client([(429, '120')]);
    await expectLater(web.getJson('https://x/api'), throwsA(isA<RateLimitedException>()));
    expect(adapter.calls, 1);
    expect(waits, isEmpty);
  });

  test('a 403 is never retried', () async {
    final (web, adapter, waits) = _client([(403, null)]);
    await expectLater(web.getJson('https://x/api'), throwsA(isA<RateLimitedException>()));
    expect(adapter.calls, 1);
    expect(waits, isEmpty);
  });
}
