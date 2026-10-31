import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import '../../core/clock.dart';
import '../../core/text_utils.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/credits_repository.dart';
import '../../data/repositories/track_kinds.dart';
import '../../data/repositories/track_repository.dart';
import '../covers/cover_store.dart';
import 'credits_enricher.dart';
import 'curiosity_service.dart';
import 'deezer_client.dart';
import 'deezer_gw_client.dart';
import 'deezer_match.dart';
import 'deezer_models.dart';
import 'enrich_parts.dart';
import 'enrich_writer.dart';
import 'http_client.dart';
import 'itunes_client.dart';
import 'lrclib_client.dart';
import 'lyrics_chain.dart';
import 'musicbrainz_client.dart';
import 'query_cleaner.dart';
import 'wikipedia_client.dart';

export 'credits_enricher.dart' show CreditsPart;
export 'enrich_parts.dart' show AskMode, EnrichField, EnrichPart, PartOutcome;

class EnrichmentProposal {
  const EnrichmentProposal({
    required this.track,
    this.meta,
    this.lyrics,
    this.curiosity,
    this.credits,
    this.disc,
    this.isrc,
    this.source,
  });

  final Track track;
  final ItunesMatch? meta;

  /// From Deezer only; written when the track has none.
  final int? disc;
  final String? isrc;

  /// Where [meta] came from: `deezer`, `itunes` or `deezer+itunes`.
  final String? source;
  final LyricsResult? lyrics;
  final Curiosity? curiosity;

  /// Only with «Credits and details» on; [EnrichmentService.propose] already
  /// saved them for a stored track (a shadow row saves them via [EnrichmentService.saveCredits]).
  /// Not part of [isEmpty]: credits never change the enrich status (K-AR-01).
  final CreditsPart? credits;

  String? get coverUrl => meta?.artworkUrl;
  bool get isEmpty =>
      meta == null && (lyrics == null || lyrics!.isEmpty) && curiosity == null;
}

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

/// What [EnrichmentService.gather] asked the sources for one track: kept until
/// [EnrichmentService.commit] writes it.
class EnrichGather {
  EnrichGather._(this.trackId, this.out);

  final int trackId;

  /// What each part came to; final once [EnrichmentService.commit] has run.
  final Map<EnrichPart, PartOutcome> out;

  /// The write of this track failed in commit; its parts came out failed.
  bool lost = false;

  /// The sources gave an answer: meta asked without failing, or a part found / empty.
  bool get answered =>
      _metaAsked ||
      out.values.any((o) => o == PartOutcome.found || o == PartOutcome.none);

  Track? _track; // as read; null when the track is gone
  int _now = 0;
  final _marks = <EnrichPart, int?>{}; // now = searched with nothing, null = found
  _Meta? _meta;
  bool _metaAsked = false;
  AskMode _mode = AskMode.due;
  String? _plain, _synced;
  CreditsPart? _credits;
  CuriosityLookup? _curio;
  String? _coverKey, _coverAlbum; // the file saved, and the album key it is for
  bool _coverGone = false; // the source answered «no such cover» (not a network error)

  void _settle(EnrichPart p, PartOutcome o, int now) {
    out[p] = o;
    if (o == PartOutcome.found) _marks[p] = null;
    if (o == PartOutcome.none) _marks[p] = now;
  }
}

bool _never() => false;

class EnrichmentService {
  EnrichmentService({
    required this.db,
    required this.tracks,
    required this.covers,
    required this.itunes,
    this.deezer,
    this.useDeezer = _never,
    this.gw,
    this.musicBrainz,
    this.creditsRepo,
    this.useCredits = _never,
    required this.lrclib,
    this.lyricsChain,
    this.curiosities,
    required this.wikipedia,
    required this.web,
    required this.language,
    RateLimiter? limiter,
  }) : _limiter = limiter ?? RateLimiter();

  final AppDatabase db;
  final TrackRepository tracks;
  final CoverStore covers;
  final ItunesClient itunes;
  final DeezerClient? deezer;

  /// The user's «Metadata from Deezer» option, read at each lookup.
  final bool Function() useDeezer;

  /// Credit sources and store, used only while [useCredits] (the user's
  /// «Credits and details» option, off by default) says so.
  final DeezerGwClient? gw;
  final MusicBrainzClient? musicBrainz;
  final CreditsRepository? creditsRepo;
  final bool Function() useCredits;
  bool get _creditsOn => useCredits() && creditsRepo != null;
  late final CreditsEnricher? _credits = creditsRepo == null
      ? null
      : CreditsEnricher(
          tracks: tracks,
          repo: creditsRepo!,
          deezer: deezer,
          gw: gw,
          musicBrainz: musicBrainz,
          deezerHit: _deezerHit,
          albumOf: (id) => _albums[id],
        );

  /// Writes `track_credits` and `track_enrich` only (see [CreditsEnricher.save]).
  Future<void> saveCredits(int trackId, CreditsPart? part) async =>
      _credits?.save(trackId, part);
  final LrclibClient lrclib;

  /// LRCLIB, NetEase, lyrics.ovh; LRCLIB alone when not given.
  final LyricsChain? lyricsChain;
  late final LyricsChain _chain = lyricsChain ?? LyricsChain(lrclib: lrclib);

  /// The automatic curiosity search ([completeOne]'s `curio` part); without it that part is skipped.
  final CuriosityService? curiosities;
  final WikipediaClient wikipedia;
  final WebClient web;
  final String Function() language;
  final RateLimiter _limiter;
  late final _writer = EnrichWriter(db);

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
      metadata ? guarded(_metadata(t, c, cancel, needGenre)) : Future<Object?>.value(),
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
    final m = results[0] as _Meta?;
    final lr = results[1] as LyricsResult?;
    final cu = results[2] as Curiosity?;
    if (m != null) AppLog.i('enrichment: track ${t.id} metadata from ${m.source}');
    // After the other parts: it reuses their Deezer hit and can never abort them.
    final cp = credits && _creditsOn && (forceCredits || t.id <= 0 || await _credits!.isDue(t))
        ? await _credits!.fetch(t, m?.hit, cancel)
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

  /// Deezer first (when on); iTunes only if Deezer did not confirm, gave no
  /// cover, or a genre is wanted. Deezer fields win, iTunes fills the gaps
  /// (genre goes the other way: Deezer's is a last resort).
  Future<_Meta?> _metadata(
      Track t, CleanQuery c, CancelToken? cancel, bool needGenre,
      {bool strict = false}) async {
    final dz = useDeezer() && deezer != null ? await _deezerLookup(t, cancel, strict: strict) : null;
    final needItunes = dz == null || dz.match.artworkUrl == null || needGenre;
    final it = needItunes
        ? await itunes.search(c.title, c.artist, cancel: cancel, strict: strict)
        : null;
    if (dz == null && it == null) return null;
    if (dz == null) return _Meta(it!, 'itunes');
    final d = dz.match;
    final match = ItunesMatch(
      title: d.title,
      artist: d.artist,
      album: d.album ?? it?.album,
      year: d.year ?? it?.year,
      genre: it?.genre ?? d.genre,
      trackNumber: d.trackNumber ?? it?.trackNumber,
      artworkUrl: d.artworkUrl ?? it?.artworkUrl,
    );
    return _Meta(match, it == null ? 'deezer' : 'deezer+itunes',
        disc: dz.disc, isrc: dz.isrc, hit: dz.hit);
  }

  final _albums = <int, DeezerAlbum>{};

  /// Null when Deezer does not confirm the track (or cannot answer). With
  /// [strict] «cannot answer» (resting, refused, unreachable) throws instead.
  Future<_Meta?> _deezerLookup(Track t, CancelToken? cancel,
      {bool strict = false}) async {
    final dz = deezer!;
    if (dz.isResting) {
      if (strict) throw const WebUnavailableException('deezer');
      return null;
    }
    try {
      final hit = await _deezerHit(t, cancel);
      if (hit == null) return null;
      final ref = hit.album;
      var album = ref == null ? null : _albums[ref.id];
      if (ref != null && album == null) {
        album = await dz.album(ref.id, cancel: cancel);
        if (album != null) {
          if (_albums.length >= 200) _albums.clear(); // bounded for single lookups
          _albums[ref.id] = album;
        }
      }
      final usable = album != null && checkEdition(t.album, album).albumUsable;
      final year = usable ? int.tryParse((album.releaseDate ?? '').split('-').first) : null;
      return _Meta(
        ItunesMatch(
          title: hit.title,
          artist: hit.artist,
          album: usable ? album.title : null,
          year: year,
          genre: usable && album.genres.isNotEmpty ? album.genres.first : null,
          trackNumber: usable ? hit.trackPosition : null,
          artworkUrl: usable ? (album.coverXl ?? ref?.coverXl) : null,
        ),
        'deezer',
        disc: usable ? hit.diskNumber : null,
        isrc: hit.isrc,
        hit: hit,
      );
    } on RateLimitedException catch (e) {
      if (strict) rethrow;
      AppLog.w('Deezer resting, using iTunes: $e');
    } on DeezerNetworkException catch (e) {
      if (strict) rethrow;
      AppLog.w('Deezer unreachable, using iTunes: $e');
    }
    return null;
  }

  /// The Deezer track [t] is, by ISRC or else by text; null when Deezer does
  /// not confirm it. Throws what the client throws.
  Future<DeezerTrack?> _deezerHit(Track t, CancelToken? cancel) async {
    final dz = deezer!;
    final want = DeezerWant(
      title: t.title,
      artist: t.artist ?? '',
      album: t.album,
      durationMs: t.durationMs > 0 ? t.durationMs : null,
      isrc: t.isrc,
    );
    if (t.isrc != null) {
      final x = await dz.trackByIsrc(t.isrc!, cancel: cancel);
      return x != null && acceptIsrcHit(want, x) ? x : null;
    }
    return pickDeezerTrack(
        want, await dz.searchTracks(deezerQuery(want), cancel: cancel));
  }

  /// Fills [parts] of one track; the caller says which are on: [gather] then
  /// [commit] of one track.
  Future<Map<EnrichPart, PartOutcome>> completeOne(
    int trackId,
    Set<EnrichPart> parts, {
    bool force = false,
    CancelToken? cancel,
  }) async {
    final g = await gather(
      trackId,
      parts,
      mode: force ? AskMode.force : AskMode.due,
      cancel: cancel,
    );
    return (await commit([g])).single;
  }

  /// The reading half of [completeOne]: asks the sources and writes nothing
  /// to the database (the cover file is the only thing saved). A part is asked
  /// for only when empty and [isDue] under [mode] (see [AskMode]). Metadata
  /// and lyrics are asked side by side, then credits, then curiosities. The
  /// caller sets the pace.
  Future<EnrichGather> gather(
    int trackId,
    Set<EnrichPart> parts, {
    AskMode mode = AskMode.due,
    CancelToken? cancel,
  }) async {
    final g = EnrichGather._(trackId, {
      for (final p in parts) p: PartOutcome.skipped,
    });
    final out = g.out;
    final t = await tracks.getById(trackId);
    if (t == null) return g;
    g._track = t;
    g._mode = mode;
    final enrich = await (db.select(
      db.trackEnrich,
    )..where((e) => e.trackId.equals(trackId))).getSingleOrNull();
    final now = g._now = nowMs();
    final at = DateTime.fromMillisecondsSinceEpoch(now);
    bool due(EnrichPart p) =>
        parts.contains(p) && isDue(p, t, enrich, at, mode: mode);
    final doMeta = due(EnrichPart.meta);
    final doLyrics = due(EnrichPart.lyrics);
    final doSynced = due(EnrichPart.synced);
    final gwc = gw;
    final doCredits =
        _creditsOn &&
        parts.contains(EnrichPart.credits) &&
        (musicBrainz != null || (gwc != null && !gwc.isPaused)) &&
        (mode == AskMode.force ||
            isDue(
              EnrichPart.credits,
              t,
              enrich,
              at,
              mode: mode,
              hasCredits: (await creditsRepo!.creditsOf(trackId)).isNotEmpty,
            ));
    final doCurio = curiosities != null && due(EnrichPart.curio);
    // now = searched with nothing, null = found
    void settle(EnrichPart p, PartOutcome o) => g._settle(p, o, now);

    final c = cleanSearchQuery(t.title, t.artist ?? '');
    final metaF = doMeta
        ? _attempt(
            'metadata',
            () => _metadata(t, c, cancel, t.genre == null, strict: true),
          )
        : null;
    final lyrF = doLyrics || doSynced
        ? _attempt(
            'lyrics',
            () => _chain.find(
              t,
              wantSynced: parts.contains(EnrichPart.synced),
              cancel: cancel,
            ),
            timeout: false,
          )
        : null;
    // Both settle before a cancellation is rethrown.
    await Future.wait<Object?>([?metaF, ?lyrF]);
    final meta = g._meta = (await metaF)?.value;
    // Settled in [commit]: «found» means a field was filled.
    final metaAsked = g._metaAsked = metaF != null && !(await metaF).failed;
    if (metaF != null && !metaAsked) {
      out[EnrichPart.meta] = _lost((await metaF).limited);
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
      final lostO = _lost(r.limited || (res?.limited ?? false));
      if (doLyrics) {
        g._plain = hasPlain ? text!.plain : null;
        settle(
          EnrichPart.lyrics,
          hasPlain || hasSynced
              ? PartOutcome.found
              : lost
              ? lostO
              : PartOutcome.none,
        );
      }
      if (hasSynced) g._synced = text!.synced;
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

    _throwIfCancelled(cancel);
    if (doCredits) {
      final r = await _attempt(
        'credits',
        () => _credits!.fetch(t, meta?.hit, cancel),
        timeout: false,
      );
      final creditsPart = g._credits = r.value;
      // CreditsEnricher.save writes the credits mark itself.
      out[EnrichPart.credits] = creditsPart == null
          ? _lost(r.limited)
          : creditsPart.credits.isNotEmpty
          ? PartOutcome.found
          : creditsPart.complete
          ? PartOutcome.none
          : _lost(creditsPart.limited);
    }
    _throwIfCancelled(cancel);
    if (doCurio) {
      final r = await _attempt(
        'curiosity',
        () => curiosities!.find(t, language(), cancel: cancel),
        timeout: false,
      );
      final l = g._curio = r.value;
      if (l == null || l.outcome.failed) {
        out[EnrichPart.curio] = _lost(r.limited);
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
      final key = _albumKeyOf(t, null, album);
      try {
        // A file saved earlier (by another track of the album) is reused.
        final known = CoverStore.coverKeyFor(key);
        g._coverKey = covers.fileFor(known) != null
            ? known
            : await _fetchCover(key, url, false, cancel,
                onGone: () => g._coverGone = true);
        g._coverAlbum = key;
      } on DioException catch (e, st) {
        if (CancelToken.isCancel(e)) rethrow;
        AppLog.w('completion: cover of track $trackId failed', e, st);
      } on Object catch (e, st) {
        AppLog.w('completion: cover of track $trackId failed', e, st);
      }
    }
    return g;
  }

  /// The writing half of [completeOne]: `tracks` (empty columns only), the
  /// cover, `track_credits`, the curiosities and `track_enrich` of every item
  /// in ONE transaction (a block of tracks costs one write to the library,
  /// not one per track). A track whose write fails is logged and its parts
  /// come out `failed`; the others are kept. Returns the outcome of each item.
  Future<List<Map<EnrichPart, PartOutcome>>> commit(
    List<EnrichGather> items,
  ) async {
    await db.transaction(() async {
      for (final g in items) {
        if (g._track == null) continue;
        try {
          await db.transaction(() => _commitOne(g));
        } on Object catch (e, st) {
          if (e is Error) {
            AppLog.e('completion: track ${g.trackId} not saved', e, st);
          } else {
            AppLog.w('completion: track ${g.trackId} not saved', e, st);
          }
          g.lost = true;
          g.out.updateAll(
            (_, o) => o == PartOutcome.skipped ? o : PartOutcome.failed,
          );
        }
      }
    });
    return [for (final g in items) g.out];
  }

  Future<void> _commitOne(EnrichGather g) async {
    final trackId = g.trackId, out = g.out, marks = g._marks;
    // The row may have changed (or be gone) while the sources were asked.
    final f = await tracks.getById(trackId);
    if (f == null) {
      out.updateAll((_, _) => PartOutcome.skipped); // nothing was saved
      return;
    }
    final fields = fillableFields(f);
    final at = DateTime.fromMillisecondsSinceEpoch(g._now);
    // A part the row no longer needs (filled meanwhile by another track of the
    // album, the download enricher or a refresh) is left alone: not «found»,
    // not «nothing».
    final enrichRow = await (db.select(
      db.trackEnrich,
    )..where((e) => e.trackId.equals(trackId))).getSingleOrNull();
    final byUser = enrichRow?.lyricsByUser ?? false;
    final metaEmpty = isDue(EnrichPart.meta, f, enrichRow, at, mode: AskMode.force);
    void leave(EnrichPart p) {
      if (out.containsKey(p)) out[p] = PartOutcome.skipped;
      marks.remove(p);
    }

    if (byUser || f.lyricsPlain != null || f.lyricsSynced != null) {
      leave(EnrichPart.lyrics);
    }
    if (byUser || f.lyricsSynced != null) leave(EnrichPart.synced);
    final meta = g._meta;
    final m = meta?.match;
    final fills =
        m != null &&
        ((fields.contains(EnrichField.album) && m.album != null) ||
            (fields.contains(EnrichField.year) && m.year != null) ||
            (fields.contains(EnrichField.genre) && m.genre != null) ||
            (fields.contains(EnrichField.trackNumber) &&
                (m.trackNumber != null ||
                    (meta!.disc != null && f.discNumber == null))) ||
            (meta!.isrc != null && f.isrc == null));
    // The cover is the only thing meta would fill.
    final coverPending =
        g._metaAsked &&
        !fills &&
        m?.artworkUrl != null &&
        !f.hasCover &&
        f.coverSource == 0;
    // A cover that is yet to be applied settles meta after it.
    final metaLeft = g._metaAsked && !coverPending && !fills && !metaEmpty;
    if (g._metaAsked && !coverPending && !metaLeft) {
      g._settle(
        EnrichPart.meta,
        fills ? PartOutcome.found : PartOutcome.none,
        g._now,
      );
    }
    final plain = f.lyricsPlain == null && !byUser ? g._plain : null;
    final synced = f.lyricsSynced == null && !byUser ? g._synced : null;
    var albumKey = f.albumKey;
    if (fills || plain != null || synced != null) {
      albumKey = (await _writeFields(
        f,
        EnrichmentProposal(
          track: f,
          meta: fills ? m : null,
          disc: fills ? meta!.disc : null,
          isrc: fills ? meta!.isrc : null,
          lyrics: LyricsResult(plain: plain, synced: synced),
        ),
        fields,
      )).key;
    }
    // Only if the album is still the one the file was saved for.
    final coverKey = g._coverKey;
    final saved =
        coverKey != null &&
        g._coverAlbum == albumKey &&
        !f.hasCover &&
        f.coverSource == 0;
    if (saved) await tracks.setCoverForAlbum(albumKey, true, coverKey);
    if (coverPending) {
      // No cover, nothing else filled: not «found». A cover that does not exist
      // is «nothing» (mark set); a download that failed is unknown (mark stays, invariant 3).
      if (!saved && g._coverGone) {
        g._settle(EnrichPart.meta, PartOutcome.none, g._now);
      } else {
        out[EnrichPart.meta] = saved ? PartOutcome.found : PartOutcome.failed;
      }
      if (saved) marks[EnrichPart.meta] = null;
    }
    if (g._credits != null) {
      if (g._mode != AskMode.force && (await creditsRepo!.creditsOf(trackId)).isNotEmpty) {
        leave(EnrichPart.credits);
      } else {
        await _credits!.save(trackId, g._credits);
      }
    }
    final lookup = g._curio;
    if (lookup != null && g._mode != AskMode.force && f.curiosities != null) {
      leave(EnrichPart.curio);
    } else if (lookup != null &&
        (await curiosities!.save(trackId, lookup)).failed) {
      out[EnrichPart.curio] = PartOutcome.failed;
      marks.remove(EnrichPart.curio);
    }
    if (marks.isNotEmpty) {
      Value<int?> mark(EnrichPart p) =>
          marks.containsKey(p) ? Value(marks[p]) : const Value.absent();
      final row = TrackEnrichCompanion(
        trackId: Value(trackId),
        metaNoneAt: mark(EnrichPart.meta),
        lyricsNoneAt: mark(EnrichPart.lyrics),
        syncedNoneAt: mark(EnrichPart.synced),
        curioNoneAt: mark(EnrichPart.curio),
      );
      await db
          .into(db.trackEnrich)
          .insert(row, onConflict: DoUpdate((_) => row));
    }
    final status = statusAfter(EnrichStatus.fromCode(f.enrichStatus), out);
    if (status != null && status.code != f.enrichStatus) {
      await _writer.writeStatus(trackId, status);
    }
  }

  /// One source of [completeOne]: its answer, or `failed` (logged) when it
  /// threw, timed out or was refused. A cancellation escapes.
  Future<({T? value, bool failed, bool limited})> _attempt<T>(
    String what,
    Future<T?> Function() ask, {
    bool timeout = true,
  }) async {
    try {
      final f = ask();
      return (
        value: await (timeout ? f.timeout(const Duration(seconds: 25)) : f),
        failed: false,
        limited: false,
      );
    } on DioException catch (e, st) {
      if (CancelToken.isCancel(e)) rethrow;
      AppLog.w('completion: $what failed', e, st);
    } on RateLimitedException catch (e) {
      AppLog.w('completion: $what refused', e);
      return (value: null, failed: true, limited: true);
    } on Object catch (e, st) {
      AppLog.w('completion: $what failed', e, st);
    }
    return (value: null, failed: true, limited: false);
  }

  /// A part that got no answer: refused (`limited`) or broken (`failed`).
  PartOutcome _lost(bool limited) =>
      limited ? PartOutcome.limited : PartOutcome.failed;

  /// Rethrows a cancellation the way a cancelled request does.
  void _throwIfCancelled(CancelToken? cancel) {
    if (cancel != null && cancel.isCancelled) {
      throw cancel.cancelError ??
          DioException.requestCancelled(
            requestOptions: RequestOptions(),
            reason: 'cancelled',
          );
    }
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
    final w = await _writeFields(t, p, f);
    var found = w.found, wrote = w.wrote, coverFailed = false;
    if (w.wrote) await _writer.writeStatus(t.id, EnrichStatus.found);
    if (f.contains(EnrichField.cover) && p.coverUrl != null) {
      try {
        final saved =
            await _applyCover(t.id, w.key, p.coverUrl!, replaceCover, cancel);
        found = saved || found;
        if (saved && !w.wrote) {
          wrote = true;
          await _writer.writeStatus(t.id, EnrichStatus.found);
        }
      } on DioException catch (e, st) {
        if (CancelToken.isCancel(e)) rethrow;
        coverFailed = true;
        AppLog.w('apply: cover of track ${t.id} failed', e, st);
      }
    }
    return (found: found, wrote: wrote, coverFailed: coverFailed);
  }

  /// The `tracks` row of [apply] (and of [completeOne]) for [f], without the
  /// cover or the status. `found`: something was proposed; `wrote`: a field
  /// was written. Also the album key.
  Future<({bool found, bool wrote, String key})> _writeFields(
      Track t, EnrichmentProposal p, Set<EnrichField> f) async {
    final m = p.meta;
    final title = f.contains(EnrichField.title) ? m?.title : null;
    final artist = f.contains(EnrichField.artist) ? m?.artist : null;
    final album = f.contains(EnrichField.album) ? m?.album : null;
    final key = _albumKeyOf(t, artist, album);
    final found = m != null || (p.lyrics != null && !p.lyrics!.isEmpty) ||
        p.curiosity != null;
    final year = f.contains(EnrichField.year) ? m?.year : null;
    final genre = f.contains(EnrichField.genre) ? m?.genre : null;
    final disc = f.contains(EnrichField.trackNumber) && t.discNumber == null
        ? p.disc
        : null;
    final isrc = t.isrc == null ? p.isrc : null;
    final number = f.contains(EnrichField.trackNumber) ? m?.trackNumber : null;
    final plain = f.contains(EnrichField.lyrics) ? p.lyrics?.plain : null;
    final synced = f.contains(EnrichField.lyrics) ? p.lyrics?.synced : null;
    final curiosity = f.contains(EnrichField.curiosity) && p.curiosity != null
        ? '${p.curiosity!.text}\n${p.curiosity!.source}'
        : null;
    Value<T> opt<T>(T? v) => v == null ? const Value.absent() : Value(v);
    await (db.update(db.tracks)..where((r) => r.id.equals(t.id))).write(
      TracksCompanion(
        title: opt(title),
        artist: opt(artist),
        album: opt(album),
        albumKey: Value(key),
        year: opt(year),
        genre: opt(genre),
        discNumber: opt(disc),
        isrc: opt(isrc),
        trackNumber: opt(number),
        lyricsPlain: opt(plain),
        lyricsSynced: opt(synced),
        curiosities: opt(curiosity),
      ),
    );
    await tracks.settleMovedCover(t, key);
    final wrote = [title, artist, album, year, genre, disc, isrc, number, plain, synced, curiosity]
        .any((v) => v != null);
    return (found: found, wrote: wrote, key: key);
  }

  /// The album key of [t] once [artist] and [album] (when not null) are written.
  String _albumKeyOf(Track t, String? artist, String? album) {
    // A streamed shadow row keeps its own `stream|<key>` album key.
    if ((artist == null && album == null) || t.kind == kStreamKind) {
      return t.albumKey;
    }
    return computeAlbumKey(
        albumArtist: t.albumArtist,
        artist: artist ?? t.artist,
        album: album ?? t.album,
        directory: _dirOf(t.path));
  }

  /// Downloads the cover and saves its file; the `coverKey`, or null when the
  /// album has a file already (unless [replace]) or nothing could be saved.
  /// [onGone] runs when the source has no such file (a local save error does not).
  Future<String?> _fetchCover(String albumKey, String url, bool replace,
      CancelToken? cancel, {void Function()? onGone}) async {
    final existing = CoverStore.coverKeyFor(albumKey);
    if (!replace && covers.fileFor(existing) != null) return null;
    final bytes = await web.getBytes(url, cancel: cancel);
    if (bytes == null) {
      onGone?.call();
      return null;
    }
    return covers.saveFromBytes(albumKey, bytes, 'image/jpeg', overwrite: replace);
  }

  Future<bool> _applyCover(int trackId, String albumKey, String url,
      bool replace, CancelToken? cancel) async {
    final key = await _fetchCover(albumKey, url, replace, cancel);
    if (key == null) return false;
    await tracks.setCoverForAlbum(albumKey, true, key);
    return true;
  }

  /// The cover of the album named in a playlist file, looked up by album and
  /// artist. Does nothing when the album already has one; true when saved.
  Future<bool> coverForAlbum(Track t, String album, String artist,
      {String? isrc, CancelToken? cancel}) async {
    if (covers.fileFor(CoverStore.coverKeyFor(t.albumKey)) != null) return false;
    final deezerUrl = isrc == null || isrc.isEmpty
        ? null
        : await _deezerCover(isrc, album, cancel);
    try {
      if (deezerUrl != null &&
          await _applyCover(t.id, t.albumKey, deezerUrl, false, cancel)) {
        return true;
      }
    } on DioException catch (e, st) {
      if (CancelToken.isCancel(e)) rethrow;
      AppLog.w('Deezer cover download failed, trying iTunes', e, st);
    }
    await _limiter.wait();
    final found = await itunes.searchAlbum(album, artist, cancel: cancel);
    final url = found?.artworkUrl;
    if (url == null) return false;
    return _applyCover(t.id, t.albumKey, url, false, cancel);
  }

  /// Deezer cover of the record the ISRC belongs to, only when that record is
  /// the CSV's album (not a compilation or box set); null otherwise.
  Future<String?> _deezerCover(
      String isrc, String csvAlbum, CancelToken? cancel) async {
    final dz = deezer;
    if (dz == null || !useDeezer() || dz.isResting) return null;
    try {
      await _limiter.wait();
      final hit = await dz.trackByIsrc(isrc, cancel: cancel);
      final ref = hit?.album;
      if (ref == null) return null;
      final full = await dz.album(ref.id, cancel: cancel);
      if (full == null || !checkEdition(csvAlbum, full).albumUsable) return null;
      return full.coverXl;
    } on DeezerNetworkException catch (e) {
      AppLog.w('Deezer cover by ISRC failed: $e');
    } on RateLimitedException catch (e) {
      AppLog.w('Deezer cover by ISRC rate limited: $e');
    }
    return null;
  }

  String _dirOf(String path) => p.dirname(path);

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
    _albums.clear();
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

/// [match] holds the merged fields; [disc], [isrc] and [hit] only exist on Deezer.
class _Meta {
  const _Meta(this.match, this.source, {this.disc, this.isrc, this.hit});

  final ItunesMatch match;
  final String source;
  final int? disc;
  final String? isrc;
  final DeezerTrack? hit;
}
