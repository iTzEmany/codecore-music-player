import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/request_budget.dart' show apiUserAgent;
import 'package:codecore/services/radio/radio_browser_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers by host + path with [routes] (a missing route is a 404) and
/// remembers every request.
class RadioAdapter implements HttpClientAdapter {
  RadioAdapter(this.routes);

  final Map<String, ResponseBody Function()> routes;
  final sent = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream,
      Future<void>? cancelFuture) async {
    sent.add(options);
    final route = routes['${options.uri.host}${options.uri.path}'] ??
        routes[options.uri.host] ??
        () => radioJson({}, 404);
    return route();
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody radioJson(Object body, [int code = 200, Map<String, List<String>>? headers]) =>
    ResponseBody.fromString(jsonEncode(body), code, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...?headers,
    });

Object fixture(String name) =>
    jsonDecode(File('test/fixtures/radio/$name.json').readAsStringSync()) as Object;

ResponseBody Function() down() =>
    () => throw DioException.connectionError(requestOptions: RequestOptions(), reason: 'down');

RadioBrowserClient clientOver(RadioAdapter a) => RadioBrowserClient(
    Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = a,
    minGap: Duration.zero);

const _discovery = 'all.api.radio-browser.info/json/servers';

void main() {
  test('the fixtures are read: servers, countries, states, stations, search and uuids', () async {
    final a = RadioAdapter({
      _discovery: () => radioJson(fixture('servers')),
      'de1.api.radio-browser.info/json/countries': () => radioJson(fixture('countries')),
      'de1.api.radio-browser.info/json/states/Italy/': () => radioJson(fixture('states_italy')),
      'de1.api.radio-browser.info/json/stations/search': () => radioJson(fixture('stations_it')),
      'de1.api.radio-browser.info/json/stations/byuuid': () => radioJson(fixture('byuuid')),
    });
    final c = clientOver(a);
    expect(await c.servers(), ['de1.api.radio-browser.info']);
    final countries = await c.countries();
    expect(countries, hasLength(10));
    expect(countries.firstWhere((x) => x.code == 'IT').stationCount, greaterThan(1000));
    final states = await c.states('Italy');
    expect(states.first.name, 'Lombardia');
    expect(states.first.stationCount, 188);
    final it = await c.byCountry('IT');
    expect(it, hasLength(60));
    final s = it.first;
    expect((s.id, s.countryCode), isNot(('', '')));
    expect(it.where((x) => x.hls), isNotEmpty);
    expect(it.where((x) => x.tags.length > 1), isNotEmpty);
    expect(await c.byUuids(['a', 'b']), hasLength(2));
    final query = a.sent.firstWhere((r) => r.uri.path.endsWith('byuuid')).uri.queryParameters;
    expect(query['uuids'], 'a,b');
  });

  test('every request carries our User-Agent and hidebroken=true (the click aside)', () async {
    final a = RadioAdapter({
      _discovery: () => radioJson(fixture('servers')),
      'de1.api.radio-browser.info': () => radioJson(fixture('search_rtl')),
    });
    final c = clientOver(a);
    await c.search(name: 'rtl', countryCode: 'IT', limit: 20);
    await c.countries();
    final api = a.sent.where((r) => r.uri.host.startsWith('de1'));
    expect(api, hasLength(2));
    for (final r in a.sent) {
      expect(r.headers['User-Agent'], apiUserAgent);
    }
    for (final r in api) {
      expect(r.uri.queryParameters['hidebroken'], 'true');
    }
    final q = api.first.uri.queryParameters;
    expect((q['name'], q['countrycode'], q['limit'], q['order'], q['reverse']),
        ('rtl', 'IT', '20', 'clickcount', 'true'));
  });

  test('click calls /json/url/<uuid>', () async {
    final a = RadioAdapter({
      _discovery: () => radioJson(fixture('servers')),
      'de1.api.radio-browser.info': () => radioJson(fixture('url_click')),
    });
    await clientOver(a).click('abc');
    expect(a.sent.last.uri.path, '/json/url/abc');
  });

  test('a server that does not answer is skipped for the next one, and the choice is kept', () async {
    final a = RadioAdapter({
      _discovery: () => radioJson([
            {'name': 'a.example'},
            {'name': 'b.example'},
            {'name': 'b.example'},
          ]),
      'a.example': down(),
      'b.example': () => radioJson(fixture('search_rtl')),
      'de1.api.radio-browser.info': down(),
    });
    // Whatever the random order is, the working server ends up answering.
    final c = clientOver(a);
    expect(await c.search(name: 'rtl'), isNotEmpty);
    final calls = a.sent.length;
    expect(await c.search(name: 'rtl'), isNotEmpty);
    expect(a.sent.length, calls + 1, reason: 'the second search goes straight to the good server');
    expect(a.sent.last.uri.host, 'b.example');
  });

  test('a 5xx moves on to the next server; all down means RadioOffline', () async {
    final a = RadioAdapter({
      _discovery: () => radioJson(fixture('servers')),
      'de1.api.radio-browser.info': () => radioJson({}, 502),
    });
    await expectLater(clientOver(a).countries(), throwsA(isA<RadioOffline>()));
  });

  test('with discovery unreachable the fixed de1 server is used', () async {
    final a = RadioAdapter({
      _discovery: down(),
      'de1.api.radio-browser.info': () => radioJson(fixture('search_rtl')),
    });
    expect(await clientOver(a).search(name: 'rtl'), isNotEmpty);
    expect(a.sent.last.uri.host, 'de1.api.radio-browser.info');
  });

  test('429 and 503 are RadioUnavailable with the wait they ask for', () async {
    final a = RadioAdapter({
      _discovery: () => radioJson(fixture('servers')),
      'de1.api.radio-browser.info': () => radioJson({}, 429, {
            'retry-after': ['30'],
          }),
    });
    final err = await clientOver(a).countries().then<Object?>((_) => null, onError: (Object e) => e);
    expect(err, isA<RadioUnavailable>());
    expect((err! as RadioUnavailable).retryAfter, const Duration(seconds: 30));
    final b = RadioAdapter({
      _discovery: () => radioJson(fixture('servers')),
      'de1.api.radio-browser.info': () => radioJson({}, 503),
    });
    await expectLater(clientOver(b).countries(), throwsA(isA<RadioUnavailable>()));
    expect(b.sent.where((r) => r.uri.host.startsWith('de1')), hasLength(1), reason: 'no tour of the servers');
  });

  test('an answer that is not the expected JSON is RadioChanged', () async {
    final a = RadioAdapter({
      _discovery: () => radioJson(fixture('servers')),
      'de1.api.radio-browser.info': () => ResponseBody.fromString('<html>oops</html>', 200,
          headers: {Headers.contentTypeHeader: ['text/html']}),
    });
    await expectLater(clientOver(a).countries(), throwsA(isA<RadioChanged>()));
    final b = RadioAdapter({
      _discovery: () => radioJson(fixture('servers')),
      'de1.api.radio-browser.info': () => radioJson({'error': 'x'}),
    });
    await expectLater(clientOver(b).countries(), throwsA(isA<RadioChanged>()));
  });

  test('a station without an address or an id is dropped, url_resolved wins over url', () async {
    final a = RadioAdapter({
      _discovery: () => radioJson(fixture('servers')),
      'de1.api.radio-browser.info': () => radioJson([
            {'stationuuid': 'a', 'name': 'A', 'url': 'http://a/raw', 'url_resolved': 'http://a/final'},
            {'stationuuid': 'b', 'name': 'B', 'url': 'http://b/raw', 'url_resolved': ''},
            {'stationuuid': 'c', 'name': 'C', 'url': '', 'url_resolved': ''},
            {'name': 'no id', 'url': 'http://x'},
            'junk',
          ]),
    });
    final r = await clientOver(a).search(name: 'x');
    expect([for (final s in r) (s.id, s.streamUrl)], [('a', 'http://a/final'), ('b', 'http://b/raw')]);
  });

  test('requests are spaced by minGap', () async {
    final a = RadioAdapter({
      _discovery: () => radioJson(fixture('servers')),
      'de1.api.radio-browser.info': () => radioJson([]),
    });
    var t = DateTime(2026);
    final waits = <Duration>[];
    final c = RadioBrowserClient(Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = a,
        now: () => t, pause: (d) async {
      waits.add(d);
      t = t.add(d);
    });
    await c.search(name: 'ab');
    await c.search(name: 'cd');
    expect(waits, isNotEmpty);
    expect(waits.every((w) => w <= const Duration(seconds: 1)), isTrue);
  });
}
