import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/app_log.dart';
import 'youtube_service.dart';

enum DownloadStatus { queued, downloading, done, failed, cancelled }

class DownloadItem {
  const DownloadItem({
    required this.id,
    required this.result,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.error,
    this.path,
    this.tag,
  });

  final int id;
  final YtResult result;
  final DownloadStatus status;
  final double progress;
  final YtErrorKind? error;
  final String? path;

  /// Opaque label from whoever queued it (e.g. `import:<id>:<row>`).
  final String? tag;

  DownloadItem copyWith(
          {DownloadStatus? status,
          double? progress,
          YtErrorKind? error,
          String? path}) =>
      DownloadItem(
        id: id,
        result: result,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        error: error ?? this.error,
        path: path ?? this.path,
        tag: tag,
      );
}

typedef Downloader = Stream<DownloadProgress> Function(
    YtResult result, Directory outDir, CancelToken cancel);

/// Sequential queue: one download at a time.
class DownloadQueue {
  DownloadQueue({
    required this.downloader,
    required this.outDir,
    required this.onChanged,
    this.onDownloaded,
    this.onSettled,
    this.uiInterval = const Duration(milliseconds: 200),
  });

  final Downloader downloader;
  final Future<Directory?> Function() outDir;
  final void Function(List<DownloadItem> items) onChanged;
  final Future<void> Function(String path)? onDownloaded;

  /// Called once per item when it reaches done, failed or cancelled
  /// (after [onDownloaded] for the done ones).
  final void Function(DownloadItem item)? onSettled;
  final Duration uiInterval;

  final List<DownloadItem> _items = [];
  final Map<int, CancelToken> _tokens = {};
  int _nextId = 1;
  bool _running = false;
  bool _disposed = false;

  List<DownloadItem> get items => List.unmodifiable(_items);

  void add(YtResult r, {String? tag}) {
    _items.add(DownloadItem(id: _nextId++, result: r, tag: tag));
    _emit();
    unawaited(_pump());
  }

  void cancel(int id) {
    _tokens[id]?.cancel();
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0 && _items[i].status == DownloadStatus.queued) {
      _items[i] = _items[i].copyWith(status: DownloadStatus.cancelled);
      _emit();
      _settle(id);
    }
  }

  /// Cancels every queued or running item for which [test] is true.
  void cancelWhere(bool Function(DownloadItem item) test) {
    for (final e in List.of(_items)) {
      final live = e.status == DownloadStatus.queued ||
          e.status == DownloadStatus.downloading;
      if (live && test(e)) cancel(e.id);
    }
  }

  void clearFinished() {
    _items.removeWhere((e) =>
        e.status == DownloadStatus.done ||
        e.status == DownloadStatus.failed ||
        e.status == DownloadStatus.cancelled);
    _emit();
  }

  /// Cancels everything (app closing); `.part` files are removed by the downloader.
  void dispose() {
    _disposed = true;
    for (final t in _tokens.values) {
      t.cancel();
    }
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].status == DownloadStatus.queued) {
        _items[i] = _items[i].copyWith(status: DownloadStatus.cancelled);
      }
    }
  }

  void _emit() {
    if (!_disposed) onChanged(items);
  }

  void _settle(int id) {
    if (_disposed) return;
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0) onSettled?.call(_items[i]);
  }

  void _replace(int id, DownloadItem Function(DownloadItem) f) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0) _items[i] = f(_items[i]);
  }

  Future<void> _pump() async {
    if (_running) return;
    _running = true;
    try {
      while (!_disposed) {
        final next = _items
            .where((e) => e.status == DownloadStatus.queued)
            .cast<DownloadItem?>()
            .firstWhere((_) => true, orElse: () => null);
        if (next == null) break;
        await _runOne(next);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _runOne(DownloadItem item) async {
    final token = CancelToken();
    _tokens[item.id] = token;
    _replace(item.id, (e) => e.copyWith(status: DownloadStatus.downloading));
    _emit();
    try {
      final dir = await outDir();
      if (dir == null) {
        throw const YtException(YtErrorKind.changed, 'no output folder');
      }
      var lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
      String? path;
      await for (final p in downloader(item.result, dir, token)) {
        if (p.path != null) path = p.path;
        final now = DateTime.now();
        if (now.difference(lastEmit) >= uiInterval) {
          lastEmit = now;
          _replace(item.id, (e) => e.copyWith(progress: p.fraction));
          _emit();
        }
      }
      if (token.isCancelled || path == null) {
        _replace(item.id, (e) => e.copyWith(status: DownloadStatus.cancelled));
      } else {
        _replace(item.id,
            (e) => e.copyWith(status: DownloadStatus.done, progress: 1, path: path));
        await onDownloaded?.call(path);
      }
    } on YtException catch (e, st) {
      AppLog.w('download of ${item.result.id} failed (${e.kind})', e.detail, st);
      _replace(item.id,
          (x) => x.copyWith(status: DownloadStatus.failed, error: e.kind));
    } on Object catch (e, st) {
      AppLog.e('download failed', e, st);
      _replace(item.id,
          (x) => x.copyWith(status: DownloadStatus.failed, error: YtErrorKind.changed));
    } finally {
      _tokens.remove(item.id);
      _emit();
      _settle(item.id);
    }
  }
}
