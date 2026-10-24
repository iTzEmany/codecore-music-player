import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import 'podcast_providers.dart';

/// Per-podcast and per-episode user choices.
class PodcastOps {
  PodcastOps(this._ref);

  final Ref _ref;

  Future<void> setAutoDeleteDays(int podcastId, int? days) => _ref.read(podcastRepositoryProvider).setAutoDeleteDays(podcastId, days);

  Future<void> markPlayed(int episodeId, bool played) => _ref.read(podcastRepositoryProvider).markPlayed(episodeId, played, now: nowMs());
}

final podcastOpsProvider = Provider<PodcastOps>(PodcastOps.new);
