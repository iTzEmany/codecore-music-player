import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import '../online/youtube_service.dart';
import '../stream/stream_cache.dart';
import '../stream/stream_key.dart' show displayArtist;
import 'jam_models.dart';

/// Queues online tracks into the Jam from this device: each one downloads into
/// our cache (in parallel), but the `add` commands go out in the order of the
/// calls (D-80), and only once the file is ready. Never throws.
class JamOnlineAdder {
  JamOnlineAdder({
    required this.ownId,
    required this.cache,
    required this.ready,
    required this.send,
    required this.onFailed,
  });

  final String ownId;
  final StreamCache cache;

  /// The preparer's `ready`: the cached file, downloading it if needed.
  final Future<File> Function(String key, YtResult r) ready;
  final Future<JamError?> Function(JamCommand) send;
  final void Function(YtResult r) onFailed;

  var _tail = Future<void>.value();
  final _pinned = <String>{}; // held from the call until the item shows in the queue
  var _disposed = false;

  /// Accepts [r] at once; the item appears when its file is ready.
  void add(YtResult r) {
    final key = r.indexKey;
    cache.pin(key);
    _pinned.add(key);
    final file = ready(key, r).then<File?>((f) => f, onError: (Object e, StackTrace st) {
      AppLog.w('jam: download of $key failed', e, st);
      return null;
    });
    _tail = _tail.then((_) async {
      final f = await file;
      final ext = f == null ? '' : p.extension(f.path).replaceFirst('.', '').toLowerCase();
      final err = f == null || _disposed || !jamExts.contains(ext)
          ? JamError.invalid
          : await send(JamCommand.add(JamItem(
              id: 0,
              ownerDeviceId: ownId,
              title: r.title,
              artist: displayArtist(r),
              album: r.album,
              durationMs: r.duration?.inMilliseconds ?? 0,
              ext: ext,
              sizeBytes: await f.length(),
              ref: 'yt:$key',
              videoId: r.id,
            )));
      if (err != null) {
        _release(key);
        if (!_disposed) onFailed(r);
      }
    });
  }

  /// Keys now in the shared queue: the Jam's own pins hold them from here on.
  void seen(Set<String> queued) => _pinned.intersection(queued).toList().forEach(_release);

  void dispose() {
    _disposed = true;
    _pinned.toList().forEach(_release);
  }

  void _release(String key) {
    if (_pinned.remove(key)) cache.unpin(key);
  }
}
