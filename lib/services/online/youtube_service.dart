import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../core/text_utils.dart';
import 'query_cleaner.dart';

/// Where a result comes from. Both are searched and downloaded with yt-dlp.
enum MediaSource { youtube, soundcloud }

class YtResult {
  const YtResult({
    required this.id,
    required this.title,
    required this.channel,
    required this.duration,
    this.thumbnailUrl,
    this.artists = const [],
    this.album,
    this.downloadName,
    this.subdir,
    this.source = MediaSource.youtube,
    this.webpageUrl,
  });

  final String id, title, channel;
  final Duration? duration;
  final String? thumbnailUrl;

  /// Credited artists and album: only present on YouTube Music results.
  final List<String> artists;
  final String? album;

  /// File base name to use instead of the one derived from title and channel
  /// (CSV imports name files after the Spotify title and artist).
  final String? downloadName;

  /// Sub-folder of the download folder to save into (a playlist's own folder).
  final String? subdir;

  final MediaSource source;

  /// The page to download from. Only kept for sources whose id alone is no
  /// address (SoundCloud); a YouTube result is addressed by [id].
  final String? webpageUrl;

  /// What is handed to yt-dlp to download this result.
  String get downloadUrl => webpageUrl ?? 'https://www.youtube.com/watch?v=$id';

  /// Key in `downloads.json`: `youtube:<id>`, `soundcloud:<id>`.
  String get indexKey => downloadIndexKey(source, id);
}

String downloadIndexKey(MediaSource source, String id) => '${source.name}:$id';

/// `mp3` = convert to MP3 256 kbps; `original` = keep the audio as served.
enum DownloadFormat { mp3, original }

/// How a download is run; read from the settings when it starts.
class DownloadOptions {
  const DownloadOptions({this.rateLimitKBps, this.format = DownloadFormat.mp3});

  /// `--limit-rate` in KB/s; null or 0 = unlimited.
  final int? rateLimitKBps;
  final DownloadFormat format;
}

class DownloadProgress {
  const DownloadProgress({this.received = 0, this.total = 0, this.path});

  final int received, total;

  /// Set only on the last event: the final file path.
  final String? path;

  double get fraction => total <= 0 ? 0 : received / total;
}

enum YtErrorKind {
  unavailable,
  network,
  changed,
  toolMissing,
  rateLimited,

  /// yt-dlp is older than `kMinYtDlpVersion` and the request failed.
  toolOutdated,
}

class YtException implements Exception {
  const YtException(this.kind, [this.detail]);

  final YtErrorKind kind;
  final String? detail;

  @override
  String toString() => 'YtException($kind, $detail)';
}

/// `music.youtube.com` search page filtered on songs.
Uri youtubeMusicSearchUri(String query) => Uri.parse(
    'https://music.youtube.com/search?q=${Uri.encodeQueryComponent(query)}#songs');

/// `music.youtube.com` search page filtered on albums.
Uri youtubeMusicAlbumsUri(String query) => Uri.parse(
    'https://music.youtube.com/search?q=${Uri.encodeQueryComponent(query)}#albums');

const _youtubeHosts = {'youtube.com', 'www.youtube.com', 'm.youtube.com', 'youtu.be'};

bool isYoutubeUrl(String input) {
  final uri = Uri.tryParse(input.trim());
  return uri != null && uri.hasScheme && _youtubeHosts.contains(uri.host);
}

/// `<artist> - <title>` sanitised; used as base name for downloads.
String downloadBaseName(YtResult r) {
  final fixed = r.downloadName;
  if (fixed != null && sanitizeFileName(fixed) != 'track') {
    return sanitizeFileName(fixed);
  }
  final c = cleanSearchQuery(r.title, r.channel);
  final raw = c.artist.isEmpty ? c.title : '${c.artist} - ${c.title}';
  return sanitizeFileName(raw);
}

/// First free `<base>.<ext>`, then `<base> (2).<ext>`, ... Never overwrites.
String uniquePath(String dir, String base, String ext, bool Function(String) exists) {
  var candidate = p.join(dir, '$base.$ext');
  var n = 2;
  while (exists(candidate)) {
    candidate = p.join(dir, '$base ($n).$ext');
    n++;
  }
  return candidate;
}

/// Search + download backend. Desktop runs the `yt-dlp` executable; Android
/// calls yt-dlp embedded in the app through a platform channel.
abstract class YoutubeService {
  Future<List<YtResult>> search(String query);

  /// YouTube Music "Songs" results, with channel, credited artists, album and
  /// duration filled in (one request, no per-video lookups).
  Future<List<YtResult>> searchSongs(String query, {int limit = 5});

  /// Albums matching [query] on YouTube Music: [YtResult.id] is the link of the
  /// album page (there is no other data without opening it).
  Future<List<YtResult>> searchAlbums(String query, {int limit = 3});

  /// The tracks of an album page found by [searchAlbums], in album order, with
  /// artists, album name and length filled in.
  Future<List<YtResult>> albumTracks(String albumLink);

  /// Emits progress; the last event carries the final file path. A cancelled
  /// download ends without a path and leaves no partial files.
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
      {CancelToken? cancel, DownloadOptions options = const DownloadOptions()});

  /// Version string of the yt-dlp in use (`2026.08.19`); null when unknown or
  /// when the tool is missing.
  Future<String?> toolVersion();

  void close() {}
}
