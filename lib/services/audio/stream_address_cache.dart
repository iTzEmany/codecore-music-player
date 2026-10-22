import 'dart:async';
import 'dart:collection';

import '../../core/app_log.dart';
import '../online/youtube_service.dart';

/// When a stream address stops working: the `expire` query parameter (Unix
/// seconds). Null when absent, which means «renew right away».
DateTime? expiryOf(Uri uri) {
  final raw = uri.queryParameters['expire'];
  final secs = raw == null ? null : int.tryParse(raw);
  if (secs == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(secs * 1000, isUtc: true);
}

/// Direct stream addresses (slow to get: seconds of yt-dlp), kept while they
/// are far from expiring, one request at a time per track.
class StreamAddressCache {
  StreamAddressCache(
    this._resolve, {
    FastClientGate? gate,
    DateTime Function()? now,
    this.margin = const Duration(minutes: 10),
    this.wait = const Duration(seconds: 15),
    this.maxEntries = 20,
  })  : gate = gate ?? FastClientGate(),
        _now = now ?? DateTime.now;

  /// [fast] says whether the quick client may be used for this request.
  final Future<StreamAddress> Function(YtResult, {required bool fast}) _resolve;

  /// Session switch of the quick client (see [invalidate]).
  final FastClientGate gate;

  // Tracks whose quick address was refused: the default clients from now on.
  final Set<String> _defaultOnly = {};
  final DateTime Function() _now;

  /// An address is reused while more than this is left before it expires.
  final Duration margin;

  /// How long [address] waits for the answer before giving up.
  final Duration wait;
  final int maxEntries;

  // Insertion order = age; the oldest goes first past [maxEntries].
  final LinkedHashMap<String, StreamAddress> _done = LinkedHashMap();
  final Map<String, Future<StreamAddress>> _pending = {};

  bool _fresh(StreamAddress a) {
    final expiry = expiryOf(a.uri);
    return expiry != null && expiry.difference(_now()) > margin;
  }

  /// The address for [r]: cached, or the one request already running, or a new
  /// one. Errors of the resolver reach every caller waiting; a timeout throws
  /// [TimeoutException] (the request itself goes on and fills the cache).
  Future<StreamAddress> address(YtResult r) {
    final key = r.indexKey;
    final cached = _done[key];
    if (cached != null && _fresh(cached)) return Future.value(cached);
    final request = _pending[key] ?? _start(r, key);
    return request.timeout(wait);
  }

  Future<StreamAddress> _start(YtResult r, String key) {
    final fast = gate.enabled && !_defaultOnly.contains(key);
    final f = _resolve(r, fast: fast).then((a) {
      _done
        ..remove(key)
        ..[key] = a;
      while (_done.length > maxEntries) {
        _done.remove(_done.keys.first);
      }
      return a;
    });
    _pending[key] = f;
    // Clear on both outcomes; the error still reaches whoever awaits [f].
    // Block bodies: returning the removed future would make this chain fail.
    f.then<void>((_) {
      _pending.remove(key);
    }, onError: (_) {
      _pending.remove(key);
    });
    return f;
  }

  /// Asks for the address ahead of time, without waiting; errors only logged.
  void prefetch(YtResult r) {
    final cached = _done[r.indexKey];
    if (cached != null && _fresh(cached)) return;
    final f = _pending[r.indexKey] ?? _start(r, r.indexKey);
    f.then<void>(
      (_) {},
      onError: (Object e, StackTrace st) {
        AppLog.w('Stream address prefetch failed for ${r.id}', e, st);
      },
    );
  }

  /// Forgets the address of [r] (it answered 403): the next [address] asks
  /// again. If the refused address came from the quick client, this track
  /// moves to the default clients and the session counts a failure (the
  /// quick client is dropped altogether after [FastClientGate.limit]).
  void invalidate(YtResult r) {
    final old = _done.remove(r.indexKey);
    if (old != null && old.fast) {
      _defaultOnly.add(r.indexKey);
      gate.failed();
      AppLog.w('quick-client address of ${r.id} refused '
          '(${gate.failures}/${gate.limit} this session)');
    }
  }
}
