import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/app_log.dart';
import 'youtube_service.dart';

/// Search results kept on disk so re-importing a playlist does not search
/// again. Entries expire after [ttl]; beyond [max] the least recently used go.
class SearchCache {
  SearchCache({
    required this.file,
    this.ttl = const Duration(days: 30),
    this.max = 2000,
    DateTime Function()? now,
    this.writeDelay = const Duration(seconds: 2),
  }) : _now = now ?? DateTime.now;

  /// Resolved lazily: the app folder is only known asynchronously.
  final Future<File> Function() file;
  final Duration ttl;
  final int max;
  final Duration writeDelay;
  final DateTime Function() _now;

  Map<String, _Entry>? _entries;
  Timer? _timer;

  Future<Map<String, _Entry>> _load() async {
    final cached = _entries;
    if (cached != null) return cached;
    final out = <String, _Entry>{};
    try {
      final f = await file();
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString());
        if (raw is Map) {
          for (final e in raw.entries) {
            final v = _Entry.fromJson(e.value);
            if (v != null) out['${e.key}'] = v;
          }
        }
      }
    } on Object catch (e, st) {
      AppLog.w('search cache unreadable, starting empty', e, st);
      out.clear();
    }
    return _entries ??= out;
  }

  Future<int> count() async => (await _load()).length;

  /// Fresh results for [key], or null. Counts as a use.
  Future<List<YtResult>?> get(String key) async {
    final m = await _load();
    final e = m[key];
    if (e == null) return null;
    final now = _now().millisecondsSinceEpoch;
    if (now - e.storedAt > ttl.inMilliseconds) {
      m.remove(key);
      _scheduleWrite();
      return null;
    }
    e.usedAt = now;
    _scheduleWrite();
    return e.results;
  }

  /// Empty result lists are not kept: «nothing found» may change.
  Future<void> put(String key, List<YtResult> results) async {
    if (results.isEmpty) return;
    final m = await _load();
    final now = _now().millisecondsSinceEpoch;
    m[key] = _Entry(now, now, results);
    if (m.length > max) {
      final byUse = m.entries.toList()
        ..sort((a, b) => a.value.usedAt.compareTo(b.value.usedAt));
      for (final e in byUse.take(m.length - max)) {
        m.remove(e.key);
      }
    }
    _scheduleWrite();
  }

  Future<void> removeWhere(bool Function(String key) test) async {
    final m = await _load();
    m.removeWhere((k, _) => test(k));
    _scheduleWrite();
  }

  Future<void> clear() async {
    (await _load()).clear();
    await flush();
  }

  void _scheduleWrite() {
    _timer?.cancel();
    _timer = Timer(writeDelay, () => unawaited(flush()));
  }

  /// Writes now (also called when the debounce fires).
  Future<void> flush() async {
    _timer?.cancel();
    final m = _entries;
    if (m == null) return;
    try {
      final f = await file();
      await f.parent.create(recursive: true);
      await f.writeAsString(
          jsonEncode({for (final e in m.entries) e.key: e.value.toJson()}));
    } on Object catch (e, st) {
      AppLog.w('search cache write failed', e, st);
    }
  }
}

class _Entry {
  _Entry(this.storedAt, this.usedAt, this.results);

  final int storedAt;
  int usedAt;
  final List<YtResult> results;

  Map<String, Object?> toJson() => {
        's': storedAt,
        'u': usedAt,
        'r': [for (final r in results) ytResultToJson(r)],
      };

  static _Entry? fromJson(Object? j) {
    if (j is! Map) return null;
    final s = j['s'], u = j['u'], r = j['r'];
    if (s is! int || u is! int || r is! List) return null;
    final results = <YtResult>[
      for (final x in r) ?ytResultFromJson(x),
    ];
    return _Entry(s, u, results);
  }
}

/// A result as the disk caches store it (short keys, defaults left out).
Map<String, Object?> ytResultToJson(YtResult r) => {
      'id': r.id,
      'title': r.title,
      'channel': r.channel,
      'ms': r.duration?.inMilliseconds,
      'thumb': r.thumbnailUrl,
      'artists': r.artists,
      'album': r.album,
      if (r.artistIds.any((i) => i.isNotEmpty)) 'aids': r.artistIds,
      if (r.albumId != null) 'alb': r.albumId,
      if (r.source != MediaSource.youtube) 'src': r.source.name,
      if (r.webpageUrl != null) 'url': r.webpageUrl,
    };

/// Inverse of [ytResultToJson]; null for an entry that is not a result.
YtResult? ytResultFromJson(Object? x) {
  if (x is! Map || x['id'] is! String || x['title'] is! String) return null;
  final ms = x['ms'];
  return YtResult(
    id: x['id'] as String,
    title: x['title'] as String,
    channel: '${x['channel'] ?? ''}',
    duration: ms is int ? Duration(milliseconds: ms) : null,
    thumbnailUrl: x['thumb'] as String?,
    artists: [
      for (final a in (x['artists'] is List ? x['artists'] as List : const [])) '$a',
    ],
    album: x['album'] as String?,
    artistIds: [
      for (final a in (x['aids'] is List ? x['aids'] as List : const [])) '$a',
    ],
    albumId: x['alb'] as String?,
    source: MediaSource.values.firstWhere(
      (m) => m.name == x['src'],
      orElse: () => MediaSource.youtube,
    ),
    webpageUrl: x['url'] as String?,
  );
}
