import 'package:dio/dio.dart';

import '../../core/app_log.dart';
import 'credits.dart';
import 'deezer_models.dart';
import 'http_client.dart';

/// The request did not get an answer (offline, timeout, non-200): not «no data».
class DeezerNetworkException implements Exception {
  const DeezerNetworkException(this.url);

  final String url;

  @override
  String toString() => 'DeezerNetworkException($url)';
}

/// Metadata only. Deezer answers errors as HTTP 200 with `{"error":{"code":n}}`.
class DeezerClient {
  /// [now] is for tests. shortcut: the 10-minute rest lives here, not in
  /// `sourceCooldownProvider` (its key `MediaKind` has no Deezer), move it there if one is added.
  DeezerClient(this._web, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _base = 'https://api.deezer.com';
  static const cooldown = Duration(minutes: 10);

  final WebClient _web;
  final DateTime Function() _now;
  DateTime? _restUntil;

  bool get isResting => _restUntil?.isAfter(_now()) ?? false;

  Future<DeezerTrack?> trackByIsrc(String isrc, {CancelToken? cancel}) async {
    final j = await _get('$_base/track/isrc:$isrc', cancel: cancel);
    return j == null ? null : DeezerTrack.fromJson(j);
  }

  Future<List<DeezerTrack>> searchTracks(
    String q, {
    int limit = 10,
    CancelToken? cancel,
  }) async {
    final j = await _get(
      '$_base/search',
      query: {'q': q, 'limit': '$limit'},
      cancel: cancel,
    );
    final data = j?['data'];
    return [
      if (data is List)
        for (final t in data)
          if (t is Map) DeezerTrack.fromJson(t),
    ];
  }

  Future<DeezerAlbum?> album(int id, {CancelToken? cancel}) async {
    final j = await _get('$_base/album/$id', cancel: cancel);
    return j == null ? null : DeezerAlbum.fromJson(j);
  }

  /// [album] is an already-read album: it saves the `/album` request.
  Future<TrackDetails?> trackDetails(
    int deezerId, {
    DeezerAlbum? album,
    CancelToken? cancel,
  }) async {
    final j = await _get('$_base/track/$deezerId', cancel: cancel);
    if (j == null) return null;
    final albumId = j['album'] is Map
        ? (j['album'] as Map)['id'] as int?
        : null;
    final alb =
        album ??
        (albumId == null ? null : await this.album(albumId, cancel: cancel));
    final bpm = (j['bpm'] as num?)?.toDouble();
    return TrackDetails(
      bpm: bpm == null || bpm <= 0 ? null : bpm,
      label: alb?.label,
      digitalReleaseDate: alb?.releaseDate ?? j['release_date'] as String?,
      recordType: alb?.recordType,
      rank: (j['rank'] as num?)?.toInt(),
      albumFans: alb?.fans,
      explicit: j['explicit_lyrics'] as bool?,
    );
  }

  Future<Map<dynamic, dynamic>?> _get(
    String url, {
    Map<String, String>? query,
    CancelToken? cancel,
  }) async {
    if (isResting) throw const RateLimitedException(429);
    final body = await _web.getJson(url, query: query, cancel: cancel);
    // WebClient maps every failure (timeout, offline, non-200) to null; Deezer
    // never answers a bare 404, so null here is the network, not «no data».
    if (body is! Map) throw DeezerNetworkException(url);
    final err = body['error'];
    if (err is Map) {
      final code = err['code'];
      if (code == 800) return null;
      if (code == 4) {
        _restUntil = _now().add(cooldown);
        AppLog.w(
          'Deezer quota exceeded: resting for ${cooldown.inMinutes} min',
        );
        throw const RateLimitedException(429);
      }
      AppLog.w('Deezer error $code: ${err['message']}');
      return null;
    }
    return body;
  }
}
