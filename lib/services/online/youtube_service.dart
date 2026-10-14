import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../core/app_log.dart';
import '../../core/text_utils.dart';
import 'query_cleaner.dart';

class YtResult {
  const YtResult({
    required this.id,
    required this.title,
    required this.channel,
    required this.duration,
    this.thumbnailUrl,
  });

  final String id, title, channel;
  final Duration? duration;
  final String? thumbnailUrl;
}

class DownloadProgress {
  const DownloadProgress({this.received = 0, this.total = 0, this.path});

  final int received, total;

  /// Set only on the last event: the final file path.
  final String? path;

  double get fraction => total <= 0 ? 0 : received / total;
}

enum YtErrorKind { unavailable, network, changed }

class YtException implements Exception {
  const YtException(this.kind, [this.detail]);

  final YtErrorKind kind;
  final String? detail;

  @override
  String toString() => 'YtException($kind, $detail)';
}

const _youtubeHosts = {'youtube.com', 'www.youtube.com', 'm.youtube.com', 'youtu.be'};

bool isYoutubeUrl(String input) {
  final uri = Uri.tryParse(input.trim());
  return uri != null && uri.hasScheme && _youtubeHosts.contains(uri.host);
}

/// `<artist> - <title>` sanitised; used as base name for downloads.
String downloadBaseName(YtResult r) {
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

class YoutubeService {
  YoutubeService([YoutubeExplode? yt]) : _yt = yt ?? YoutubeExplode();

  final YoutubeExplode _yt;

  YtResult _map(Video v) => YtResult(
        id: v.id.value,
        title: v.title,
        channel: v.author,
        duration: v.duration,
        thumbnailUrl: v.thumbnails.mediumResUrl,
      );

  Future<List<YtResult>> search(String query) async {
    try {
      final q = query.trim();
      if (isYoutubeUrl(q)) {
        final id = VideoId.parseVideoId(q);
        if (id == null) return const [];
        return [_map(await _yt.videos.get(id))];
      }
      if (q.isEmpty) return const [];
      final res = await _yt.search.search(q);
      return res.take(15).map(_map).toList();
    } on Object catch (e, st) {
      throw _translate(e, st);
    }
  }

  YtException _translate(Object e, StackTrace st) {
    AppLog.w('youtube error', e, st);
    if (e is YtException) return e;
    if (e is SocketException || e is TimeoutException) {
      return YtException(YtErrorKind.network, '$e');
    }
    if (e is VideoUnavailableException ||
        e is VideoUnplayableException ||
        e is VideoRequiresPurchaseException) {
      return YtException(YtErrorKind.unavailable, '$e');
    }
    if (e is YoutubeExplodeException) {
      final text = '$e'.toLowerCase();
      if (text.contains('socket') || text.contains('connection')) {
        return YtException(YtErrorKind.network, '$e');
      }
    }
    return YtException(YtErrorKind.changed, '$e');
  }

  Stream<DownloadProgress> download(YtResult r, Directory outDir,
      {CancelToken? cancel}) async* {
    File? part;
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(r.id);
      final audio = manifest.audioOnly;
      if (audio.isEmpty) throw const YtException(YtErrorKind.unavailable);
      final mp4 = audio.where((s) => s.container.name == 'mp4').toList();
      final pool = mp4.isNotEmpty ? mp4 : audio.toList();
      final info = pool.reduce(
          (a, b) => a.bitrate.bitsPerSecond >= b.bitrate.bitsPerSecond ? a : b);
      final ext = info.container.name == 'mp4' ? 'm4a' : info.container.name;
      await outDir.create(recursive: true);
      final target = uniquePath(
          outDir.path, downloadBaseName(r), ext, (f) => File(f).existsSync());
      part = File('$target.part');
      final sink = part.openWrite();
      final total = info.size.totalBytes;
      var received = 0;
      try {
        await for (final chunk in _yt.videos.streamsClient.get(info)) {
          if (cancel?.isCancelled ?? false) break;
          sink.add(chunk);
          received += chunk.length;
          yield DownloadProgress(received: received, total: total);
        }
      } finally {
        await sink.close();
      }
      if (cancel?.isCancelled ?? false) {
        await _deleteQuiet(part);
        return;
      }
      await part.rename(target);
      yield DownloadProgress(received: received, total: total, path: target);
    } on Object catch (e, st) {
      if (part != null) await _deleteQuiet(part);
      throw _translate(e, st);
    }
  }

  Future<void> _deleteQuiet(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } on Object catch (e, st) {
      AppLog.w('delete partial failed: ${f.path}', e, st);
    }
  }

  void close() => _yt.close();
}
