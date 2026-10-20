import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/text_utils.dart';
import 'request_budget.dart';
import 'youtube_service.dart';

/// The answer of a direct search was not what this client knows how to read
/// (YouTube changed its format, or refused in an unexpected way): the caller
/// searches with yt-dlp instead.
class InnerTubeChanged implements Exception {
  const InnerTubeChanged(this.detail);

  final String detail;

  @override
  String toString() => 'InnerTubeChanged($detail)';
}

/// The search endpoint of YouTube's own pages (InnerTube, the same one yt-dlp
/// and NewPipe call). One request answers in about half a second, where
/// starting yt-dlp takes seconds and its YouTube Music search opens every
/// video. Undocumented: every field is read defensively and anything
/// unexpected becomes [InnerTubeChanged].
class InnerTubeClient {
  InnerTubeClient([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 15),
              validateStatus: (_) => true,
            ));

  final Dio _dio;

  static const webVersion = '2.20250101.00.00';
  static const musicVersion = '1.20250101.01.00';

  /// Search filters as the sites encode them: «Videos» and «Songs».
  static const videosFilter = 'EgIQAQ%3D%3D';
  static const songsFilter = 'EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D';

  /// Videos for [query], best first, as the YouTube search page lists them.
  Future<List<YtResult>> searchVideos(String query,
          {int limit = 10, CancelToken? cancel}) async =>
      parseVideoSearch(
          await _post('https://www.youtube.com', 'WEB', webVersion, query,
              videosFilter, cancel),
          limit: limit);

  /// YouTube Music «Songs» for [query] with credited artists, album and length.
  Future<List<YtResult>> searchSongs(String query,
          {int limit = 5, CancelToken? cancel}) async =>
      parseSongSearch(
          await _post('https://music.youtube.com', 'WEB_REMIX', musicVersion,
              query, songsFilter, cancel),
          limit: limit);

  Future<Map> _post(String origin, String client, String version, String query,
      String params, CancelToken? cancel) async {
    final Response<Object?> res;
    try {
      res = await _dio.post<Object?>(
        '$origin/youtubei/v1/search',
        queryParameters: const {'prettyPrint': 'false'},
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'User-Agent': apiUserAgent,
            'Origin': origin,
            Headers.contentTypeHeader: Headers.jsonContentType,
          },
        ),
        data: {
          // No region: YouTube takes it from the address, as for yt-dlp.
          'context': {
            'client': {'clientName': client, 'clientVersion': version, 'hl': 'en'},
          },
          'query': query,
          'params': params,
        },
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      // yt-dlp would not reach YouTube either: no point in trying it.
      final offline = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => true,
        DioExceptionType.unknown => e.error is IOException,
        _ => false,
      };
      if (offline) throw YtException(YtErrorKind.network, '${e.type}: ${e.message}');
      throw InnerTubeChanged('${e.type}: ${e.error ?? e.message}');
    }
    final code = res.statusCode;
    if (code == 429) throw const YtException(YtErrorKind.rateLimited, 'HTTP 429');
    if (code != 200) throw InnerTubeChanged('HTTP $code');
    final data = res.data;
    if (data is! Map) throw const InnerTubeChanged('not JSON');
    return data;
  }

  void close() => _dio.close();
}

/// Every map stored under [key] anywhere in [node], in document order.
List<Map> _collect(Object? node, String key) {
  final out = <Map>[];
  void walk(Object? n) {
    if (n is Map) {
      for (final e in n.entries) {
        if (e.key == key && e.value is Map) {
          out.add(e.value as Map);
        } else {
          walk(e.value);
        }
      }
    } else if (n is List) {
      n.forEach(walk);
    }
  }

  walk(node);
  return out;
}

/// `{"runs": [{"text": …}]}` or `{"simpleText": …}` as plain text.
String _text(Object? node) {
  if (node is! Map) return '';
  final simple = node['simpleText'];
  if (simple is String) return simple;
  final runs = node['runs'];
  if (runs is! List) return '';
  return [
    for (final r in runs)
      if (r is Map && r['text'] is String) r['text'] as String,
  ].join();
}

final _clock = RegExp(r'^(?:(\d+):)?(\d{1,2}):(\d{2})$');

/// `3:45`, `1:02:03` → a [Duration]; anything else → null.
Duration? parseClock(String text) {
  final m = _clock.firstMatch(text.trim());
  if (m == null) return null;
  return Duration(
    hours: int.parse(m.group(1) ?? '0'),
    minutes: int.parse(m.group(2)!),
    seconds: int.parse(m.group(3)!),
  );
}

void _ensureKnown(Map data, String container) {
  final contents = data['contents'];
  if (contents is! Map || !contents.containsKey(container)) {
    throw InnerTubeChanged('no $container');
  }
}

/// Reads a YouTube (WEB client) search answer. A known answer with no videos
/// is a real «no results»; an unknown one throws [InnerTubeChanged].
List<YtResult> parseVideoSearch(Map data, {int limit = 10}) {
  _ensureKnown(data, 'twoColumnSearchResultsRenderer');
  final out = <YtResult>[];
  for (final v in _collect(data['contents'], 'videoRenderer')) {
    final id = v['videoId'];
    final title = _text(v['title']);
    if (id is! String || id.isEmpty || title.isEmpty) continue;
    final channel = _text(v['ownerText']).isNotEmpty
        ? _text(v['ownerText'])
        : _text(v['longBylineText']);
    out.add(YtResult(
      id: id,
      title: htmlUnescape(title),
      channel: htmlUnescape(channel),
      // Live streams have no length.
      duration: parseClock(_text(v['lengthText'])),
      thumbnailUrl: smallVideoThumbnail(id),
    ));
    if (out.length >= limit) break;
  }
  return out;
}

String? _pageType(Map run) {
  final endpoint = run['navigationEndpoint'];
  if (endpoint is! Map) return null;
  final browse = endpoint['browseEndpoint'];
  if (browse is! Map) return null;
  final configs = browse['browseEndpointContextSupportedConfigs'];
  if (configs is! Map) return null;
  final music = configs['browseEndpointContextMusicConfig'];
  return music is Map ? music['pageType'] as String? : null;
}

const _artistJoiners = {',', '&', 'and', 'e', 'y', 'et', 'und', 'x'};

/// Reads a YouTube Music «Songs» search answer: title in the first column;
/// `artists • album • length` in the second.
List<YtResult> parseSongSearch(Map data, {int limit = 5}) {
  _ensureKnown(data, 'tabbedSearchResultsRenderer');
  final out = <YtResult>[];
  for (final item in _collect(data['contents'], 'musicResponsiveListItemRenderer')) {
    final columns = [
      for (final c in item['flexColumns'] is List ? item['flexColumns'] as List : const [])
        if (c is Map && c['musicResponsiveListItemFlexColumnRenderer'] is Map)
          (c['musicResponsiveListItemFlexColumnRenderer'] as Map)['text'],
    ];
    if (columns.length < 2) continue;
    final title = _text(columns[0]);
    final id = _songId(item, columns[0]);
    if (id == null || title.isEmpty) continue;
    // Split the second column on « • » into groups of runs.
    final groups = <List<Map>>[[]];
    final runs = columns[1] is Map ? (columns[1] as Map)['runs'] : null;
    for (final r in runs is List ? runs : const []) {
      if (r is! Map || r['text'] is! String) continue;
      if ((r['text'] as String).trim() == '•') {
        groups.add([]);
      } else {
        groups.last.add(r);
      }
    }
    final artists = <String>[];
    String? album;
    Duration? duration;
    for (final (i, g) in groups.indexed) {
      final joined = g.map((r) => r['text'] as String).join().trim();
      final linked = g.where((r) => _pageType(r) == 'MUSIC_PAGE_TYPE_ARTIST');
      final albumRun = g.where((r) => _pageType(r) == 'MUSIC_PAGE_TYPE_ALBUM');
      if (albumRun.isNotEmpty) {
        album = (albumRun.first['text'] as String).trim();
      } else if (linked.isNotEmpty || (i == 0 && parseClock(joined) == null)) {
        // The first group is the artists even when they have no page.
        artists.addAll([
          for (final r in g)
            if (!_artistJoiners.contains((r['text'] as String).trim().toLowerCase()))
              (r['text'] as String).trim(),
        ].where((a) => a.isNotEmpty));
      } else {
        duration ??= parseClock(joined);
      }
    }
    out.add(YtResult(
      id: id,
      title: htmlUnescape(title),
      // The uploader is not in the answer: the first credited artist stands in.
      channel: artists.isEmpty ? '' : htmlUnescape(artists.first),
      duration: duration,
      thumbnailUrl: _squareThumbnail(item) ?? smallVideoThumbnail(id),
      artists: [for (final a in artists) htmlUnescape(a)],
      album: album == null ? null : htmlUnescape(album),
    ));
    if (out.length >= limit) break;
  }
  return out;
}

String? _songId(Map item, Object? titleColumn) {
  final data = item['playlistItemData'];
  if (data is Map && data['videoId'] is String) return data['videoId'] as String;
  final runs = titleColumn is Map ? titleColumn['runs'] : null;
  for (final r in runs is List ? runs : const []) {
    final watch = r is Map && r['navigationEndpoint'] is Map
        ? (r['navigationEndpoint'] as Map)['watchEndpoint']
        : null;
    if (watch is Map && watch['videoId'] is String) return watch['videoId'] as String;
  }
  return null;
}

/// The album cover the list shows, at 120×120 when offered.
String? _squareThumbnail(Map item) {
  final thumbs = _collect(item['thumbnail'], 'thumbnail');
  final list = thumbs.isEmpty ? null : thumbs.first['thumbnails'];
  if (list is! List) return null;
  String? best;
  for (final t in list) {
    if (t is! Map || t['url'] is! String) continue;
    best = t['url'] as String;
    final w = t['width'];
    if (w is num && w >= 120) break;
  }
  return best;
}
