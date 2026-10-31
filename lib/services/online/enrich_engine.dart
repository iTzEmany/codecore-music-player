import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/app_log.dart';
import '../../core/clock.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/track_repository.dart';
import 'cover_fetcher.dart';
import 'credits_enricher.dart';
import 'curiosity_service.dart';
import 'enrich_commit.dart';
import 'enrich_gather.dart';
import 'enrich_parts.dart';
import 'enrich_writer.dart';
import 'http_client.dart' show RateLimiter;
import 'lyrics_chain.dart';
import 'metadata_resolver.dart';
import 'query_cleaner.dart';

export 'enrich_gather.dart' show CommitResult, EnrichGather, GatherSignal;

bool _never() => false;

/// The one engine that fills a track's parts: [gather] asks the sources,
/// [commit] writes, [completeOne] does both. Never calls `EnrichmentService`.
class EnrichEngine {
  EnrichEngine({
    required this.db,
    required this.tracks,
    required this.resolver,
    required this.covers,
    required this.chain,
    this.credits,
    this.curiosities,
    required this.language,
    this.useCredits = _never,
    RateLimiter? limiter,
  }) : limiter = limiter ?? RateLimiter(),
       _writer = EnrichWriter(db, tracks) {
    _committer = EnrichCommitter(
      db,
      tracks,
      _writer,
      credits: credits,
      curiosities: curiosities,
    );
  }

  final AppDatabase db;
  final TrackRepository tracks;
  final MetadataResolver resolver;
  final CoverFetcher covers;
  final LyricsChain chain;

  /// Credit sources and store, used only while [useCredits] (the user's
  /// «Credits and details» option, off by default) says so.
  final CreditsEnricher? credits;
  final bool Function() useCredits;
  bool get _creditsOn => useCredits() && credits != null;

  /// The automatic curiosity search (`curio` part); without it that part is skipped.
  final CuriosityService? curiosities;
  final String Function() language;

  /// The pause between online lookups.
  final RateLimiter limiter;
  final EnrichWriter _writer;
  late final EnrichCommitter _committer;

  /// Tracks gathered and not yet committed: a second gather of the same id
  /// asks nothing, and [completeOne] waits for the commit.
  final _inFlight = <int, ({EnrichGather owner, Completer<void> done})>{};

  /// Fills [parts] of one track; the caller says which are on: [gather] then
  /// [commit] of one track. Waits first for a gather of the same track.
  Future<Map<EnrichPart, PartOutcome>> completeOne(
    int trackId,
    Set<EnrichPart> parts, {
    bool force = false,
    CancelToken? cancel,
  }) async {
    for (var w = _inFlight[trackId]; w != null; w = _inFlight[trackId]) {
      await w.done.future;
    }
    final g = await gather(
      trackId,
      parts,
      mode: force ? AskMode.force : AskMode.due,
      cancel: cancel,
    );
    return (await commit([g])).single.out;
  }

  void _release(EnrichGather g) {
    final e = _inFlight[g.trackId];
    if (e == null || !identical(e.owner, g)) return;
    _inFlight.remove(g.trackId);
    e.done.complete();
  }

  /// The reading half of [completeOne]: asks the sources and writes nothing
  /// to the database (the cover file is the only thing saved). A part is asked
  /// for only when empty and [isDue] under [mode] (see [AskMode]). Metadata
  /// and lyrics are asked side by side, then credits, then curiosities. The
  /// caller sets the pace. A track already in flight comes back all `skipped`.
  Future<EnrichGather> gather(
    int trackId,
    Set<EnrichPart> parts, {
    AskMode mode = AskMode.due,
    CancelToken? cancel,
  }) async {
    final g = EnrichGather(trackId, {
      for (final p in parts) p: PartOutcome.skipped,
    });
    if (_inFlight.containsKey(trackId)) return g;
    _inFlight[trackId] = (owner: g, done: Completer<void>()); // before the first await
    try {
      await _gather(g, parts, mode, cancel);
    } on Object {
      _release(g);
      rethrow;
    }
    if (g.track == null) _release(g);
    return g;
  }

  Future<void> _gather(
    EnrichGather g,
    Set<EnrichPart> parts,
    AskMode mode,
    CancelToken? cancel,
  ) async {
    final trackId = g.trackId, out = g.out;
    final t = await tracks.getById(trackId);
    if (t == null) return;
    g.track = t;
    g.mode = mode;
    final enrich = await (db.select(
      db.trackEnrich,
    )..where((e) => e.trackId.equals(trackId))).getSingleOrNull();
    final now = g.now = nowMs();
    final at = DateTime.fromMillisecondsSinceEpoch(now);
    bool due(EnrichPart p) =>
        parts.contains(p) && isDue(p, t, enrich, at, mode: mode);
    final doMeta = due(EnrichPart.meta);
    final doLyrics = due(EnrichPart.lyrics);
    final doSynced = due(EnrichPart.synced);
    final doCredits =
        _creditsOn &&
        parts.contains(EnrichPart.credits) &&
        credits!.canAsk &&
        (mode == AskMode.force ||
            isDue(
              EnrichPart.credits,
              t,
              enrich,
              at,
              mode: mode,
              hasCredits: (await credits!.repo.creditsOf(trackId)).isNotEmpty,
            ));
    final doCurio = curiosities != null && due(EnrichPart.curio);
    // now = searched with nothing, null = found
    void settle(EnrichPart p, PartOutcome o) => g.settle(p, o, now);

    final c = cleanSearchQuery(t.title, t.artist ?? '');
    final metaF = doMeta
        ? attemptSource(
            'metadata',
            () => resolver.resolve(t, c, cancel, t.genre == null, strict: true),
          )
        : null;
    final lyrF = doLyrics || doSynced
        ? attemptSource(
            'lyrics',
            () => chain.find(
              t,
              wantSynced: parts.contains(EnrichPart.synced),
              cancel: cancel,
            ),
            timeout: false,
          )
        : null;
    // Both settle before a cancellation is rethrown.
    await Future.wait<Object?>([?metaF, ?lyrF]);
    final meta = g.meta = (await metaF)?.value;
    // Settled in [commit]: «found» means a field was filled.
    final metaAsked = g.metaAsked = metaF != null && !(await metaF).failed;
    if (metaF != null && !metaAsked) {
      out[EnrichPart.meta] = lostOutcome((await metaF).limited);
    }
    if (lyrF != null) {
      final r = await lyrF;
      final res = r.value;
      final text = res?.lyrics;
      final hasPlain = text?.plain?.isNotEmpty ?? false;
      final hasSynced = text?.synced?.isNotEmpty ?? false;
      final lost =
          r.failed ||
          (res?.failed ?? false); // no answer is not an empty answer
      final lostO = lostOutcome(r.limited || (res?.limited ?? false));
      if (doLyrics) {
        g.plain = hasPlain ? text!.plain : null;
        settle(
          EnrichPart.lyrics,
          hasPlain || hasSynced
              ? PartOutcome.found
              : lost
              ? lostO
              : PartOutcome.none,
        );
      }
      if (hasSynced) g.synced = text!.synced;
      if (parts.contains(EnrichPart.synced) &&
          (doSynced || (doLyrics && hasPlain))) {
        settle(
          EnrichPart.synced,
          hasSynced
              ? PartOutcome.found
              : r.failed || (res?.syncedFailed ?? false)
              ? lostO
              : PartOutcome.none,
        );
      }
    }

    throwIfCancelled(cancel);
    if (doCredits) {
      final r = await attemptSource(
        'credits',
        () => credits!.fetch(t, meta?.hit, cancel),
        timeout: false,
      );
      final creditsPart = g.credits = r.value;
      // CreditsEnricher.save writes the credits mark itself.
      out[EnrichPart.credits] = creditsPart == null
          ? lostOutcome(r.limited)
          : creditsPart.credits.isNotEmpty
          ? PartOutcome.found
          : creditsPart.complete
          ? PartOutcome.none
          : lostOutcome(creditsPart.limited);
    }
    throwIfCancelled(cancel);
    if (doCurio) {
      final r = await attemptSource(
        'curiosity',
        () => curiosities!.find(t, language(), cancel: cancel),
        timeout: false,
      );
      final l = g.curio = r.value;
      if (l == null || l.outcome.failed) {
        out[EnrichPart.curio] = lostOutcome(r.limited);
      } else if (l.pair.song == null && l.outcome.songLimited) {
        out[EnrichPart.curio] = PartOutcome.limited;
      } else {
        // The part is the track's own text: an artist bio alone leaves it empty.
        settle(
          EnrichPart.curio,
          l.pair.song != null ? PartOutcome.found : PartOutcome.none,
        );
      }
    }

    // The cover file is saved here (network); [commit] only points the album at it.
    final url = metaAsked ? meta?.match.artworkUrl : null;
    // Never over a hand-made cover (cover_source > 0) or an existing one.
    if (url != null && !t.hasCover && t.coverSource == 0) {
      final album = fillableFields(t).contains(EnrichField.album)
          ? meta!.match.album
          : null;
      final key = _writer.albumKeyOf(t, null, album);
      try {
        // A file saved earlier (by another track of the album) is reused.
        g.cover = await covers.fetch(key, url, cancel: cancel);
        g.coverAlbum = key;
      } on Object catch (e, st) {
        if (e is DioException && CancelToken.isCancel(e)) rethrow;
        if (e is Error) {
          AppLog.e('completion: cover of track $trackId failed', e, st);
        } else {
          AppLog.w('completion: cover of track $trackId failed', e, st);
        }
      }
    }
  }

  /// The writing half of [completeOne]: `tracks` (empty columns only), the
  /// cover, `track_credits`, the curiosities and `track_enrich` of every item
  /// in ONE transaction (a block of tracks costs one write to the library,
  /// not one per track). A track whose write fails is logged and its parts
  /// come out `failed`; the others are kept. Returns one result per item.
  Future<List<CommitResult>> commit(List<EnrichGather> items) async {
    final lost = <int>{};
    try {
      await db.transaction(() async {
        for (final g in items) {
          if (g.track == null) continue;
          try {
            await db.transaction(() => _committer.commitOne(g));
          } on Object catch (e, st) {
            if (e is Error) {
              AppLog.e('completion: track ${g.trackId} not saved', e, st);
            } else {
              AppLog.w('completion: track ${g.trackId} not saved', e, st);
            }
            lost.add(g.trackId);
            g.out.updateAll(
              (_, o) => o == PartOutcome.skipped ? o : PartOutcome.failed,
            );
          }
        }
      });
    } finally {
      items.forEach(_release);
    }
    return [
      for (final g in items)
        (trackId: g.trackId, out: g.out, lost: lost.contains(g.trackId)),
    ];
  }
}
