import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import '../../core/text_utils.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/track_kinds.dart';
import '../../data/repositories/track_repository.dart';
import '../covers/cover_store.dart';
import 'deezer_client.dart';
import 'deezer_match.dart';
import 'deezer_models.dart';
import 'http_client.dart';
import 'itunes_client.dart';
import 'lrclib_client.dart';
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
      bool needGenre = true}) async {
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
    return EnrichmentProposal(
        track: t,
        meta: m?.match,
        lyrics: lr,
        curiosity: cu,
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
        disc: dz.disc, isrc: dz.isrc);
  }

  final _albums = <int, DeezerAlbum>{};

  /// Null when Deezer does not confirm the track (or cannot answer).
  Future<_Meta?> _deezerLookup(Track t, CancelToken? cancel) async {
    final dz = deezer!;
    if (dz.isResting) return null;
    final want = DeezerWant(
      title: t.title,
      artist: t.artist ?? '',
      album: t.album,
      durationMs: t.durationMs > 0 ? t.durationMs : null,
      isrc: t.isrc,
    );
    try {
      DeezerTrack? hit;
      if (t.isrc != null) {
        final x = await dz.trackByIsrc(t.isrc!, cancel: cancel);
        if (x != null && acceptIsrcHit(want, x)) hit = x;
      } else {
        hit = pickDeezerTrack(
            want, await dz.searchTracks(deezerQuery(want), cancel: cancel));
      }
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
      );
    } on RateLimitedException catch (e) {
      AppLog.w('Deezer resting, using iTunes: $e');
    } on DeezerNetworkException catch (e) {
      AppLog.w('Deezer unreachable, using iTunes: $e');
    }
    return null;
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

/// [match] holds the merged fields; [disc] and [isrc] only exist on Deezer.
class _Meta {
  const _Meta(this.match, this.source, {this.disc, this.isrc});

  final ItunesMatch match;
  final String source;
  final int? disc;
  final String? isrc;
}
