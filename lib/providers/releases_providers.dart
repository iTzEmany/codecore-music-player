import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/follow_repository.dart';
import '../data/repositories/release_repository.dart';
import '../data/repositories/stats_queries.dart';
import '../services/releases/auto_follow_service.dart';
import '../services/releases/release_checker.dart';
import 'database_providers.dart';
import 'ytm_catalog_providers.dart';

final followRepositoryProvider =
    Provider<FollowRepository>((ref) => FollowRepository(ref.watch(databaseProvider)));

final releaseRepositoryProvider =
    Provider<ReleaseRepository>((ref) => ReleaseRepository(ref.watch(databaseProvider)));

/// Followed and automatic artists (not the excluded), by name.
final followedArtistsProvider = StreamProvider.autoDispose(
    (ref) => ref.watch(followRepositoryProvider).watchFollowed());

/// Whether the artist with this `UC…` id is followed.
final isFollowedProvider = StreamProvider.autoDispose.family<bool, String>(
    (ref, id) => ref.watch(followRepositoryProvider).watchIsFollowed(id));

/// Releases flagged new in the last 30 days (Home); 90 for the full page.
final recentReleasesProvider = StreamProvider.autoDispose
    .family<List<RecentRelease>, int>((ref, days) =>
        ref.watch(releaseRepositoryProvider).watchRecent(days: days));

final newReleasesCountProvider = StreamProvider.autoDispose(
    (ref) => ref.watch(releaseRepositoryProvider).watchCountNew());

/// A round of checks reading the artist pages in [hl]'s language.
final releaseCheckerProvider = Provider.family<ReleaseChecker, String>((ref, hl) {
  final catalog = ref.watch(ytmCatalogProvider);
  return ReleaseChecker(
    (id) => catalog.releases(id, hl),
    ref.watch(followRepositoryProvider),
    ref.watch(releaseRepositoryProvider),
  );
});

final autoFollowServiceProvider = Provider.family<AutoFollowService, String>((ref, hl) {
  final catalog = ref.watch(ytmCatalogProvider);
  return AutoFollowService(
    stats: StatsQueries(ref.watch(databaseProvider)),
    follows: ref.watch(followRepositoryProvider),
    search: (name) => catalog.searchArtists(name, hl),
  );
});
