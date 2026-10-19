import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import '../../core/text_utils.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/track_repository.dart';
import '../covers/cover_store.dart';
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
  });

  final Track track;
  final ItunesMatch? meta;
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
/// for it explicitly.
bool needsEnrichment(
  Track t, {
  bool metadata = true,
  bool lyrics = true,
  bool curiosities = false,
}) {
  if (t.enrichStatus == 2) return false;
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

class EnrichmentService {
  EnrichmentService({
    required this.db,
    required this.tracks,
    required this.covers,
    required this.itunes,
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
  final LrclibClient lrclib;
  final WikipediaClient wikipedia;
  final WebClient web;
  final String Function() language;
  final RateLimiter _limiter;

  /// Reads only: nothing is written until [apply].
  Future<EnrichmentProposal> propose(Track t,
      {CancelToken? cancel,
      bool lyrics = true,
      bool curiosity = true,
      bool metadata = true}) async {
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
      metadata
          ? guarded(itunes.search(c.title, c.artist, cancel: cancel))
          : Future<Object?>.value(),
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
    final meta = results[0] as ItunesMatch?;
    final lr = results[1] as LyricsResult?;
    final cu = results[2] as Curiosity?;
    return EnrichmentProposal(
        track: t, meta: meta, lyrics: lr, curiosity: cu);
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
    final changedKey = artist != null || album != null;
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
      {CancelToken? cancel}) async {
    if (covers.fileFor(CoverStore.coverKeyFor(t.albumKey)) != null) return false;
    await _limiter.wait();
    final found = await itunes.searchAlbum(album, artist, cancel: cancel);
    final url = found?.artworkUrl;
    if (url == null) return false;
    return _applyCover(t.id, t.albumKey, url, false, cancel);
  }

  String _dirOf(String path) => p.dirname(path);

  /// Fills only empty fields; never touches title/artist.
  Stream<BatchProgress> enrichMany(
    List<int> ids, {
    CancelToken? cancel,
    bool includeLyrics = true,
    bool includeCuriosities = false,
    bool includeMetadata = true,
  }) async* {
    var updated = 0, notFound = 0, done = 0;
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
              curiosities: includeCuriosities)) {
        yield BatchProgress(
            done: done, total: ids.length, updated: updated, notFound: notFound);
        continue;
      }
      try {
        await _limiter.wait();
        final prop = await propose(t,
            cancel: cancel,
            metadata: includeMetadata,
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
