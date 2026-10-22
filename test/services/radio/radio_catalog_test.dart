import 'dart:io';

import 'package:codecore/services/radio/radio_browser_client.dart';
import 'package:codecore/services/radio/radio_catalog.dart';
import 'package:codecore/services/radio/regions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'radio_browser_client_test.dart' show RadioAdapter, down, fixture, radioJson;

void main() {
  late Directory tmp;
  late RadioAdapter adapter;
  late DateTime clock;
  late bool offline;
  late RadioCatalog catalog;

  int apiCalls() => adapter.sent.where((r) => r.uri.path.contains('/stations/')).length;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('radio_catalog');
    clock = DateTime(2026, 10, 22, 12);
    offline = false;
    adapter = RadioAdapter({
      'all.api.radio-browser.info/json/servers': () => radioJson(fixture('servers')),
      'de1.api.radio-browser.info/json/stations/search': () =>
          offline ? down()() : radioJson(fixture('stations_it')),
    });
    catalog = RadioCatalog(
      RadioBrowserClient(Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter,
          minGap: Duration.zero),
      tmp.path,
      now: () => clock,
    );
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('the second opening is served from the saved copy, with no request', () async {
    final first = await catalog.country('IT');
    expect(first.stale, isFalse);
    expect(File('${tmp.path}/country_IT.json').existsSync(), isTrue);
    final calls = apiCalls();
    offline = true;
    final second = await catalog.country('IT');
    expect(apiCalls(), calls);
    expect(second.stations.length, first.stations.length);
    expect(second.stale, isFalse);
  });

  test('the region filter runs on the saved copy too', () async {
    await catalog.country('IT');
    final region = kItalianRegions.firstWhere((r) => r.id == 'lombardia');
    final near = await catalog.country('IT', region: region);
    expect(near.stations, isNotEmpty);
    expect(near.stations.length, lessThan((await catalog.country('IT')).stations.length));
  });

  test('an expired copy is downloaded again; offline it is returned as stale', () async {
    await catalog.country('IT');
    clock = clock.add(const Duration(days: 8));
    offline = true;
    final old = await catalog.country('IT');
    expect(old.stale, isTrue);
    expect(old.stations, isNotEmpty);
    offline = false;
    final calls = apiCalls();
    final fresh = await catalog.country('IT');
    expect(apiCalls(), calls + 1);
    expect(fresh.stale, isFalse);
  });

  test('no copy and no network is an error', () async {
    offline = true;
    await expectLater(catalog.country('IT'), throwsA(isA<RadioOffline>()));
  });

  test('the same search within 10 minutes makes no request, after that it does', () async {
    final a = await catalog.search('rtl');
    final calls = apiCalls();
    final b = await catalog.search(' RTL ');
    expect(apiCalls(), calls);
    expect(b.length, a.length);
    clock = clock.add(const Duration(minutes: 11));
    await catalog.search('rtl');
    expect(apiCalls(), calls + 1);
  });

  test('a one-letter search asks nothing; the cache keeps at most 30 searches', () async {
    expect(await catalog.search('a'), isEmpty);
    expect(apiCalls(), 0);
    for (var i = 0; i < 31; i++) {
      await catalog.search('query $i');
    }
    final calls = apiCalls();
    await catalog.search('query 30');
    expect(apiCalls(), calls, reason: 'the newest is still there');
    await catalog.search('query 0');
    expect(apiCalls(), calls + 1, reason: 'the oldest was dropped');
  });

  test('the country comes from the locale, or Italy', () {
    expect(defaultRadioCountry('de'), 'DE');
    expect(defaultRadioCountry(null), 'IT');
    expect(defaultRadioCountry(''), 'IT');
  });
}
