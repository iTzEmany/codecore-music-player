import 'package:dio/dio.dart';

import '../../core/app_log.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/track_repository.dart';
import 'cover_fetcher.dart';
import 'credits_enricher.dart';
import 'enrich_parts.dart';
import 'enrich_writer.dart';
import 'enrichment_proposal.dart';
import 'http_client.dart';
import 'lrclib_client.dart';
import 'lyrics_chain.dart';
import 'metadata_resolver.dart';
import 'query_cleaner.dart';
import 'wikipedia_client.dart';

export 'credits_enricher.dart' show CreditsPart;
export 'enrich_parts.dart' show AskMode, EnrichField, EnrichPart, PartOutcome;
export 'enrichment_proposal.dart' show EnrichmentProposal;

class BatchProgress {
  const BatchProgress({
    this.done = 0,
    this.total = 0,
    this.updated = 0,
    this.notFound = 0,
    this.finished = false,
    this.rateLimited = false,
    this.cancelled = false,
  });

  final int done, total, updated, notFound;
  final bool finished, rateLimited, cancelled;
}

/// Whether a batch run still has something to ask the online services for
/// [t]. A track whose requested fields are all filled is not looked up again
/// (every run used to ask iTunes again for every track already enriched), and
/// one for which nothing was ever found (status 2) waits until the user asks
/// for it explicitly ([force]).
bool needsEnrichment(
  Track t, {
  bool metadata = true,
  bool lyrics = true,
  bool curiosities = false,
  bool force = false,
}) {
  if (t.enrichStatus == 2 && !force) return false;
  final meta = metadata &&
      (t.album == null ||
          t.year == null ||
          t.genre == null ||
          t.trackNumber == null ||
          !t.hasCover);
  final words = lyrics && t.lyricsPlain == null && t.lyricsSynced == null;
  final trivia = curiosities && t.curiosities == null;
  return meta || words || trivia;
}

bool _never() => false;

class EnrichmentService {
  EnrichmentService({
    required this.db,
    required this.tracks,
    required this.resolver,
    required this.covers,
    this.creditsEnricher,
    this.useCredits = _never,
    required this.lrclib,
    this.lyricsChain,
    required this.wikipedia,
    required this.language,
    RateLimiter? limiter,
  }) : _limiter = limiter ?? RateLimiter(),
       _writer = EnrichWriter(db, tracks);

  final AppDatabase db;
  final TrackRepository tracks;
  final MetadataResolver resolver;
  final CoverFetcher covers;

  /// The credits part, used only while [useCredits] (the user's «Credits and
  /// details» option, off by default) says so.
  final CreditsEnricher? creditsEnricher;
  final bool Function() useCredits;
  bool get _creditsOn => useCredits() && creditsEnricher != null;

  /// Writes `track_credits` and `track_enrich` only (see [CreditsEnricher.save]).
  Future<void> saveCredits(int trackId, CreditsPart? part) async =>
      creditsEnricher?.save(trackId, part);
  final LrclibClient lrclib;

  /// LRCLIB, NetEase, lyrics.ovh; LRCLIB alone when not given.
  final LyricsChain? lyricsChain;
  late final LyricsChain _chain = lyricsChain ?? LyricsChain(lrclib: lrclib);
  final WikipediaClient wikipedia;
  final String Function() language;
  final RateLimiter _limiter;
  final EnrichWriter _writer;

  /// The pause between online lookups, shared with the second opinion.
  RateLimiter get limiter => _limiter;

  /// Reads only: nothing is written until [apply].
  Future<EnrichmentProposal> propose(Track t,
      {CancelToken? cancel,
      bool lyrics = true,
      bool curiosity = true,
      bool metadata = true,
      bool needGenre = true,
      bool credits = true,
      bool forceCredits = false}) async {
    final c = cleanSearchQuery(t.title, t.artist ?? '');
    // Independent services run in parallel; a slow one cannot block the others.
    Future<T?> guarded<T>(Future<T?> f) => f
        .timeout(const Duration(seconds: 25))
        .catchError((Object e, StackTrace st) {
      if (e is RateLimitedException || e is DioException) throw e;
      AppLog.w('enrichment source failed', e, st);
      return null as T?;
    });
    final results = await Future.wait<Object?>([
      metadata ? guarded(resolver.resolve(t, c, cancel, needGenre)) : Future<Object?>.value(),
      lyrics
          ? guarded(_chain.find(t, cancel: cancel).then((r) {
              // A refusal is not «no text»: the manual run stops on it.
              if (r.lyrics == null && r.limited) throw const RateLimitedException(429);
              return r.lyrics;
            }))
          : Future<Object?>.value(),
      curiosity
          ? guarded(wikipedia.find(c.title, c.artist, language(), cancel: cancel))
          : Future<Object?>.value(),
    ]);
    final m = results[0] as ResolvedMeta?;
    final lr = results[1] as LyricsResult?;
    final cu = results[2] as Curiosity?;
    if (m != null) AppLog.i('enrichment: track ${t.id} metadata from ${m.source}');
    // After the other parts: it reuses their Deezer hit and can never abort them.
    final cp = credits && _creditsOn && (forceCredits || t.id <= 0 || await creditsEnricher!.isDue(t))
        ? await creditsEnricher!.fetch(t, m?.hit, cancel)
        : null;
    // The only place credits are saved for a stored track, even if the preview is cancelled.
    if (t.id > 0) await saveCredits(t.id, cp);
    return EnrichmentProposal(
        track: t,
        meta: m?.match,
        lyrics: lr,
        curiosity: cu,
        credits: cp,
        disc: m?.disc,
        isrc: m?.isrc,
        source: m?.source);
  }

  /// Writes only [fields]; `userEdited` tracks keep title/artist/album.
  /// True when the proposal had something (not that a field changed).
  Future<bool> apply(EnrichmentProposal p, Set<EnrichField> fields,
          {CancelToken? cancel, bool replaceCover = false}) async =>
      (await _apply(p, fields, cancel: cancel, replaceCover: replaceCover))
          .found;

  /// [apply] that also says what happened: `wrote`: a field or the cover was
  /// written (status `found` written with it); `coverFailed`: the cover
  /// download failed, so the answer is incomplete.
  Future<({bool found, bool wrote, bool coverFailed})> _apply(
      EnrichmentProposal p, Set<EnrichField> fields,
      {CancelToken? cancel, bool replaceCover = false}) async {
    final t = await tracks.getById(p.track.id) ?? p.track;
    final f = {...fields};
    if (t.userEdited) {
      f.removeAll({EnrichField.title, EnrichField.artist, EnrichField.album});
    }
    final w = await _writer.writeFields(t, p, f);
    var found = w.found, wrote = w.wrote, coverFailed = false;
    if (w.wrote) await _writer.writeStatus(t.id, EnrichStatus.found);
    if (f.contains(EnrichField.cover) && p.coverUrl != null) {
      final r = await covers.apply(w.key, p.coverUrl!,
          replace: replaceCover, cancel: cancel);
      coverFailed = r == CoverResult.failed;
      if (r == CoverResult.saved) {
        found = true;
        if (!w.wrote) {
          wrote = true;
          await _writer.writeStatus(t.id, EnrichStatus.found);
        }
      }
    }
    return (found: found, wrote: wrote, coverFailed: coverFailed);
  }

  /// Fills only empty fields; never touches title/artist.
  Stream<BatchProgress> enrichMany(
    List<int> ids, {
    CancelToken? cancel,
    bool includeLyrics = true,
    bool includeCuriosities = false,
    bool includeMetadata = true,
    bool force = false,
  }) async* {
    var updated = 0, notFound = 0, done = 0;
    resolver.clearAlbums();
    for (final id in ids) {
      if (cancel?.isCancelled ?? false) {
        yield BatchProgress(
            done: done, total: ids.length, updated: updated,
            notFound: notFound, finished: true, cancelled: true);
        return;
      }
      final t = await tracks.getById(id);
      done++;
      if (t == null ||
          !needsEnrichment(t,
              metadata: includeMetadata,
              lyrics: includeLyrics,
              curiosities: includeCuriosities,
              force: force)) {
        yield BatchProgress(
            done: done, total: ids.length, updated: updated, notFound: notFound);
        continue;
      }
      try {
        await _limiter.wait();
        final prop = await propose(t,
            cancel: cancel,
            credits: true,
            forceCredits: force,
            metadata: includeMetadata,
            needGenre: t.genre == null,
            lyrics: includeLyrics && t.lyricsPlain == null,
            curiosity: includeCuriosities && t.curiosities == null);
        final fields = <EnrichField>{
          if (includeMetadata && t.album == null) EnrichField.album,
          if (includeMetadata && t.year == null) EnrichField.year,
          if (includeMetadata && t.genre == null) EnrichField.genre,
          if (includeMetadata && t.trackNumber == null) EnrichField.trackNumber,
          if (includeMetadata && !t.hasCover) EnrichField.cover,
          if (t.lyricsPlain == null && t.lyricsSynced == null) EnrichField.lyrics,
          if (t.curiosities == null) EnrichField.curiosity,
        };
        final r = prop.isEmpty
            ? (found: false, wrote: false, coverFailed: false)
            : await _apply(prop, fields, cancel: cancel);
        // apply wrote `found` itself; otherwise the sources said nothing, unless a
        // cover download failed (no answer: status unchanged).
        if (!r.wrote && !r.coverFailed) {
          final status = statusAfter(EnrichStatus.fromCode(t.enrichStatus), {
            EnrichPart.meta: PartOutcome.none,
          });
          if (status != null) await _writer.writeStatus(t.id, status);
        }
        if (r.wrote) {
          updated++;
        } else {
          notFound++;
        }
      } on RateLimitedException catch (e) {
        AppLog.w('enrichment rate limited: $e');
        yield BatchProgress(
            done: done, total: ids.length, updated: updated,
            notFound: notFound, finished: true, rateLimited: true);
        return;
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) {
          yield BatchProgress(
              done: done, total: ids.length, updated: updated,
              notFound: notFound, finished: true, cancelled: true);
          return;
        }
        rethrow;
      }
      yield BatchProgress(
          done: done, total: ids.length, updated: updated, notFound: notFound);
    }
    yield BatchProgress(
        done: done, total: ids.length, updated: updated,
        notFound: notFound, finished: true);
  }
}

