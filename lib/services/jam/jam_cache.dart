import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import 'jam_models.dart';
import 'jam_output.dart';

/// Temporary storage for the tracks about to play, so a missing owner does
/// not stop the music. Wiped at the end of the Jam and on start-up.
class JamCache {
  JamCache(this.dir, {Dio? dio, this.maxBytes = 300 * 1024 * 1024})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));

  final Directory dir;
  final int maxBytes;
  final Dio _dio;
  final _inFlight = <int, Future<File?>>{};
  final _cancels = <int, CancelToken>{};

  File _file(JamItem i) => File(p.join(dir.path, '${i.id}.${i.ext}'));

  /// The cached copy of [item], if complete.
  File? cached(JamItem item) {
    final f = _file(item);
    return f.existsSync() ? f : null;
  }

  /// Downloads [item] unless it is already cached or too big. Never throws.
  Future<File?> fetch(JamItem item, Uri uri, Map<String, String> headers) {
    final hit = cached(item);
    if (hit != null) return Future.value(hit);
    if (item.sizeBytes > maxBytes) return Future.value(null);
    return _inFlight[item.id] ??= _download(item, uri, headers).whenComplete(() {
      _inFlight.remove(item.id);
      _cancels.remove(item.id);
    });
  }

  Future<File?> _download(JamItem item, Uri uri, Map<String, String> h) async {
    final target = _file(item);
    final part = File('${target.path}.part');
    final cancel = _cancels[item.id] = CancelToken();
    try {
      await dir.create(recursive: true);
      await _dio.download(uri.toString(), part.path,
          options: Options(headers: h, receiveTimeout: const Duration(minutes: 5)),
          cancelToken: cancel);
      if (await part.length() > maxBytes) {
        await part.delete();
        return null;
      }
      await part.rename(target.path);
      return target;
    } on DioException catch (e) {
      AppLog.w('jam cache: ${item.title} failed', e);
      if (await part.exists()) await part.delete();
      return null;
    } on FileSystemException catch (e) {
      AppLog.w('jam cache: io error', e);
      return null;
    }
  }

  /// Source for [item]: the cached copy when there is one, else [remote].
  JamSource? sourceFor(JamItem item, JamSource? remote) {
    final f = cached(item);
    return f != null ? JamSource.local(f.path) : remote;
  }

  /// Keeps only files of [keepIds]; aborts downloads that are not wanted.
  Future<void> prune(Set<int> keepIds) async {
    for (final e in _cancels.entries.toList()) {
      if (!keepIds.contains(e.key)) e.value.cancel();
    }
    if (!await dir.exists()) return;
    await for (final f in dir.list()) {
      if (f is! File) continue;
      final id = int.tryParse(p.basename(f.path).split('.').first);
      if (id == null || !keepIds.contains(id)) {
        try {
          await f.delete();
        } on FileSystemException {
          // best effort
        }
      }
    }
  }

  /// End of the Jam (or start-up): remove everything.
  Future<void> clear() async {
    for (final c in _cancels.values) {
      c.cancel();
    }
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException catch (e) {
        AppLog.w('jam cache: clear failed', e);
      }
    }
  }
}
