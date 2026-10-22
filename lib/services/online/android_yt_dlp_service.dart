import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import 'yt_dlp_args.dart';
import 'yt_dlp_process_service.dart';
import 'youtube_service.dart';

/// yt-dlp embedded in the Android app (see MainActivity.kt).
class AndroidYtDlpService implements YoutubeService, StreamSource {
  AndroidYtDlpService() {
    _channel.setMethodCallHandler(_onCall);
  }

  static const _channel = MethodChannel('codecore/ytdlp');

  /// A search that takes longer is cancelled and reported as a network error.
  static const searchTimeout = Duration(seconds: 45);
  /// Stream resolution with the default clients can run YouTube's JS challenge
  /// on the phone: much slower than a search, so it has its own limit.
  static const streamTimeout = Duration(seconds: 90);
  static const fastStreamTimeout = Duration(seconds: 20);
  final _progress = <String, StreamController<DownloadProgress>>{};
  int _counter = 0;

  Future<dynamic> _onCall(MethodCall call) async {
    if (call.method != 'progress') return null;
    final args = call.arguments as Map;
    final c = _progress['${args['processId']}'];
    // youtubedl-android says -1 until it knows the size.
    final percent = ((args['percent'] as num?)?.toDouble() ?? 0).clamp(0, 100);
    c?.add(DownloadProgress(received: percent.round(), total: 100));
    return null;
  }

  /// Calls the `search` method with a process id so that a search that hangs
  /// can be killed on the Kotlin side after [searchTimeout].
  Future<List<YtResult>> _search(Map<String, Object?> args,
          {List<YtResult> Function(String raw) parse = parseYtDlpJson}) async =>
      parse(await _call(args));

  Future<String> _call(Map<String, Object?> args,
      {Duration? timeout, String method = 'search'}) async {
    final processId = 'sr-${_counter++}';
    try {
      final raw = await _channel
          .invokeMethod<String>(method, {...args, 'processId': processId})
          .timeout(timeout ?? searchTimeout);
      return raw ?? '{}';
    } on TimeoutException {
      await _channel.invokeMethod<void>('cancel', {'processId': processId});
      throw const YtException(YtErrorKind.network, 'search timed out');
    } on PlatformException catch (e) {
      AppLog.w('yt-dlp search failed: ${e.message}');
      throw ytExceptionFromStderr(e.message ?? '');
    }
  }

  @override
  Future<List<YtResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    return _search({'query': q, 'isUrl': isYoutubeUrl(q)});
  }

  @override
  Future<Uri> streamUrl(YtResult r) async {
    // Fast path: the android_vr client needs neither the JS challenge solver
    // nor a PO token (~2 s instead of ~45 s on the phone). If it cannot serve
    // this video (age limit, region...) yt-dlp's default clients take over.
    try {
      final fast = await _call(
          {'url': r.downloadUrl, 'format': streamFormat, 'fast': true},
          method: 'streamUrl', timeout: fastStreamTimeout);
      final uri = parseStreamUrl(fast);
      if (uri != null) return uri;
    } on YtException catch (e) {
      AppLog.i('listen: fast client failed (${e.kind}), using default clients');
    }
    final out = await _call(
        {'url': r.downloadUrl, 'format': streamFormat},
        method: 'streamUrl', timeout: streamTimeout);
    return parseStreamUrl(out) ??
        (throw const YtException(YtErrorKind.changed, 'no stream address'));
  }

  @override
  Future<PlaylistListing> listPlaylist(String url, {int limit = 500}) async {
    final raw = await _call({
      'query': url,
      'isUrl': true,
      'items': limit,
      'flat': true,
    }, timeout: const Duration(seconds: 120));
    try {
      return parsePlaylistListing(raw, limit: limit);
    } on FormatException catch (e, st) {
      AppLog.w('yt-dlp playlist output not JSON', e, st);
      throw const YtException(YtErrorKind.changed, 'bad output');
    }
  }

  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    return _search({
      'query': youtubeMusicSearchUri(q).toString(),
      'isUrl': true,
      'items': limit,
    });
  }

  @override
  Future<List<YtResult>> searchAlbums(String query, {int limit = 3}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    return _search({
      'query': youtubeMusicAlbumsUri(q).toString(),
      'isUrl': true,
      'items': limit,
      'flat': true,
    }, parse: parseYtAlbumLinks);
  }

  @override
  /// Flat: one request for the page, not one per track (see [parseYtAlbumPage]).
  Future<List<YtResult>> albumTracks(String albumLink) => _search(
      {'query': albumLink, 'isUrl': true, 'items': 80, 'flat': true},
      parse: parseYtAlbumPage);

  @override
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
      {CancelToken? cancel,
      DownloadOptions options = const DownloadOptions()}) async* {
    await outDir.create(recursive: true);
    // yt-dlp in the app always comes with ffmpeg.
    final choice = downloadChoice(options.format, hasFfmpeg: true);
    final target = uniquePath(
        outDir.path,
        downloadBaseName(r),
        reservedExtension(hasFfmpeg: true, options: options),
        (f) => anyDownloadExtensionExists(f, (x) => File(x).existsSync()));
    final stem = p.withoutExtension(target);
    final processId = 'dl-${_counter++}';
    final controller = StreamController<DownloadProgress>();
    _progress[processId] = controller;
    unawaited(cancel?.whenCancel.then((_) {
      _channel.invokeMethod<void>('cancel', {'processId': processId});
    }));
    final done = _channel.invokeMethod<String>('download', {
      'id': r.id,
      'url': r.downloadUrl,
      'stem': stem,
      'selector': choice.selector,
      'audioFormat': choice.audioFormat,
      'audioQuality': choice.quality,
      'processId': processId,
      'rateLimit': options.rateLimitKBps,
    }).then<String?>((path) => path).catchError((Object e) {
      if (cancel?.isCancelled ?? false) return null;
      final msg = e is PlatformException ? (e.message ?? '') : '$e';
      throw ytExceptionFromStderr(msg);
    });
    unawaited(done.then((_) => controller.close(),
        onError: (Object _) => controller.close()));
    try {
      await for (final p in controller.stream) {
        yield p;
      }
      final path = await done;
      if (cancel?.isCancelled ?? false) {
        await _deleteStem(stem);
        return;
      }
      if (path == null) {
        throw const YtException(YtErrorKind.changed, 'no output');
      }
      yield DownloadProgress(received: 100, total: 100, path: path);
    } finally {
      _progress.remove(processId);
    }
  }

  Future<void> _deleteStem(String stem) async {
    final dir = Directory(p.dirname(stem));
    final base = p.basename(stem);
    if (!await dir.exists()) return;
    await for (final e in dir.list()) {
      if (e is File && p.basename(e.path).startsWith('$base.')) {
        await e.delete();
      }
    }
  }

  @override
  Future<String?> toolVersion() async {
    try {
      final v = await _channel.invokeMethod<String>('version');
      return (v == null || v.trim().isEmpty) ? null : v.trim();
    } on PlatformException catch (e, st) {
      AppLog.w('yt-dlp version lookup failed', e, st);
      return null;
    }
  }

  @override
  void close() {}
}
