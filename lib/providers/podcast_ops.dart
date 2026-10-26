import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../services/podcast/podcast_service.dart';
import 'activity_log_providers.dart';
import 'activity_providers.dart';
import 'podcast_providers.dart';

/// Per-podcast and per-episode user choices.
class PodcastOps {
  PodcastOps(this._ref);

  final Ref _ref;

  /// Reads every feed again: it shows in the Activity centre and leaves a
  /// line in the Registro, failed if any feed (or the whole run) failed.
  Future<RefreshReport> refreshAll() async {
    _ref.read(podcastRefreshingProvider.notifier).set(true);
    var failed = true;
    try {
      final report = await _ref.read(podcastServiceProvider).refreshAll();
      failed = report.failed.isNotEmpty;
      return report;
    } finally {
      _ref.read(podcastRefreshingProvider.notifier).set(false);
      await _ref
          .read(activityLogProvider.notifier)
          .add(
            LogEntry(
              at: DateTime.now(),
              item: ActivityItem(
                kind: ActivityKind.podcastRefresh,
                key: 'podcastRefresh',
                name: null,
                running: false,
                failed: failed,
              ),
            ),
          );
    }
  }

  Future<void> setAutoDeleteDays(int podcastId, int? days) =>
      _ref.read(podcastRepositoryProvider).setAutoDeleteDays(podcastId, days);

  Future<void> markPlayed(int episodeId, bool played) => _ref
      .read(podcastRepositoryProvider)
      .markPlayed(episodeId, played, now: nowMs());
}

final podcastOpsProvider = Provider<PodcastOps>(PodcastOps.new);
