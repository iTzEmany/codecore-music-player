import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/online/enrichment_service.dart';
import '../services/online/http_client.dart';
import '../services/online/itunes_client.dart';
import '../services/online/lrclib_client.dart';
import '../services/online/curiosity_finder.dart';
import '../services/online/musicbrainz_client.dart';
import '../services/online/quiet_enricher.dart';
import '../services/online/wikipedia_client.dart';
import 'database_providers.dart';
import 'library_providers.dart';
import 'settings_providers.dart';

final webClientProvider = Provider<WebClient>((ref) => DioWebClient());

final itunesClientProvider = Provider(
  (ref) => ItunesClient(
    ref.watch(webClientProvider),
    // The store follows the app language: its catalogue has the local music.
    country: () => switch (ref.read(settingsProvider).language) {
      'it' => 'IT',
      'de' => 'DE',
      'es' => 'ES',
      _ => 'US',
    },
  ),
);
final lrclibClientProvider = Provider(
  (ref) => LrclibClient(ref.watch(webClientProvider)),
);
final wikipediaClientProvider = Provider(
  (ref) => WikipediaClient(ref.watch(webClientProvider)),
);
final musicBrainzClientProvider = Provider(
  (ref) => MusicBrainzClient(ref.watch(webClientProvider)),
);
final curiosityFinderProvider = Provider(
  (ref) => CuriosityFinder(
    wikipedia: ref.watch(wikipediaClientProvider),
    musicBrainz: ref.watch(musicBrainzClientProvider),
    wikidata: WikidataClient(ref.watch(webClientProvider)),
  ),
);

final enrichmentServiceProvider = Provider<EnrichmentService>((ref) {
  final web = ref.watch(webClientProvider);
  return EnrichmentService(
    db: ref.watch(databaseProvider),
    tracks: ref.watch(trackRepositoryProvider),
    covers: ref.watch(coverStoreProvider),
    itunes: ref.watch(itunesClientProvider),
    lrclib: ref.watch(lrclibClientProvider),
    wikipedia: ref.watch(wikipediaClientProvider),
    web: web,
    language: () => ref.read(settingsProvider).language,
  );
});

class EnrichJobState {
  const EnrichJobState({this.running = false, this.progress, this.result});

  final bool running;
  final BatchProgress? progress;

  /// Last finished job (shown once by the shell as a snackbar).
  final BatchProgress? result;
}

class EnrichJobNotifier extends Notifier<EnrichJobState> {
  CancelToken? _cancel;

  @override
  EnrichJobState build() => const EnrichJobState();

  /// Returns false when another job is already running.
  bool start(
    List<int> ids, {
    bool includeLyrics = true,
    bool includeCuriosities = false,
    bool includeMetadata = true,
    bool force = false,
    void Function()? onFinished,
  }) {
    if (state.running || ids.isEmpty) return false;
    _cancel = CancelToken();
    state = const EnrichJobState(running: true);
    _run(ids, includeLyrics, includeCuriosities, includeMetadata, force, onFinished);
    return true;
  }

  Future<void> _run(
    List<int> ids,
    bool lyrics,
    bool curiosities,
    bool metadata,
    bool force,
    void Function()? onFinished,
  ) async {
    BatchProgress? last;
    try {
      await for (final p
          in ref
              .read(enrichmentServiceProvider)
              .enrichMany(
                ids,
                cancel: _cancel,
                includeLyrics: lyrics,
                includeCuriosities: curiosities,
                includeMetadata: metadata,
                force: force,
              )) {
        last = p;
        state = EnrichJobState(running: !p.finished, progress: p);
      }
    } on Object {
      last = const BatchProgress(finished: true);
    }
    state = EnrichJobState(result: last ?? const BatchProgress(finished: true));
    onFinished?.call();
  }

  void cancel() => _cancel?.cancel();

  void clearResult() => state = const EnrichJobState();
}

final enrichJobProvider = NotifierProvider<EnrichJobNotifier, EnrichJobState>(
  EnrichJobNotifier.new,
);

/// Downloaded songs get their lyrics and missing tags here, one at a time and
/// without a line in the Activity centre (the batch job is for the user's
/// own «Arricchisci»).
final downloadEnricherProvider = Provider<QuietEnricher>((ref) {
  final enricher = QuietEnricher(
    enabled: () {
      final s = ref.read(settingsProvider);
      return s.autoEnrich || s.autoLyrics;
    },
    enrich: (id) {
      final s = ref.read(settingsProvider);
      return ref
          .read(enrichmentServiceProvider)
          .enrichMany([id], includeLyrics: s.autoLyrics, includeMetadata: s.autoEnrich)
          .drain<void>();
    },
  );
  ref.onDispose(enricher.dispose);
  return enricher;
});

/// The downloaded songs waiting for, or in, that enrichment.
final enrichingTracksProvider = StreamProvider<Set<int>>((ref) async* {
  final enricher = ref.watch(downloadEnricherProvider);
  yield enricher.pending;
  yield* enricher.changes;
});
