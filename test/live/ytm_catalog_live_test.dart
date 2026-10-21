// Opt-in: the real artist and album pages of YouTube Music (a few requests).
// A failure here means YouTube changed the pages: see R74 in
// docs/99-rischi-e-fallback.md and refresh test/fixtures/innertube.
//   CODECORE_LIVE=1 flutter test test/live/ytm_catalog_live_test.dart
import 'dart:io';

import 'package:codecore/services/online/catalog_cache.dart';
import 'package:codecore/services/online/innertube_client.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/online/ytm_catalog.dart';
import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  final skip = live ? false : 'set CODECORE_LIVE=1';

  late Directory dir;
  late YtmCatalog catalog;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ytm_catalog_live');
    catalog = YtmCatalog(
      InnerTubeClient(),
      YtDlpProcessService(executable: Platform.environment['YTDLP']),
      CatalogCache(file: () async => File('${dir.path}/catalog.json')),
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('the top card is an artist for an artist name, not for a song', () async {
    final artist = await catalog.topArtist('pink floyd', 'en');
    expect(artist, isNotNull);
    expect(artist!.name.toLowerCase(), contains('pink floyd'));
    expect(artist.id, startsWith('UC'));
    expect(await catalog.topArtist('mother', 'en'), isNull);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('an artist page has top songs and albums', () async {
    final artist = await catalog.topArtist('pink floyd', 'en');
    final page = (await catalog.artist(artist!.id, 'en')).value;
    final songs = page.shelves.whereType<YtmSongShelf>().expand((s) => s.songs);
    final releases = page.shelves.whereType<YtmReleaseShelf>().expand((s) => s.releases);
    expect(songs, isNotEmpty);
    expect(releases, isNotEmpty);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('an album page has its tracks with durations', () async {
    final artist = await catalog.topArtist('pink floyd', 'en');
    final page = (await catalog.artist(artist!.id, 'en')).value;
    final release = page.shelves
        .whereType<YtmReleaseShelf>()
        .expand((s) => s.releases)
        .first;
    final album = (await catalog.album(release.browseId, 'en')).value;
    expect(album.tracks.length, greaterThanOrEqualTo(5));
    expect(album.tracks.where((t) => t.result.duration != null).length,
        album.tracks.length);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('a missing artist id is ArtistNotFound', () async {
    await expectLater(
      catalog.artist('UCxxxxxxxxxxxxxxxxxxxxxx', 'en'),
      throwsA(isA<ArtistNotFound>()),
    );
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
