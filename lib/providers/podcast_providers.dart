import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories/podcast_repository.dart';
import '../services/covers/cover_store.dart';
import '../services/online/http_client.dart';
import '../services/podcast/feed_fetcher.dart';
import '../services/podcast/podcast_service.dart';
import 'database_providers.dart';
import 'library_providers.dart';

final podcastRepositoryProvider = Provider<PodcastRepository>(
  (ref) => PodcastRepository(ref.watch(databaseProvider)),
);

/// The albumKey every episode of a podcast shares (its cover hangs on it).
String podcastAlbumKey(int podcastId) => 'podcast|$podcastId';

final podcastServiceProvider = Provider<PodcastService>((ref) {
  final web = DioWebClient();
  final covers = ref.watch(coverStoreProvider);
  return PodcastService(
    repo: ref.watch(podcastRepositoryProvider),
    fetch: dioFeedFetcher(),
    parse: unavailableFeedParser,
    web: web,
    saveCover: (id, url) async {
      final bytes = await web.getBytes(url, maxBytes: CoverStore.maxBytes);
      if (bytes == null) return null;
      return covers.saveFromBytes(podcastAlbumKey(id), bytes, url);
    },
  );
});

final podcastsProvider = StreamProvider<List<PodcastSummary>>(
  (ref) => ref.watch(podcastRepositoryProvider).watchPodcasts(),
);

final podcastProvider = StreamProvider.family<Podcast?, int>(
  (ref, id) => ref.watch(podcastRepositoryProvider).watchById(id),
);

final podcastEpisodesProvider = StreamProvider.family<List<EpisodeRow>, int>(
  (ref, id) => ref.watch(podcastRepositoryProvider).watchEpisodes(id),
);
