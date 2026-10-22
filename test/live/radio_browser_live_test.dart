// Opt-in: the real Radio Browser (a handful of requests, about 5 s).
//   CODECORE_LIVE=1 flutter test test/live/radio_browser_live_test.dart
import 'dart:io';

import 'package:codecore/services/radio/radio_browser_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  final skip = live ? false : 'set CODECORE_LIVE=1';
  const timeout = Timeout(Duration(minutes: 2));
  late RadioBrowserClient client;

  setUp(() => client = RadioBrowserClient.standard());

  test('the discovery address lists at least one server', () async {
    expect(await client.servers(), isNotEmpty);
  }, skip: skip, timeout: timeout);

  test('Italy has at least 500 working stations, each with an address', () async {
    final list = await client.byCountry('IT');
    expect(list.length, greaterThanOrEqualTo(500));
    expect(list.every((s) => s.streamUrl.startsWith('http')), isTrue);
  }, skip: skip, timeout: timeout);

  test('«rtl 102.5» is found and the same station is read again by its id', () async {
    final hits = await client.search(name: 'rtl 102.5');
    expect(hits, isNotEmpty);
    final again = await client.byUuids([hits.first.id]);
    expect(again.map((s) => s.id), [hits.first.id]);
  }, skip: skip, timeout: timeout);

  test('the countries and the regions of Italy are listed', () async {
    final countries = await client.countries();
    final italy = countries.firstWhere((c) => c.code == 'IT');
    expect(italy.stationCount, greaterThan(500));
    expect(await client.states(italy.name), isNotEmpty);
  }, skip: skip, timeout: timeout);
}
