// Opt-in: the real artist page of YouTube Music read with the new-releases
// mask (one request). A failure here means YouTube changed the pages: see
// R74 and R93 in docs/99-rischi-e-fallback.md.
//   CODECORE_LIVE=1 flutter test test/live/releases_live_test.dart
import 'dart:io';

import 'package:codecore/services/online/catalog_cache.dart';
import 'package:codecore/services/online/innertube_client.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/online/ytm_catalog.dart';
import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:codecore/services/releases/release_diff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  final skip = live ? false : 'set CODECORE_LIVE=1';

  late Directory dir;
  late YtmCatalog catalog;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('releases_live');
    catalog = YtmCatalog(
      InnerTubeClient(),
      YtDlpProcessService(executable: Platform.environment['YTDLP']),
      CatalogCache(file: () async => File('${dir.path}/catalog.json')),
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('the releases mask of Pink Floyd gives an album carousel with readable years', () async {
    final page = await catalog.releases('UCO6LS_5W7vqG9mALDNzSFug', 'en');
    final shelves = page.shelves.whereType<YtmReleaseShelf>().toList();
    expect(shelves, isNotEmpty);
    final albums = shelves.expand((s) => s.releases).toList();
    expect(albums, isNotEmpty);
    expect(albums.every((r) => r.browseId.startsWith('MPREb_')), isTrue);
    final years = [for (final r in albums) releaseYear(r.subtitle)];
    expect(years.whereType<int>(), isNotEmpty, reason: 'subtitles: ${albums.map((r) => r.subtitle).toList()}');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('the first check of an artist stores everything and finds nothing new', () async {
    final page = await catalog.releases('UCO6LS_5W7vqG9mALDNzSFug', 'en');
    final diff = diffReleases(
      known: const {},
      knownGroups: const {},
      fetched: page.shelves.whereType<YtmReleaseShelf>().toList(),
      firstCheck: true,
      now: DateTime.now(),
    );
    expect(diff.toStore, isNotEmpty);
    expect(diff.fresh, isEmpty);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
