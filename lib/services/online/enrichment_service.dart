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
import 'http_client.dart';
import 'itunes_client.dart';
import 'lrclib_client.dart';
import 'lyrics_chain.dart';
import 'musicbrainz_client.dart';
import 'query_cleaner.dart';
import 'wikipedia_client.dart';

export 'credits_enricher.dart' show CreditsPart;
export 'enrich_parts.dart' show EnrichPart, PartOutcome;

enum EnrichField {
  title,
  artist,
  album,
  year,
  genre,
  trackNumber,
  cover,
  lyrics,
  curiosity
}

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
          ? guarded(_chain.find(t, cancel: cancel).then((r) => r.lyrics))
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

  /// Fills [parts] of one track; the caller says which are on. A part is asked
  /// for only when empty and [isDue]; [force] also asks with a recent «searched,
  /// nothing» mark. Valid and empty → `*_none_at = now`; found → cleared; an
  /// error or a refusal → left as it was (invariant 3). Metadata and lyrics are
  /// asked side by side, then credits, then curiosities; `tracks` (empty
  /// columns only), `track_credits` and `track_enrich` are written in one
  /// transaction at the end. The curiosities and the cover are saved by their
  /// own steps. The caller sets the pace.
  Future<Map<EnrichPart, PartOutcome>> completeOne(
    int trackId,
    Set<EnrichPart> parts, {
    bool force = false,
    CancelToken? cancel,
  }) async {
    final out = {for (final p in parts) p: PartOutcome.skipped};
    final t = await tracks.getById(trackId);
    if (t == null) return out;
    final enrich = await (db.select(
      db.trackEnrich,
    )..where((e) => e.trackId.equals(trackId))).getSingleOrNull();
    final now = nowMs();
    final at = DateTime.fromMillisecondsSinceEpoch(now);
    bool due(EnrichPart p) =>
        parts.contains(p) && isDue(p, t, enrich, at, force: force);
    final doMeta = due(EnrichPart.meta);
    final doLyrics = due(EnrichPart.lyrics);
    final doSynced = due(EnrichPart.synced);
    final g = gw;
    final doCredits =
        _creditsOn &&
        parts.contains(EnrichPart.credits) &&
        (musicBrainz != null || (g != null && !g.isPaused)) &&
        await _credits!.isDue(t, force: force);
    final doCurio = curiosities != null && due(EnrichPart.curio);
    final marks =
        <EnrichPart, int?>{}; // now = searched with nothing, null = found
    void settle(EnrichPart p, PartOutcome o) {
      out[p] = o;
      if (o == PartOutcome.found) marks[p] = null;
      if (o == PartOutcome.none) marks[p] = now;
    }

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
          )
        : null;
    // Both settle before a cancellation is rethrown.
    await Future.wait<Object?>([?metaF, ?lyrF]);
    final meta = (await metaF)?.value;
    // Settled in the transaction: «found» means a field was filled.
    final metaAsked = metaF != null && !(await metaF).failed;
    if (metaF != null && !metaAsked) {
      out[EnrichPart.meta] = _lost((await metaF).limited);
    }
    String? plainW, syncedW;
    if (lyrF != null) {
      final r = await lyrF;
      final res = r.value;
      final text = res?.lyrics;
      final hasPlain = text?.plain?.isNotEmpty ?? false;
      final hasSynced = text?.synced?.isNotEmpty ?? false;
      final lost =
          r.failed ||
          (res?.failed ?? false); // no answer is not an empty answer
      final lostO = _lost(r.limited);
      if (doLyrics) {
        plainW = hasPlain ? text!.plain : null;
        settle(
          EnrichPart.lyrics,
          hasPlain || hasSynced
              ? PartOutcome.found
              : lost
              ? lostO
              : PartOutcome.none,
        );
      }
      if (hasSynced) syncedW = text!.synced;
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

    CreditsPart? creditsPart;
    _throwIfCancelled(cancel);
    if (doCredits) {
      final r = await _attempt(
        'credits',
        () => _credits.fetch(t, meta?.hit, cancel),
        timeout: false,
      );
      creditsPart = r.value;
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
        () => curiosities!.fetch(t, language(), cancel: cancel),
        timeout: false,
      );
      final o = r.value;
      if (o == null || o.failed) {
        out[EnrichPart.curio] = _lost(r.limited);
      } else if (o.limited) {
        out[EnrichPart.curio] = PartOutcome.limited;
      } else {
        // The part is the track's own text: an artist bio alone leaves it empty.
        final has = (await tracks.getById(trackId))?.curiosities != null;
        settle(EnrichPart.curio, has ? PartOutcome.found : PartOutcome.none);
      }
    }

    Track? fresh;
    var albumKey = t.albumKey;
    var coverPending = false; // the cover is the only thing meta would fill
    await db.transaction(() async {
      // The row may have changed (or be gone) while the sources were asked.
      fresh = await tracks.getById(trackId);
      final f = fresh;
      if (f == null) return;
      final fields = <EnrichField>{
        if (f.album == null && !f.userEdited) EnrichField.album,
        if (f.year == null) EnrichField.year,
        if (f.genre == null) EnrichField.genre,
        if (f.trackNumber == null) EnrichField.trackNumber,
        EnrichField.lyrics,
      };
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
      coverPending =
          metaAsked &&
          !fills &&
          m?.artworkUrl != null &&
          !f.hasCover &&
          f.coverSource == 0;
      // A cover that is yet to be downloaded settles meta after the download.
      if (metaAsked && !coverPending) {
        settle(EnrichPart.meta, fills ? PartOutcome.found : PartOutcome.none);
      }
      // The user may have saved a text while the sources were asked.
      final byUser =
          (await (db.select(db.trackEnrich)
                    ..where((e) => e.trackId.equals(trackId)))
                  .getSingleOrNull())
              ?.lyricsByUser ??
          false;
      final plain = f.lyricsPlain == null && !byUser ? plainW : null;
      final synced = f.lyricsSynced == null && !byUser ? syncedW : null;
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
        )).$2;
      } else if (metaAsked && !coverPending) {
        // Like enrichMany: nothing found for the track → status 2.
        await (db.update(db.tracks)..where((r) => r.id.equals(trackId))).write(
          const TracksCompanion(enrichStatus: Value(2)),
        );
      }
      if (creditsPart != null) await _credits!.save(trackId, creditsPart);
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
    });
    final f = fresh;
    final url = metaAsked ? meta?.match.artworkUrl : null;
    // Never over a hand-made cover (cover_source > 0) or an existing one.
    if (f != null && url != null && !f.hasCover && f.coverSource == 0) {
      var saved = false;
      try {
        saved = await _applyCover(trackId, albumKey, url, false, cancel);
      } on DioException catch (e, st) {
        if (CancelToken.isCancel(e)) rethrow;
        AppLog.w('completion: cover of track $trackId failed', e, st);
      } on Object catch (e, st) {
        AppLog.w('completion: cover of track $trackId failed', e, st);
      }
      if (coverPending) {
        // No cover, nothing else filled: not «found», and the mark stays (invariant 3).
        out[EnrichPart.meta] = saved ? PartOutcome.found : PartOutcome.failed;
        if (saved) await _markMetaFound(trackId);
      }
    }
    return out;
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

  /// The cover was the only thing meta filled: clears the «nothing» mark.
  Future<void> _markMetaFound(int trackId) => db.transaction(() async {
    await (db.update(db.tracks)..where((r) => r.id.equals(trackId))).write(
      const TracksCompanion(enrichStatus: Value(1)),
    );
    final row = TrackEnrichCompanion(
      trackId: Value(trackId),
      metaNoneAt: const Value(null),
    );
    await db.into(db.trackEnrich).insert(row, onConflict: DoUpdate((_) => row));
  });

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
  Future<bool> apply(EnrichmentProposal p, Set<EnrichField> fields,
      {CancelToken? cancel, bool replaceCover = false}) async {
    final t = await tracks.getById(p.track.id) ?? p.track;
    final f = {...fields};
    if (t.userEdited) {
      f.removeAll({EnrichField.title, EnrichField.artist, EnrichField.album});
    }
    var (found, key) = await _writeFields(t, p, f);
    if (f.contains(EnrichField.cover) && p.coverUrl != null) {
      found = await _applyCover(t.id, key, p.coverUrl!, replaceCover, cancel) ||
          found;
    }
    return found;
  }

  /// The `tracks` row of [apply] (and of [completeOne]) for [f], without the
  /// cover. Returns whether something was found and the album key.
  Future<(bool, String)> _writeFields(
      Track t, EnrichmentProposal p, Set<EnrichField> f) async {
    final m = p.meta;
    final title = f.contains(EnrichField.title) ? m?.title : null;
    final artist = f.contains(EnrichField.artist) ? m?.artist : null;
    final album = f.contains(EnrichField.album) ? m?.album : null;
    final newArtist = artist ?? t.artist;
    final newAlbum = album ?? t.album;
    // A streamed shadow row keeps its own `stream|<key>` album key.
    final changedKey = (artist != null || album != null) && t.kind != kStreamKind;
    final key = changedKey
        ? computeAlbumKey(
            albumArtist: t.albumArtist,
            artist: newArtist,
            album: newAlbum,
            directory: _dirOf(t.path))
        : t.albumKey;
    final found = m != null || (p.lyrics != null && !p.lyrics!.isEmpty) ||
        p.curiosity != null;
    await (db.update(db.tracks)..where((r) => r.id.equals(t.id))).write(
      TracksCompanion(
        title: title == null ? const Value.absent() : Value(title),
        artist: artist == null ? const Value.absent() : Value(artist),
        album: album == null ? const Value.absent() : Value(album),
        albumKey: Value(key),
        year: f.contains(EnrichField.year) && m?.year != null
            ? Value(m!.year)
            : const Value.absent(),
        genre: f.contains(EnrichField.genre) && m?.genre != null
            ? Value(m!.genre)
            : const Value.absent(),
        discNumber: f.contains(EnrichField.trackNumber) &&
                p.disc != null &&
                t.discNumber == null
            ? Value(p.disc)
            : const Value.absent(),
        isrc: p.isrc != null && t.isrc == null
            ? Value(p.isrc)
            : const Value.absent(),
        trackNumber: f.contains(EnrichField.trackNumber) && m?.trackNumber != null
            ? Value(m!.trackNumber)
            : const Value.absent(),
        lyricsPlain: f.contains(EnrichField.lyrics) && p.lyrics?.plain != null
            ? Value(p.lyrics!.plain)
            : const Value.absent(),
        lyricsSynced: f.contains(EnrichField.lyrics) && p.lyrics?.synced != null
            ? Value(p.lyrics!.synced)
            : const Value.absent(),
        curiosities:
            f.contains(EnrichField.curiosity) && p.curiosity != null
                ? Value('${p.curiosity!.text}\n${p.curiosity!.source}')
                : const Value.absent(),
        enrichStatus: Value(found ? 1 : 2),
      ),
    );
    return (found, key);
  }

  Future<bool> _applyCover(int trackId, String albumKey, String url,
      bool replace, CancelToken? cancel) async {
    final existing = CoverStore.coverKeyFor(albumKey);
    if (!replace && covers.fileFor(existing) != null) return false;
    final bytes = await web.getBytes(url, cancel: cancel);
    if (bytes == null) return false;
    final key =
        await covers.saveFromBytes(albumKey, bytes, 'image/jpeg', overwrite: replace);
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
    if (deezerUrl != null &&
        await _applyCover(t.id, t.albumKey, deezerUrl, false, cancel)) {
      return true;
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
        final found = prop.isEmpty ? false : await apply(prop, fields, cancel: cancel);
        if (prop.isEmpty) {
          await (db.update(db.tracks)..where((r) => r.id.equals(t.id)))
              .write(const TracksCompanion(enrichStatus: Value(2)));
        }
        if (found) {
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
