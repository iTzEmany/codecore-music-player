import 'dart:convert';

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
import 'credits.dart';
import 'deezer_client.dart';
import 'deezer_gw_client.dart';
import 'deezer_match.dart';
import 'deezer_models.dart';
import 'http_client.dart';
import 'itunes_client.dart';
import 'lrclib_client.dart';
import 'musicbrainz_client.dart';
import 'query_cleaner.dart';
import 'wikipedia_client.dart';

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

/// What the credits sources said about one track. Never touches `tracks`.
class CreditsPart {
  const CreditsPart({
    this.credits = const [],
    this.details,
    this.deezerId,
    this.mbid,
    this.failed = const {},
  });

  /// Deezer's first, then what MusicBrainz adds ([mergeCredits]).
  final List<TrackCredit> credits;
  final TrackDetails? details;
  final int? deezerId;
  final String? mbid;

  /// The credit sources (`deezer`, `musicbrainz`) that did not answer. Only
  /// when none failed (a valid empty answer counts) may an empty result be
  /// remembered as «searched, nothing» (invariant 3).
  final Set<String> failed;
  bool get complete => failed.isEmpty;
}

/// The parts [EnrichmentService.completeOne] can fill (phase 52 adds the rest).
enum EnrichPart { credits }

/// What one part of [EnrichmentService.completeOne] came to. [failed]: a source
/// did not answer and no «searched, nothing» mark was written; [skipped]: off,
/// not due, or no source reachable (no call made).
enum PartOutcome { found, none, failed, skipped }

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
  final LrclibClient lrclib;
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
          ? guarded(lrclib.find(
              title: c.title,
              artist: c.artist,
              album: t.album,
              durationSec:
                  t.durationMs > 0 ? (t.durationMs / 1000).round() : null,
              cancel: cancel))
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
    final cp = credits && _creditsOn && (forceCredits || t.id <= 0 || await _creditsDue(t.id, false))
        ? await _creditsPart(t, m?.hit, cancel)
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
      Track t, CleanQuery c, CancelToken? cancel, bool needGenre) async {
    final dz = useDeezer() && deezer != null ? await _deezerLookup(t, cancel) : null;
    final needItunes = dz == null || dz.match.artworkUrl == null || needGenre;
    final it = needItunes
        ? await itunes.search(c.title, c.artist, cancel: cancel)
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

  /// Null when Deezer does not confirm the track (or cannot answer).
  Future<_Meta?> _deezerLookup(Track t, CancelToken? cancel) async {
    final dz = deezer!;
    if (dz.isResting) return null;
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
      AppLog.w('Deezer resting, using iTunes: $e');
    } on DeezerNetworkException catch (e) {
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

  /// Deezer id (given [known] by the metadata part, else looked up even with
  /// «Metadata from Deezer» off, and then nothing but credits comes of it:
  /// R-36), details, Deezer and MusicBrainz credits. Each source is guarded on
  /// its own; only a cancellation escapes.
  Future<CreditsPart> _creditsPart(
      Track t, DeezerTrack? known, CancelToken? cancel) async {
    final failed = <String>{};
    // [origin] is the credit source that gets no answer when [ask] fails
    // (no answer is not an empty answer: invariant 3).
    Future<T?> source<T>(String origin, String name, Future<T?> Function() ask) async {
      try {
        return await ask().timeout(const Duration(seconds: 25));
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) rethrow;
        AppLog.w('credits source $name failed', e);
      } catch (e, st) {
        AppLog.w('credits source $name failed', e, st);
      }
      failed.add(origin);
      return null;
    }

    final dz = deezer;
    var hit = known;
    if (hit == null) {
      if (dz == null || dz.isResting) {
        failed.add('deezer');
      } else {
        hit = await source('deezer', 'deezer lookup', () => _deezerHit(t, cancel));
      }
    }
    final found = hit;
    final isrc = t.isrc ?? found?.isrc;
    final mb = musicBrainz;

    Future<(TrackDetails?, DeezerContributors?)> deezerBranch() async {
      if (found == null || dz == null) return (null, null);
      final d = await source(
          'deezer',
          'deezer details',
          () => dz.trackDetails(found.id,
              album: _albums[found.album?.id], cancel: cancel));
      final g = gw;
      final ready = g == null
          ? null
          : await source('deezer', 'deezer gw', () async {
              await g.load();
              return !g.isPaused;
            });
      if (ready != true) {
        failed.add('deezer'); // paused, missing or unreadable
        return (d, null);
      }
      return (d, await source('deezer', 'deezer page', () => g!.pageTrack(found.id)));
    }

    Future<(String?, List<TrackCredit>)> mbBranch() async {
      if (mb == null) {
        failed.add('musicbrainz');
        return (null, const <TrackCredit>[]);
      }
      if (isrc == null) return (null, const <TrackCredit>[]);
      final recs = await source(
          'musicbrainz',
          'musicbrainz isrc',
          () => mb.recordingsByIsrc(isrc, t.durationMs,
              title: t.title, artist: t.artist ?? '', cancel: cancel, strict: true));
      final mbid = recs?.firstOrNull?.id;
      if (mbid == null) return (null, const <TrackCredit>[]);
      final credits = await source('musicbrainz', 'musicbrainz credits',
          () => mb.recordingCredits(mbid, cancel: cancel));
      return (mbid, credits ?? const <TrackCredit>[]);
    }

    // Different services: asked side by side. (Not a record `.wait`, which
    // would wrap a cancellation in a ParallelWaitError.)
    final both = await Future.wait<Object?>([deezerBranch(), mbBranch()]);
    final (details, page) = both[0] as (TrackDetails?, DeezerContributors?);
    final (mbid, mbCredits) = both[1] as (String?, List<TrackCredit>);
    return CreditsPart(
      credits: mergeCredits(page?.credits ?? const [], mbCredits),
      details: details == null && page == null
          ? null
          : (details ?? const TrackDetails()).copyWith(
              copyright: page?.copyright,
              physicalReleaseDate: page?.physicalReleaseDate),
      deezerId: found?.id,
      mbid: mbid,
      failed: failed,
    );
  }

  /// No credits yet and not searched with an empty answer.
  Future<bool> _creditsDue(int trackId, bool force) async {
    if (force) return true;
    final repo = creditsRepo!;
    return (await repo.enrichOf(trackId))?.creditsNoneAt == null &&
        (await repo.creditsOf(trackId)).isEmpty;
  }

  /// Writes `track_credits` and `track_enrich` only. Found → the none mark is
  /// cleared; valid and empty → marked now; any failure → left as it was.
  Future<void> saveCredits(int trackId, CreditsPart? part) async {
    final repo = creditsRepo;
    if (part == null || repo == null) return;
    // The track may have been deleted while the sources were asked (FK).
    if (await tracks.getById(trackId) == null) {
      AppLog.i('credits: track $trackId is gone, nothing saved');
      return;
    }
    var list = part.credits;
    if (list.isNotEmpty && !part.complete) {
      // A source was down: keep only what it gave in an earlier run.
      list = mergeCredits(list, [
        for (final c in await repo.creditsOf(trackId))
          if (part.failed.contains(c.source)) TrackCredit(c.name, c.role, c.source)
      ]);
    }
    final row = TrackEnrichCompanion(
      trackId: Value(trackId),
      details: part.details == null
          ? const Value.absent()
          : Value(jsonEncode(part.details!.toJson())),
      deezerId: part.deezerId == null ? const Value.absent() : Value(part.deezerId),
      mbid: part.mbid == null ? const Value.absent() : Value(part.mbid),
      creditsNoneAt: list.isNotEmpty
          ? const Value(null)
          : part.complete
              ? Value(nowMs())
              : const Value.absent(),
    );
    // Empty and complete replaces what was stored: credits and the none mark never coexist.
    if (list.isEmpty && !part.complete) return repo.saveEnrich(row);
    await repo.save(trackId, [
      for (final c in list)
        TrackCreditsCompanion.insert(
            trackId: trackId,
            name: c.name,
            nameKey: c.nameKey,
            role: c.role,
            source: c.source)
    ], row);
  }

  /// Fills [parts] of one track: for now only the credits (and details), and
  /// only while «Credits and details» is on. Skipped when the track has them
  /// or they were searched with an empty answer, unless [force]. The caller
  /// sets the pace.
  Future<Map<EnrichPart, PartOutcome>> completeOne(int trackId, Set<EnrichPart> parts,
      {bool force = false, CancelToken? cancel}) async {
    if (!parts.contains(EnrichPart.credits)) return const {};
    Map<EnrichPart, PartOutcome> only(PartOutcome o) => {EnrichPart.credits: o};
    if (!_creditsOn) return only(PartOutcome.skipped);
    final t = await tracks.getById(trackId);
    if (t == null || !await _creditsDue(trackId, force)) {
      return only(PartOutcome.skipped);
    }
    final g = gw;
    if (musicBrainz == null && (g == null || g.isPaused)) {
      return only(PartOutcome.skipped);
    }
    final part = await _creditsPart(t, null, cancel);
    await saveCredits(trackId, part);
    return only(part.credits.isNotEmpty
        ? PartOutcome.found
        : part.complete
            ? PartOutcome.none
            : PartOutcome.failed);
  }

  /// Writes only [fields]; `userEdited` tracks keep title/artist/album.
  Future<bool> apply(EnrichmentProposal p, Set<EnrichField> fields,
      {CancelToken? cancel, bool replaceCover = false}) async {
    final t = await tracks.getById(p.track.id) ?? p.track;
    final f = {...fields};
    if (t.userEdited) {
      f.removeAll({EnrichField.title, EnrichField.artist, EnrichField.album});
    }
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
    var found = m != null || (p.lyrics != null && !p.lyrics!.isEmpty) ||
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
    if (f.contains(EnrichField.cover) && p.coverUrl != null) {
      found = await _applyCover(t.id, key, p.coverUrl!, replaceCover, cancel) ||
          found;
    }
    return found;
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
