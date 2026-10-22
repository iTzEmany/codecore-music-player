import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/radio/near_you.dart';
import 'package:codecore/services/radio/radio_browser_client.dart';
import 'package:codecore/services/radio/radio_station.dart';
import 'package:codecore/services/radio/regions.dart';
import 'package:flutter_test/flutter_test.dart';

List fixtureList(String name) =>
    jsonDecode(File('test/fixtures/radio/$name.json').readAsStringSync()) as List;

RadioStation st(String name, {String state = '', String url = 'http://x/s', int clicks = 0, bool ok = true, String? id}) =>
    RadioStation(id: id ?? name + url, name: name, streamUrl: url, state: state, clickCount: clicks, lastCheckOk: ok);

void main() {
  final stations = [for (final j in fixtureList('stations_it')) ?RadioStation.fromApi(j as Map)];
  RadioRegion region(String id) => kItalianRegions.firstWhere((r) => r.id == id);
  Set<String> states(RadioRegion r) => {for (final s in stations) if (matchesRegion(s, r)) s.state};

  test('Lombardia takes every spelling the stations use, cities included', () {
    final got = states(region('lombardia'));
    expect(got, containsAll(['Lombardia', 'Lombardy', 'lombardia', 'Lombardia/Italy', 'Milano', 'Milano (MI)', 'Brescia']));
    expect(got.where((s) => s.toLowerCase().contains('lazio')), isEmpty);
  });

  test('no station of another region ends up in Lombardia', () {
    final lombardia = region('lombardia');
    for (final other in ['Lazio', 'Roma', 'Sicilia', 'Veneto', 'Piemonte', 'Emilia-Romagna', 'Bologna']) {
      final s = stations.where((x) => x.state == other);
      expect(s, isNotEmpty, reason: other);
      expect(s.where((x) => matchesRegion(x, lombardia)), isEmpty, reason: other);
    }
  });

  test('Emilia-Romagna also takes «Emilia Romagna» and Bologna; Lazio takes Roma', () {
    expect(states(region('emilia-romagna')), containsAll(['Emilia-Romagna', 'Emilia Romagna', 'Bologna']));
    expect(states(region('lazio')), containsAll(['Lazio', 'Roma']));
  });

  test('a station without a state matches nothing, and Romagna is not Roma', () {
    expect(matchesRegion(st('A'), region('lazio')), isFalse);
    expect(matchesRegion(st('A', state: 'Romagna'), region('lazio')), isFalse);
    expect(matchesRegion(st('A', state: 'Toscana,Firenze,Florence'), region('toscana')), isTrue);
  });

  test('the 74 real states all belong to at most the regions they name', () {
    final real = [for (final j in fixtureList('states_italy')) (j as Map)['name'] as String];
    expect(real, hasLength(74));
    final lazio = real.where((n) => matchesRegion(st('x', state: n), region('lazio')));
    expect(lazio, contains('Lazio'));
    expect(lazio.where((n) => n.toLowerCase().contains('lomb')), isEmpty);
  });

  test('dedupe: Radio Deejay once, the working https copy with most clicks wins', () {
    final deejay = stations.where((s) => s.name.toLowerCase() == 'radio deejay').toList();
    expect(deejay.length, greaterThan(1), reason: 'the fixture has the doubles');
    final one = dedupe(stations);
    expect(one.where((s) => s.name.toLowerCase() == 'radio deejay'), hasLength(1));
    expect(one.map((s) => s.name.toLowerCase()).toSet().length, one.length, reason: 'one per name');
  });

  test('dedupe preference: ok first, then https, then clicks; first position is kept', () {
    final r = dedupe([
      st('Alfa', url: 'http://a', clicks: 99),
      st('Beta', url: 'http://b'),
      st('alfa!', url: 'https://a', clicks: 1),
      st('ALFA', url: 'https://a2', clicks: 5),
      st('Beta', url: 'https://b', ok: false),
    ]);
    expect([for (final s in r) s.streamUrl], ['https://a2', 'http://b']);
  });

  test('nearYou sorts by clicks after removing doubles', () {
    final r = nearYou([
      st('Low', state: 'Lombardia', clicks: 1),
      st('High', state: 'Milano', clicks: 50),
      st('Away', state: 'Lazio', clicks: 999),
      st('High', state: 'Lombardy', clicks: 10, url: 'http://y'),
    ], region('lombardia'));
    expect([for (final s in r) s.name], ['High', 'Low']);
  });

  test('a foreign country offers the states with at least 3 stations, as they are', () {
    final r = regionsFor('DE', const [
      RadioState(name: 'Bayern', stationCount: 40),
      RadioState(name: 'Bremen', stationCount: 2),
      RadioState(name: 'Berlin', stationCount: 3),
    ]);
    expect([for (final x in r) x.label], ['Bayern', 'Berlin']);
    expect(matchesRegion(st('x', state: 'BAYERN'), r.first), isTrue);
    expect(regionById('DE', 'Bayern')!.label, 'Bayern');
    expect(regionsFor('IT', const []), hasLength(20));
    expect(regionById('IT', 'lombardia')!.label, 'Lombardia');
    expect(regionById('IT', 'nope'), isNull);
  });
}
