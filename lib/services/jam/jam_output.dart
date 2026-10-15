import 'dart:async';

import '../../core/app_log.dart';
import '../audio/audio_backend.dart';
import 'jam_models.dart';

/// Where to read an item from.
class JamSource {
  const JamSource.local(this.path)
      : uri = null,
        headers = const {};
  const JamSource.remote(this.uri, this.headers) : path = null;

  final String? path;
  final Uri? uri;
  final Map<String, String> headers;
}

typedef JamSourceResolver = Future<JamSource?> Function(JamItem item);

const jamDriftTolerance = Duration(milliseconds: 1500);

/// Plays the shared state on this device when it is the output device.
/// Applies `playing`/`position` with a drift tolerance (no sync promised).
class JamOutput {
  JamOutput({
    required this.deviceId,
    required this.backend,
    required this.resolve,
    this.onTrackEnded,
    this.onItemFailed,
    this.tolerance = jamDriftTolerance,
    int Function()? nowMs,
  }) : _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch) {
    _subs
      ..add(backend.position.listen((p) => _position = p))
      ..add(backend.state.listen(_onBackend));
  }

  final String deviceId;
  final AudioBackend backend;
  final JamSourceResolver resolve;
  final Duration tolerance;
  final int Function() _nowMs;

  /// The current item finished by itself (reported to the host).
  void Function(int itemId)? onTrackEnded;

  /// The current item cannot be played (owner unreachable, bad file).
  void Function(int itemId)? onItemFailed;

  final _subs = <StreamSubscription<Object?>>[];
  Duration _position = Duration.zero;
  int? _loadedId;
  bool _backendPlaying = false;
  double _volume = -1;
  Future<void> _chain = Future.value();
  bool _disposed = false;

  bool get isOutput => _loadedId != null;
  int? get loadedItemId => _loadedId;

  void _onBackend(BackendState s) {
    _backendPlaying = s == BackendState.playing;
    if (s == BackendState.completed && _loadedId != null) {
      final id = _loadedId!;
      _loadedId = null; // report once
      onTrackEnded?.call(id);
    }
  }

  /// Applies [s]; calls are serialised and the latest state wins.
  Future<void> apply(JamState s) {
    _chain = _chain.then((_) => _apply(s)).catchError((Object e, StackTrace st) {
      AppLog.w('jam output: apply failed', e, st);
    });
    return _chain;
  }

  Future<void> _apply(JamState s) async {
    if (_disposed) return;
    final item = s.current;
    final mine = s.outputDeviceId == deviceId && !s.ended;
    if (!mine || item == null) {
      if (_loadedId != null || _backendPlaying) {
        _loadedId = null;
        await backend.stop();
      }
      return;
    }
    if (s.volume != _volume) {
      _volume = s.volume;
      await backend.setVolume(s.volume);
    }
    final target = Duration(milliseconds: s.positionAtTime(_nowMs()));
    if (_loadedId != item.id) {
      final src = await resolve(item);
      if (src == null) {
        onItemFailed?.call(item.id);
        return;
      }
      try {
        if (src.path != null) {
          await backend.load(src.path!);
        } else {
          await backend.loadUri(src.uri!, headers: src.headers);
        }
      } on BackendException catch (e) {
        AppLog.w('jam output: ${e.message}');
        onItemFailed?.call(item.id);
        return;
      }
      _loadedId = item.id;
      _position = Duration.zero;
      if (target > Duration.zero) await backend.seek(target);
    } else {
      final drift = (target - _position).abs();
      // While playing the position moves by itself: only correct big jumps.
      if (drift > tolerance) await backend.seek(target);
    }
    if (s.playing && !_backendPlaying) {
      await backend.play();
    } else if (!s.playing && _backendPlaying) {
      await backend.pause();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final s in _subs) {
      await s.cancel();
    }
    await backend.dispose();
  }
}
