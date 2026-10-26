import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../data/repositories/credits_repository.dart';
import '../data/settings/settings_store.dart' show AppSettings;
import '../services/online/enrichment_service.dart';
import '../services/online/http_client.dart';
import '../services/online/itunes_client.dart';
import '../services/online/lrclib_client.dart';
import '../services/online/lyrics_chain.dart';
import '../services/online/lyrics_ovh_client.dart';
import '../services/online/netease_lyrics_client.dart';
import '../services/online/curiosity_finder.dart';
import '../services/online/curiosity_service.dart';
import '../services/online/deezer_client.dart';
import '../services/online/deezer_gw_client.dart';
import '../services/online/discogs_client.dart';
import '../core/app_log.dart';
import '../services/online/musicbrainz_client.dart';
import '../services/online/youtube_service.dart' show YtException, YtErrorKind;
import '../services/online/quiet_enricher.dart';
import '../services/share/track_meta.dart';
import '../services/library/download_tagger.dart';
import '../services/library/track_file_sync.dart';
import '../services/tags/tag_writer.dart';
import '../services/online/wikipedia_client.dart';
import '../services/online/ytm_artist_resolver.dart';
import 'ytm_catalog_providers.dart';
import 'database_providers.dart';
import 'library_providers.dart';
import 'settings_providers.dart';
import 'player_providers.dart';
import 'youtube_providers.dart' show resolveDownloadFolder;

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
final deezerClientProvider = Provider(
  (ref) => DeezerClient(ref.watch(webClientProvider)),
);
final deezerGwClientProvider = Provider(
  // shortcut: a one-off Registro line needs a LogEntry kind (phase 53); AppLog until then.
  (ref) => DeezerGwClient(onPaused: () => AppLog.w('deezer_gw: paused for 24 hours after 3 errors')),
);
final lrclibClientProvider = Provider(
  (ref) => LrclibClient(ref.watch(webClientProvider)),
);
final neteaseLyricsClientProvider = Provider(
  (ref) => NeteaseLyricsClient(ref.watch(webClientProvider)),
);
final lyricsOvhClientProvider = Provider(
  (ref) => LyricsOvhClient(ref.watch(webClientProvider)),
);
final lyricsChainProvider = Provider(
  (ref) => LyricsChain(
    lrclib: ref.watch(lrclibClientProvider),
    netease: ref.watch(neteaseLyricsClientProvider),
    ovh: ref.watch(lyricsOvhClientProvider),
  ),
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
    discogs: DiscogsClient(ref.watch(webClientProvider)),
    ytmArtist: (name, cancel) => ytmQuiet(() async {
      final catalog = ref.read(ytmCatalogProvider);
      final hl = ref.read(ytmLanguageProvider);
      // Only a certain match: a wrong artist's story is worse than none.
      final pick = pickYtmArtist(name, await catalog.searchArtists(name, hl));
      if (pick is! ExactArtist) return null;
      final page = (await catalog.artist(pick.artist.id, hl)).value;
      final text = page.description;
      if (text == null) return null;
      return (text: text, source: Uri.parse('https://music.youtube.com/channel/${pick.artist.id}'), lang: hl);
    }),
  ),
);

/// A YouTube Music fallback must stay quiet: a rate limit is the one thing the
/// finder understands, everything else is just "nothing found".
Future<T?> ytmQuiet<T>(Future<T?> Function() body) async {
  try {
    return await body();
  } on YtException catch (e, st) {
    if (e.kind == YtErrorKind.rateLimited) throw const RateLimitedException(429);
    AppLog.w('YouTube Music artist fallback failed', e, st);
    return null;
  }
}

final creditsRepositoryProvider = Provider(
  (ref) => CreditsRepository(ref.watch(databaseProvider)),
);

final curiosityServiceProvider = Provider(
  (ref) => CuriosityService(
    finder: ref.watch(curiosityFinderProvider),
    tracks: ref.watch(trackRepositoryProvider),
    artistInfos: ref.watch(artistInfoRepositoryProvider),
  ),
);

final enrichmentServiceProvider = Provider<EnrichmentService>((ref) {
  final web = ref.watch(webClientProvider);
  return EnrichmentService(
    db: ref.watch(databaseProvider),
    tracks: ref.watch(trackRepositoryProvider),
    covers: ref.watch(coverStoreProvider),
    itunes: ref.watch(itunesClientProvider),
    deezer: ref.watch(deezerClientProvider),
    useDeezer: () => ref.read(settingsProvider).deezerMeta,
    gw: ref.watch(deezerGwClientProvider),
    musicBrainz: ref.watch(musicBrainzClientProvider),
    creditsRepo: ref.watch(creditsRepositoryProvider),
    useCredits: () => ref.read(settingsProvider).creditsDetails,
    lrclib: ref.watch(lrclibClientProvider),
    lyricsChain: ref.watch(lyricsChainProvider),
    curiosities: ref.watch(curiosityServiceProvider),
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
    if (last?.cancelled != true) onFinished?.call();
  }

  void cancel() => _cancel?.cancel();

  void clearResult() => state = const EnrichJobState();
}

final enrichJobProvider = NotifierProvider<EnrichJobNotifier, EnrichJobState>(
  EnrichJobNotifier.new,
);

/// The parts the switches turn on for a song that has just arrived.
Set<EnrichPart> autoParts(AppSettings s) => {
  if (s.autoEnrich) EnrichPart.meta,
  if (s.autoLyrics) ...[EnrichPart.lyrics, EnrichPart.synced],
  if (s.autoCuriosities) EnrichPart.curio,
  if (s.creditsDetails) EnrichPart.credits,
};

/// Downloaded songs get every part that is on (tags, lyrics, curiosities,
/// credits) here, one at a time and without a line in the Activity centre
/// (the batch job is for the user's own «Arricchisci»).
final downloadEnricherProvider = Provider<QuietEnricher>((ref) {
  final enricher = QuietEnricher(
    onDone: (id) => ref.read(downloadTaggerProvider).tag(id),
    enabled: () => autoParts(ref.read(settingsProvider)).isNotEmpty,
    enrich: (id) async {
      final service = ref.read(enrichmentServiceProvider);
      await service.limiter.wait();
      await service.completeOne(id, autoParts(ref.read(settingsProvider)));
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

/// Writes the tags of files Codecore downloaded or received into them.
/// Call `tag(trackId)` once the row has its final tags (also after a receive).
final downloadTaggerProvider = Provider<DownloadTagger>((ref) {
  final db = ref.watch(databaseProvider);
  final tracks = ref.watch(trackRepositoryProvider);
  final covers = ref.watch(coverStoreProvider);
  final handler = ref.watch(audioHandlerProvider);
  final tagger = DownloadTagger(
    trackById: tracks.getById,
    sync: TrackFileSync(db, () => ref.read(safeTagWriterProvider.future)),
    reader: ref.watch(tagReaderProvider),
    downloadRoot: () async =>
        (await resolveDownloadFolder(ref.read(folderRepositoryProvider)))?.$1.path,
    enabled: () => ref.read(settingsProvider).writeTagsAfterDownload,
    coverOf: (t) async {
      final f = t.coverKey == null ? null : covers.fileFor(t.coverKey!);
      if (f == null) return null;
      final png = f.path.toLowerCase().endsWith('.png');
      return TagCover(await f.readAsBytes(), png ? 'image/png' : 'image/jpeg');
    },
    playingPath: () => handler.currentTrack?.path,
    playingChanges: handler.currentTrackStream.map((t) => t?.path),
  );
  ref.onDispose(tagger.dispose);
  return tagger;
});

/// A downloaded song is ready: enrich it (tags are written when that ends), or
/// write its tags now when enrichment is off.
void afterDownload(Ref ref, int trackId) {
  try {
    if (autoParts(ref.read(settingsProvider)).isNotEmpty) {
      ref.read(downloadEnricherProvider).add(trackId);
    } else {
      unawaited(ref.read(downloadTaggerProvider).tag(trackId));
    }
  } on Object catch (e, st) {
    AppLog.w('afterDownload failed for track $trackId', e, st);
  }
}

/// A received song is ready. With an ISRC and Deezer metadata on, it joins the
/// download enricher (whose `onDone` writes the tags); otherwise tags go now.
/// [read] is `ref.read` of a Ref or a WidgetRef.
void afterReceive(
  T Function<T>(ProviderListenable<T>) read,
  int trackId,
  TrackMeta? meta,
) {
  try {
    final s = read(settingsProvider);
    if (meta?.isrc != null && s.deezerMeta && s.autoEnrich) {
      read(downloadEnricherProvider).add(trackId);
    } else {
      unawaited(read(downloadTaggerProvider).tag(trackId));
    }
  } on Object catch (e, st) {
    AppLog.w('afterReceive failed for track $trackId', e, st);
  }
}
