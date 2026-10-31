import 'package:dio/dio.dart';

import '../../core/app_log.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/track_repository.dart';
import '../covers/cover_store.dart';
import 'deezer_client.dart';
import 'deezer_match.dart';
import 'http_client.dart';
import 'itunes_client.dart';

bool _never() => false;

/// What [CoverFetcher.fetch] came to. [sourceHasNoFile]: the source answered
/// «no such cover» (not a network error); [failed]: a network or save error.
enum CoverResult { saved, albumHasCover, sourceHasNoFile, failed }

/// Cover files: downloaded from the sources and saved in the [CoverStore].
class CoverFetcher {
  CoverFetcher({
    required this.covers,
    required this.web,
    required this.tracks,
    required this.itunes,
    this.deezer,
    this.useDeezer = _never,
    RateLimiter? limiter,
  }) : limiter = limiter ?? RateLimiter();

  final CoverStore covers;
  final WebClient web;
  final TrackRepository tracks;
  final ItunesClient itunes;
  final DeezerClient? deezer;
  final bool Function() useDeezer;

  /// The pause between online lookups, shared with the enrichment.
  final RateLimiter limiter;

  /// Downloads [url] and saves the file of [albumKey]; nothing is asked when
  /// the album has a file already (unless [replace]). A cancellation escapes.
  Future<CoverResult> fetch(String albumKey, String url,
      {bool replace = false, CancelToken? cancel}) async {
    final existing = CoverStore.coverKeyFor(albumKey);
    if (!replace && covers.fileFor(existing) != null) return CoverResult.albumHasCover;
    try {
      final bytes = await web.getBytes(url, maxBytes: CoverStore.maxBytes, cancel: cancel);
      if (bytes == null) return CoverResult.sourceHasNoFile;
      final key =
          await covers.saveFromBytes(albumKey, bytes, 'image/jpeg', overwrite: replace);
      return key == null ? CoverResult.failed : CoverResult.saved;
    } on DioException catch (e, st) {
      if (CancelToken.isCancel(e)) rethrow;
      AppLog.w('cover of $albumKey failed', e, st);
      return CoverResult.failed;
    }
  }

  /// [fetch], then points every track of the album at the file.
  Future<CoverResult> apply(String albumKey, String url,
      {bool replace = false, CancelToken? cancel}) async {
    final r = await fetch(albumKey, url, replace: replace, cancel: cancel);
    if (r == CoverResult.saved) {
      await tracks.setCoverForAlbum(albumKey, true, CoverStore.coverKeyFor(albumKey));
    }
    return r;
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
        await apply(t.albumKey, deezerUrl, cancel: cancel) == CoverResult.saved) {
      return true;
    }
    await limiter.wait();
    final found = await itunes.searchAlbum(album, artist, cancel: cancel);
    final url = found?.artworkUrl;
    if (url == null) return false;
    return await apply(t.albumKey, url, cancel: cancel) == CoverResult.saved;
  }

  /// Deezer cover of the record the ISRC belongs to, only when that record is
  /// the CSV's album (not a compilation or box set); null otherwise.
  Future<String?> _deezerCover(
      String isrc, String csvAlbum, CancelToken? cancel) async {
    final dz = deezer;
    if (dz == null || !useDeezer() || dz.isResting) return null;
    try {
      await limiter.wait();
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
}
