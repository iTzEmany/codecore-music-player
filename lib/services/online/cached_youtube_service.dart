import 'dart:io';

import 'package:dio/dio.dart';

import 'search_cache.dart';
import 'youtube_service.dart';

String _norm(String q) => q.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Answers repeated searches from [cache]. Used by the CSV import only: the
/// interactive search in the Search tab always asks YouTube.
class CachedYoutubeService implements YoutubeService {
  CachedYoutubeService(this.inner, this.cache);

  final YoutubeService inner;
  final SearchCache cache;

  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) async {
    final key = 'songs|${_norm(query)}|$limit';
    final hit = await cache.get(key);
    if (hit != null) return hit;
    final res = await inner.searchSongs(query, limit: limit);
    await cache.put(key, res);
    return res;
  }

  @override
  Future<List<YtResult>> search(String query) async {
    final key = 'plain|${_norm(query)}';
    final hit = await cache.get(key);
    if (hit != null) return hit;
    final res = await inner.search(query);
    await cache.put(key, res);
    return res;
  }

  @override
  Future<List<YtResult>> searchSoundCloud(String query, {int limit = 5}) async {
    final key = 'sc|${_norm(query)}|$limit';
    final hit = await cache.get(key);
    if (hit != null) return hit;
    final res = await inner.searchSoundCloud(query, limit: limit);
    await cache.put(key, res);
    return res;
  }

  @override
  Future<List<YtResult>> searchAlbums(String query, {int limit = 3}) async {
    final key = 'albums|${_norm(query)}|$limit';
    final hit = await cache.get(key);
    if (hit != null) return hit;
    final res = await inner.searchAlbums(query, limit: limit);
    await cache.put(key, res);
    return res;
  }

  @override
  Future<List<YtResult>> albumTracks(String albumLink) async {
    final key = 'album|$albumLink';
    final hit = await cache.get(key);
    if (hit != null) return hit;
    final res = await inner.albumTracks(albumLink);
    await cache.put(key, res);
    return res;
  }

  /// Forgets every cached answer to [queries] (a video that turned out to be
  /// unavailable must not be proposed again from the cache).
  Future<void> forget(Iterable<String> queries) {
    final wanted = {for (final q in queries) _norm(q)};
    return cache.removeWhere((key) => wanted
        .any((q) =>
            key.startsWith('songs|$q|') ||
            key.startsWith('sc|$q|') ||
            key == 'plain|$q'));
  }

  @override
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
          {CancelToken? cancel,
          DownloadOptions options = const DownloadOptions()}) =>
      inner.download(r, outDir, cancel: cancel, options: options);

  @override
  Future<String?> toolVersion() => inner.toolVersion();

  @override
  void close() {}
}
