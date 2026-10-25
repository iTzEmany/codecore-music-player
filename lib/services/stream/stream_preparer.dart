import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import '../../data/repositories/track_repository.dart';
import '../online/youtube_service.dart';
import 'stream_cache.dart';
import 'stream_key.dart';

enum StreamPhase { queued, downloading, ready, failed }

/// A queue entry that can be streamed: its cache key and what to download.
class StreamItem {
  const StreamItem(this.key, this.result);
  final String key;
  final YtResult result;
}

/// Looks up tags, lyrics and cover for a streamed track. Starts together with
/// the download; [rowId] completes with the shadow row id once the file is
/// cached (or with an error if it never is).
typedef StreamEnricher = Future<void> Function(YtResult r, Future<int> rowId);

class _Job {
  _Job(this.key, this.result) {
    done.future.ignore(); // the error reaches ready() callers only
    rowId.future.ignore();
  }
  final String key;
  final YtResult result;
  final done = Completer<File>();
  final rowId = Completer<int>();
  var phase = StreamPhase.queued;

  /// A `ready()` caller waits for it: runs first, even out of the queue window.
  var requested = false;
  var enriching = false;
}

/// Downloads the queue's online tracks into the [StreamCache] ahead of the
/// player (at most [maxParallel] at once, queue order, one per key).
/// The handler calls [setQueue] before [ready] (45.4).
class StreamPreparer {
  StreamPreparer({
    required this.cache,
    required this.tracks,
    required this.youtube,
    required this.isMetered,
    this.enrich,
    this.maxParallel = 2,
    this.meteredAhead = 3,
    this.cooldown = const Duration(minutes: 5),
    this.attemptTimeout = const Duration(minutes: 5),
  });

  final StreamCache cache;
  final TrackRepository tracks;
  final YoutubeService youtube;
  final Future<bool> Function() isMetered;
  final StreamEnricher? enrich;
  final int maxParallel, meteredAhead;

  /// Pause of the prefetch after a 403/429 (like Shuffle+'s source cooldown).
  final Duration cooldown;

  /// Longest a single download attempt may take.
  final Duration attemptTimeout;

  /// Phase per key, updated only when it changes (never the byte count).
  final phases = ValueNotifier<Map<String, StreamPhase>>({});

  var _queue = <StreamItem>[];
  final _jobs = <String, _Job>{};
  final _pinned = <String>{};
  final _cancel = CancelToken();
  var _active = 0;
  var _pumping = false, _again = false, _disposed = false;
  Timer? _resume;
  DateTime? _pausedUntil;

  /// Keys of the entries given to the last [setQueue].
  Set<String> get queuedKeys => {for (final i in _queue) i.key};

  /// The upcoming online entries, current first. Pins current + next 2.
  void setQueue(List<StreamItem> items) {
    if (_disposed) return;
    if (items.isEmpty && _queue.isEmpty) return;
    _queue = List.of(items);
    final want = {for (final i in items.take(3)) i.key};
    for (final k in _pinned.difference(want)) {
      cache.unpin(k);
    }
    for (final k in want.difference(_pinned)) {
      cache.pin(k);
    }
    _pinned
      ..clear()
      ..addAll(want);
    // Forget what nobody waits for any more.
    final inQueue = {for (final i in items) i.key};
    _jobs.removeWhere((k, j) =>
        !inQueue.contains(k) && !j.requested && j.phase != StreamPhase.downloading);
    final keep = {...inQueue, ..._jobs.keys};
    if (phases.value.keys.any((k) => !keep.contains(k))) {
      phases.value = {
        for (final e in phases.value.entries)
          if (keep.contains(e.key)) e.key: e.value,
      };
    }
    _pump();
  }

  /// The cached file of [key], downloading it first (ahead of the queue) when
  /// needed. Errors after the second failed attempt. The key is pinned until
  /// the file is handed back; from then on the queue window pins it.
  Future<File> ready(String key, YtResult r) async {
    if (_disposed) throw StateError('disposed');
    cache.pin(key);
    try {
      final file = await cache.fileFor(key);
      if (file != null) {
        await cache.touch(key);
        // A file cached by an earlier session may have lost its row: plays need it.
        if (await tracks.streamRow(key) == null) await tracks.upsertStreamRow(key, r, file);
        _setPhase(key, StreamPhase.ready);
        return file;
      }
      if (_disposed) throw StateError('disposed');
      var job = _jobs[key];
      if (job == null || job.phase == StreamPhase.failed) {
        job = _jobs[key] = _Job(key, r);
      }
      job.requested = true;
      _pump();
      return await job.done.future;
    } finally {
      cache.unpin(key);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _resume?.cancel();
    _cancel.cancel('disposed');
    for (final j in _jobs.values) {
      _fail(j, StateError('disposed'));
    }
    _pinned.forEach(cache.unpin);
    _pinned.clear();
    phases.dispose();
  }

  void _setPhase(String key, StreamPhase ph) {
    if (!_disposed && phases.value[key] != ph) phases.value = {...phases.value, key: ph};
  }

  void _fail(_Job j, Object error) {
    j.phase = StreamPhase.failed;
    _setPhase(j.key, StreamPhase.failed);
    if (!j.rowId.isCompleted) j.rowId.completeError(error);
    if (!j.done.isCompleted) j.done.completeError(error);
  }

  void _pump() {
    if (_pumping) {
      _again = true;
      return;
    }
    _pumping = true;
    unawaited(() async {
      try {
        do {
          _again = false;
          await _fill();
        } while (_again && !_disposed);
      } on Object catch (e, st) {
        AppLog.w('stream preparer: scheduling failed', e, st);
        for (final j in _jobs.values.toList()) {
          if (j.requested && j.phase == StreamPhase.queued) _fail(j, e);
        }
      } finally {
        _pumping = false;
      }
    }());
  }

  Future<void> _fill() async {
    if (_disposed) return;
    // Requested jobs first, whatever the network or the pause.
    // Queue order: the current track first, keys outside the queue last.
    int rank(_Job j) {
      final i = _queue.indexWhere((q) => q.key == j.key);
      return i < 0 ? _queue.length : i;
    }
    final requested = _jobs.values.where((j) => j.requested && j.phase == StreamPhase.queued).toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
    for (final j in requested) {
      if (_active >= maxParallel) return;
      _start(j);
    }
    if (_pausedUntil?.isAfter(DateTime.now()) ?? false) return;
    var metered = false;
    try {
      metered = await isMetered();
    } on Object catch (e, st) {
      AppLog.w('stream preparer: network kind unavailable', e, st);
    }
    for (final i in _queue.take(metered ? meteredAhead : _queue.length)) {
      if (_active >= maxParallel || _disposed) return;
      // shortcut: a key marked ready is trusted; if evicted, ready() re-downloads it.
      if (_jobs.containsKey(i.key) || phases.value[i.key] == StreamPhase.ready) continue;
      var cached = false;
      try {
        cached = await cache.fileFor(i.key) != null;
      } on Object catch (e, st) {
        AppLog.w('stream preparer: cache lookup failed', e, st);
      }
      if (_jobs.containsKey(i.key) || _active >= maxParallel || _disposed) continue; // changed meanwhile
      if (cached) {
        _setPhase(i.key, StreamPhase.ready);
      } else {
        _start(_jobs[i.key] = _Job(i.key, i.result));
      }
    }
  }

  void _start(_Job j) {
    _active++;
    j.phase = StreamPhase.downloading;
    _setPhase(j.key, StreamPhase.downloading);
    unawaited(_run(j));
  }

  static bool _isRateLimited(Object e) =>
      e is YtException &&
      (e.kind == YtErrorKind.rateLimited ||
          (e.detail ?? '').toLowerCase().contains('http error 403'));

  Future<void> _run(_Job j) async {
    if (enrich != null && !j.enriching) {
      j.enriching = true;
      unawaited(enrich!(j.result, j.rowId.future).catchError((Object e, StackTrace st) {
        AppLog.w('stream enrichment failed for ${j.key}', e, st);
      }));
    }
    File? part;
    Object? error;
    for (var attempt = 1; attempt <= 2 && part == null && !_disposed; attempt++) {
      try {
        part = await _download(j);
      } on Object catch (e, st) {
        AppLog.w('stream download of ${j.key} ($attempt)', e, st);
        error = e;
        if (_isRateLimited(e)) {
          _pausedUntil = DateTime.now().add(cooldown);
          _resume?.cancel();
          _resume = Timer(cooldown, _pump);
          if (!j.requested) {
            // Prefetch only: forget it, the queue walk picks it up after the pause.
            _jobs.remove(j.key);
            if (!_disposed) phases.value = {...phases.value}..remove(j.key);
            return _finish();
          }
        }
      }
    }
    if (_disposed) error = StateError('disposed');
    if (part != null && !_disposed) {
      try {
        final file = await cache.put(j.key, part);
        j.rowId.complete(await tracks.upsertStreamRow(j.key, j.result, file));
        _jobs.remove(j.key);
        _setPhase(j.key, StreamPhase.ready);
        j.done.complete(file);
        return _finish();
      } on Object catch (e, st) {
        AppLog.w('stream cache/row of ${j.key}', e, st);
        error = e;
      }
    }
    _fail(j, error ?? StateError('no download'));
    _finish();
  }

  void _finish() {
    _active--;
    if (!_disposed) _pump();
  }

  /// Downloads into a temp folder inside the cache and returns the file as
  /// `<key>.<ext>.part`, the shape [StreamCache.put] takes.
  Future<File> _download(_Job j) async {
    final name = streamFileName(j.key);
    final tmp = Directory(p.join(cache.dir.path, '.dl-$name'));
    try {
      String? path;
      // One attempt that hangs counts as a failed attempt.
      path = await (() async {
        String? found;
        await for (final e in youtube.download(j.result, tmp, cancel: _cancel)) {
          found = e.path ?? found;
        }
        return found;
      })().timeout(attemptTimeout);
      if (path == null) throw StateError('download ended without a file');
      return await File(path).rename(p.join(cache.dir.path, '$name${p.extension(path)}.part'));
    } finally {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    }
  }
}
