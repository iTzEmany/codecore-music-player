// Opt-in: the public web sources the app talks to, with the real clients.
//   CODECORE_LIVE=1 flutter test test/live/sources_live_test.dart
import 'dart:io';

import 'package:codecore/services/online/http_client.dart';
import 'package:codecore/services/online/itunes_client.dart';
import 'package:codecore/services/online/lrclib_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  final skip = live ? false : 'set CODECORE_LIVE=1';
  final web = DioWebClient();
  // Italian store: the catalogue the live songs below belong to.
  final itunes = ItunesClient(web, country: () => 'IT');

  test('iTunes answers a song search with album, year and artwork', () async {
    final m = await itunes.search('Imagine', 'John Lennon');
    expect(m, isNotNull);
    expect(m!.album, isNotEmpty);
    expect(m.year, isNotNull);
    expect(m.artworkUrl, startsWith('https://'));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 1)));

  test('iTunes answers an album search for the cover', () async {
    final a = await itunes.searchAlbum('Volevo essere un duro', 'Lucio Corsi');
    expect(a, isNotNull);
    expect(a!.artworkUrl, contains('600x600'));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 1)));

  test('LRCLIB finds the lyrics of a well-known song', () async {
    final r = await LrclibClient(web).find(
        title: 'Imagine', artist: 'John Lennon', durationSec: 187);
    expect(r, isNotNull);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 1)));
}
