import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'yt_dlp_process_service.dart';
import 'youtube_service.dart';

/// yt-dlp embedded in the Android app (see MainActivity.kt).
class AndroidYtDlpService implements YoutubeService {
  AndroidYtDlpService() {
    _channel.setMethodCallHandler(_onCall);
  }

  static const _channel = MethodChannel('codecore/ytdlp');
  final _progress = <String, StreamController<DownloadProgress>>{};
  int _counter = 0;

  Future<dynamic> _onCall(MethodCall call) async {
    if (call.method != 'progress') return null;
    final args = call.arguments as Map;
    final c = _progress['${args['processId']}'];
    final percent = (args['percent'] as num?)?.toDouble() ?? 0;
    c?.add(DownloadProgress(received: percent.round(), total: 100));
    return null;
  }

  @override
  Future<List<YtResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    try {
      final raw = await _channel.invokeMethod<String>(
          'search', {'query': q, 'isUrl': isYoutubeUrl(q)});
      return parseYtDlpJson(raw ?? '{}');
    } on PlatformException catch (e) {
      throw ytExceptionFromStderr(e.message ?? '');
    }
  }

  @override
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
      {CancelToken? cancel}) async* {
    await outDir.create(recursive: true);
    final target = uniquePath(
        outDir.path, downloadBaseName(r), 'mp3', (f) => File(f).existsSync());
    final stem = p.withoutExtension(target);
    final processId = 'dl-${_counter++}';
    final controller = StreamController<DownloadProgress>();
    _progress[processId] = controller;
    unawaited(cancel?.whenCancel.then((_) {
      _channel.invokeMethod<void>('cancel', {'processId': processId});
    }));
    final done = _channel.invokeMethod<String>('download', {
      'id': r.id,
      'stem': stem,
      'convert': true,
      'processId': processId,
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
  void close() {}
}
