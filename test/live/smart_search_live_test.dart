// Opt-in: the smart online search with the real services (YouTube Music card,
// YouTube Music songs, YouTube videos; a handful of requests per phrase).
// A failure here means YouTube changed its answers or the scoring drifted:
// see R82 in docs/99-rischi-e-fallback.md.
//   CODECORE_LIVE=1 [YTDLP=/path/to/yt-dlp] flutter test test/live/smart_search_live_test.dart
import 'dart:io';

import 'package:codecore/services/online/catalog_cache.dart';
import 'package:codecore/services/online/direct_search_service.dart';
import 'package:codecore/services/online/innertube_client.dart';
import 'package:codecore/services/online/query_intent.dart';
import 'package:codecore/services/online/smart_search.dart';
import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/online/ytm_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  final skip = live ? false : 'set CODECORE_LIVE=1';

  late Directory dir;
  late InnerTubeClient client;
  late SmartSearch engine;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('smart_search_live');
    client = InnerTubeClient();
    final yt = YtDlpProcessService(executable: Platform.environment['YTDLP']);
    final catalog = YtmCatalog(
      client,
      yt,
      CatalogCache(file: () async => File('${dir.path}/catalog.json')),
    );
    engine = SmartSearch(
      youtube: DirectSearchService(yt, client, catalog: catalog),
      catalog: catalog,
    );
  });
  tearDown(() {
    client.close();
    dir.deleteSync(recursive: true);
  });

  /// The last state of the search: every source has answered.
  Future<SmartSearchState> search(String q) async {
    final last = await engine.run(q, 'en').last;
    expect(last.error, isNull);
    expect(last.pending, isEmpty);
    expect(last.notices, isEmpty, reason: 'no source in error');
    return last;
  }

  test(
    'an artist name gives the artist card and the artist-page intent',
    () async {
      final s = await search('pink floyd');
      expect(s.card, isA<TopArtist>());
      expect(
        (s.card! as TopArtist).artist.name.toLowerCase(),
        contains('pink floyd'),
      );
      expect(s.intent, SearchIntent.artistPage);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'an album name gives the album card',
    () async {
      final s = await search('the wall');
      expect(s.card, isA<TopAlbum>());
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'artist and title: the first best row is the song',
    () async {
      final s = await search('pink floyd mother');
      expect(s.best, isNotEmpty);
      final first = s.best.first.primary;
      expect(first.title.toLowerCase(), contains('mother'));
      expect(first.channel.toLowerCase(), contains('pink floyd'));
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'a nonsense phrase has nothing sure',
    () async {
      final s = await search('qzxv wkjh plorb nnmqtz');
      expect(s.noneSure, isTrue);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
