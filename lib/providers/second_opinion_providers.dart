import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_log.dart';
import '../data/repositories/review_queries.dart';
import '../services/online/query_match.dart';
import '../services/online/second_opinion.dart';
import 'database_providers.dart';
import 'online_providers.dart';
import 'settings_providers.dart';
import 'smart_search_providers.dart';
import 'youtube_providers.dart';
import 'ytm_catalog_providers.dart';

final secondOpinionProvider = Provider<SecondOpinion>(
  (ref) => SecondOpinion(
    client: ref.watch(innerTubeClientProvider),
    catalog: ref.watch(ytmCatalogProvider),
    enrichment: ref.watch(enrichmentServiceProvider),
    musicBrainz: ref.watch(musicBrainzClientProvider),
    tracks: ref.watch(trackRepositoryProvider),
    hl: () => ref.read(ytmLanguageProvider),
  ),
);

/// The tracks YouTube Music already gave its second opinion on (kept in the
/// settings): opening «Da revisionare» does not ask for them again.
class ReviewCheckedNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => ref.read(settingsStoreProvider).readReviewChecked();

  Future<void> add(int id) async {
    state = {...state, id};
    await ref.read(settingsStoreProvider).writeReviewChecked(state);
  }
}

final reviewCheckedProvider =
    NotifierProvider<ReviewCheckedNotifier, Set<int>>(ReviewCheckedNotifier.new);

/// Progress of the second-opinion job. It stays filled after the job ends
/// (`running` false), so the UI can tell the end of a run that changed
/// something: `running` going true → false with `updated > 0`.
class SecondOpinionState {
  const SecondOpinionState({
    this.running = false,
    this.done = 0,
    this.total = 0,
    this.updated = 0,
    this.throttled = false,
  });

  final bool running;

  /// Tracks looked at so far, out of [total] to look at in this run.
  final int done, total;

  /// Tracks that got at least one field filled in.
  final int updated;

  /// A «too many requests» answer stopped the run (the rest stays unchecked).
  final bool throttled;
}

class SecondOpinionNotifier extends Notifier<SecondOpinionState> {
  CancelToken? _cancel;

  @override
  SecondOpinionState build() => const SecondOpinionState();

  /// Looks at [ids] one at a time, in the background. Without [force] the
  /// ones already checked are left out; with it (the user's «Riprova») every
  /// track that still has a hole is asked again. Does nothing while a run is
  /// going or YouTube Music is resting after a «too many requests».
  Future<void> run(List<int> ids, {bool force = false}) async {
    final cooldown = ref.read(sourceCooldownProvider);
    if (state.running || ids.isEmpty || cooldown.isPaused(MediaKind.ytmSong)) return;
    final checked = ref.read(reviewCheckedProvider);
    final todo = force ? ids : [for (final id in ids) if (!checked.contains(id)) id];
    if (todo.isEmpty) return;
    final tracks = ref.read(trackRepositoryProvider);
    final service = ref.read(secondOpinionProvider);
    final token = _cancel = CancelToken();
    var done = 0, updated = 0, throttled = false;
    void emit({bool running = true}) => state = SecondOpinionState(
        running: running, done: done, total: todo.length, updated: updated, throttled: throttled);
    emit();
    try {
      for (final id in todo) {
        if (token.isCancelled) break;
        final t = await tracks.getById(id);
        if (t != null && (!force || reviewReasons(t).isNotEmpty)) {
          final out = await service.check(t, cancel: token);
          if (out.written.isNotEmpty) updated++;
          if (out.kind == SecondOpinionKind.networkError) {
            // Not marked: the answer never came, so it is worth another try.
          } else {
            await ref.read(reviewCheckedProvider.notifier).add(id);
          }
          if (out.kind == SecondOpinionKind.throttled) {
            cooldown.trip(MediaKind.ytmSong);
            throttled = true;
            break;
          }
        }
        done++;
        emit();
      }
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e)) AppLog.w('second opinion job failed: $e');
    } on Object catch (e, st) {
      AppLog.w('second opinion job failed', e, st);
    }
    emit(running: false);
  }

  void cancel() => _cancel?.cancel();
}

final secondOpinionJobProvider =
    NotifierProvider<SecondOpinionNotifier, SecondOpinionState>(SecondOpinionNotifier.new);
