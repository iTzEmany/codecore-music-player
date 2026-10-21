import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/review_queries.dart';
import '../data/db/app_database.dart';
import 'database_providers.dart';
import 'online_providers.dart';
import 'settings_providers.dart';

final reviewQueriesProvider = Provider<ReviewQueries>(
  (ref) => ReviewQueries(ref.watch(databaseProvider)),
);

/// The tracks the user dismissed with «Va bene così», kept in the settings.
class ReviewDismissedNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => ref.read(settingsStoreProvider).readReviewDismissed();

  Future<void> add(Set<int> ids) async {
    state = {...state, ...ids};
    await ref.read(settingsStoreProvider).writeReviewDismissed(state);
  }
}

final reviewDismissedProvider =
    NotifierProvider<ReviewDismissedNotifier, Set<int>>(
      ReviewDismissedNotifier.new,
    );

/// The tracks to review (see [ReviewQueries]), minus the dismissed ones.
final reviewTracksProvider = StreamProvider.autoDispose<List<Track>>(
  (ref) => ref
      .watch(reviewQueriesProvider)
      .watch(dismissed: ref.watch(reviewDismissedProvider)),
);

/// Only the number, for the Library entry.
final reviewCountProvider = StreamProvider.autoDispose<int>(
  (ref) => ref
      .watch(reviewQueriesProvider)
      .watchCount(dismissed: ref.watch(reviewDismissedProvider)),
);

enum ReviewRetryResult { started, busy }

class ReviewActions {
  ReviewActions(this._ref);

  final Ref _ref;

  /// «Riprova»: the tracks go back to status 0 and the batch enrichment (the
  /// same job as «Arricchisci») asks the online sources again. Nothing is
  /// reset while another job runs, or the tracks would leave the list untried.
  Future<ReviewRetryResult> retry(Set<int> ids) async {
    if (_ref.read(enrichJobProvider).running) return ReviewRetryResult.busy;
    await _ref.read(reviewQueriesProvider).resetStatus(ids);
    final started = _ref.read(enrichJobProvider.notifier).start(ids.toList());
    return started ? ReviewRetryResult.started : ReviewRetryResult.busy;
  }

  Future<void> dismiss(Set<int> ids) =>
      _ref.read(reviewDismissedProvider.notifier).add(ids);
}

final reviewActionsProvider = Provider<ReviewActions>(ReviewActions.new);
