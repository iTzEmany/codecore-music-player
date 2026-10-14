import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../core/text_utils.dart';
import '../online/youtube_service.dart' show DownloadProgress, uniquePath;

class RemoteInfo {
  const RemoteInfo(this.name);

  final String name;
}

class RemoteTrack {
  const RemoteTrack({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    required this.sizeBytes,
    required this.durationMs,
    required this.ext,
  });

  factory RemoteTrack.fromJson(Map<String, dynamic> j) => RemoteTrack(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String?,
        album: j['album'] as String?,
        sizeBytes: (j['sizeBytes'] as num?)?.toInt() ?? 0,
        durationMs: (j['durationMs'] as num?)?.toInt() ?? 0,
        ext: j['ext'] as String? ?? 'mp3',
      );

  final int id;
  final String title;
  final String? artist, album;
  final int sizeBytes, durationMs;
  final String ext;

  /// `Artist - Title` (sanitised); used for the received file name.
  String get baseName => sanitizeFileName(
      artist == null || artist!.isEmpty ? title : '$artist - $title');
}

enum LanError { unreachable, wrongPin, blocked, notCodecore, failed }

class LanException implements Exception {
  const LanException(this.error);

  final LanError error;

  @override
  String toString() => 'LanException($error)';
}

class LanClient {
  LanClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 30),
              validateStatus: (_) => true,
            ));

  final Dio _dio;

  /// Accepts `host:port`, optionally with a `http://` prefix.
  static ({String host, int port})? parseAddress(String input) {
    var s = input.trim();
    s = s.replaceFirst(RegExp(r'^https?://'), '');
    s = s.split('/').first;
    final i = s.lastIndexOf(':');
    if (i <= 0) return null;
    final port = int.tryParse(s.substring(i + 1));
    final host = s.substring(0, i);
    if (port == null || port < 1 || port > 65535 || host.isEmpty) return null;
    return (host: host, port: port);
  }

  Options _options(String? pin, {ResponseType? type}) => Options(
        headers: {'X-Pin': ?pin},
        responseType: type,
      );

  Never _fail(Response<dynamic> r) {
    if (r.statusCode == 401) throw const LanException(LanError.wrongPin);
    if (r.statusCode == 429) throw const LanException(LanError.blocked);
    throw const LanException(LanError.failed);
  }

  Future<RemoteInfo> hello(String host, int port, {CancelToken? cancel}) async {
    try {
      final r = await _dio.get<Object?>('http://$host:$port/hello',
          cancelToken: cancel);
      final data = r.data;
      if (r.statusCode != 200 || data is! Map || data['app'] != 'codecore') {
        throw const LanException(LanError.notCodecore);
      }
      return RemoteInfo('${data['name'] ?? host}');
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw const LanException(LanError.unreachable);
    }
  }

  Future<List<RemoteTrack>> manifest(String host, int port, String pin,
      {CancelToken? cancel}) async {
    try {
      final r = await _dio.get<Object?>('http://$host:$port/manifest',
          options: _options(pin), cancelToken: cancel);
      if (r.statusCode != 200) _fail(r);
      final data = r.data;
      if (data is! List) throw const LanException(LanError.failed);
      return [
        for (final e in data)
          if (e is Map<String, dynamic>) RemoteTrack.fromJson(e),
      ];
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw const LanException(LanError.unreachable);
    }
  }

  /// Writes `<name>.<ext>.part`, checks the length, then renames. The final
  /// event carries the path. On cancel or error nothing is left behind.
  Stream<DownloadProgress> download(
    String host,
    int port,
    String pin,
    RemoteTrack track,
    Directory outDir, {
    CancelToken? cancel,
  }) async* {
    await outDir.create(recursive: true);
    final target = uniquePath(outDir.path, track.baseName, track.ext,
        (f) => File(f).existsSync());
    final part = File('$target.part');
    IOSink? sink;
    try {
      final r = await _dio.get<ResponseBody>(
        'http://$host:$port/file/${track.id}',
        options: _options(pin, type: ResponseType.stream),
        cancelToken: cancel,
      );
      if (r.statusCode != 200) _fail(r);
      final body = r.data!;
      final expected = int.tryParse(
              r.headers.value(Headers.contentLengthHeader) ?? '') ??
          track.sizeBytes;
      sink = part.openWrite();
      var received = 0;
      await for (final chunk in body.stream) {
        if (cancel?.isCancelled ?? false) break;
        sink.add(chunk);
        received += chunk.length;
        yield DownloadProgress(received: received, total: expected);
      }
      await sink.close();
      sink = null;
      if (cancel?.isCancelled ?? false) {
        await _deleteQuiet(part);
        return;
      }
      if (received != expected) {
        await _deleteQuiet(part);
        throw const LanException(LanError.failed);
      }
      await part.rename(target);
      yield DownloadProgress(received: received, total: expected, path: target);
    } on DioException catch (e) {
      await sink?.close();
      await _deleteQuiet(part);
      if (CancelToken.isCancel(e)) return;
      throw const LanException(LanError.unreachable);
    } on Object {
      await sink?.close();
      await _deleteQuiet(part);
      rethrow;
    }
  }

  Future<void> _deleteQuiet(File f) async {
    if (await f.exists()) await f.delete();
  }

  static String fileNameOf(String path) => p.basename(path);
}
