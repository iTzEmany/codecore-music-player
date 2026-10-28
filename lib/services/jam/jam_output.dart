import 'dart:async';

import '../../core/app_log.dart';
import '../audio/audio_backend.dart';
import 'jam_clock.dart';
import 'jam_models.dart';
import 'jam_sync.dart';

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

/// Single output: re-seek when the position is this far off (clock skew is
/// seconds; start latency and position jitter are not worth a jump).
const jamSingleOutputReseek = Duration(milliseconds: 500);

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
    this.clock,
    this.latencyMs = 0,
    this.syncController = const JamSyncController(),
    this.syncInterval = const Duration(milliseconds: 500),
  }) : _nowMs = nowMs ??
           (clock != null
               ? clock.jamNowMs // the shared position is in the host's clock
               : () => DateTime.now().millisecondsSinceEpoch) {
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

  /// Reference clock for synchronised playback; without it a Jam with several
  /// outputs falls back to the single-output behaviour.
  final JamClock? clock;

  /// Extra output latency of this device (Bluetooth...), ms.
  int latencyMs;

  final JamSyncController syncController;
  final Duration syncInterval;

  /// Latest measured error while synchronised (ms, + = ahead), for the UI.
  void Function(int errorMs)? onSyncError;

  JamState? _state;
  Timer? _syncTimer, _startTimer;
  double _speed = 1.0;

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
    final mine = s.outputs.contains(deviceId) && !s.ended;
    _state = s;
    if (!mine || item == null) {
      _stopSync();
      if (_loadedId != null || _backendPlaying) {
        _loadedId = null;
        await backend.stop();
      }
      return;
    }
    final syncMode = s.synced && clock != null;
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
      if (!syncMode && target > Duration.zero) await backend.seek(target);
    } else if (!syncMode) {
      final drift = (target - _position).abs();
      // While playing the position moves by itself: only correct big jumps.
      if (drift > tolerance) await backend.seek(target);
    }
    if (syncMode) {
      _syncTimer ??= Timer.periodic(syncInterval, (_) => unawaited(_tick()));
      await _tick();
      return;
    }
    // Single output: no follower, but keep a light watch so that a pause the
    // OS imposed (audio focus lost to a notification) does not outlive the
    // shared "playing" state.
    _startTimer?.cancel();
    _startTimer = null;
    if (_speed != 1.0) {
      _speed = 1.0;
      unawaited(backend.setSpeed(1.0));
    }
    _syncTimer ??= Timer.periodic(syncInterval * 4, (_) => unawaited(_tick()));
    if (s.playing && !_backendPlaying) {
      await backend.play();
    } else if (!s.playing && _backendPlaying) {
      await backend.pause();
    }
  }

  void _stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _startTimer?.cancel();
    _startTimer = null;
    if (_speed != 1.0) {
      _speed = 1.0;
      unawaited(backend.setSpeed(1.0));
    }
  }

  bool _ticking = false;

  /// One step of the synchronised follower (also runs every [syncInterval]).
  Future<void> _tick() async {
    final s = _state, c = clock;
    if (_disposed || _ticking || s == null || _loadedId == null) return;
    if (c == null || !s.synced) {
      // single output: only resume what the OS paused behind our back
      if (s.playing && !_backendPlaying && s.outputs.contains(deviceId)) {
        await backend.play();
      }
      // The Jam clock settles after the first state: re-check the position.
      // Not in the first second after the (re)start: the player is still
      // starting up.
      final since = _nowMs() - s.positionAt;
      if (c != null && s.playing && _backendPlaying && since > 1000) {
        final target = s.positionAtTime(_nowMs());
        final drift = backend.positionNow.inMilliseconds - target;
        if (drift.abs() > jamSingleOutputReseek.inMilliseconds) {
          AppLog.d('jam sync: single output drift ${drift}ms, seek to $target');
          await backend.seek(Duration(milliseconds: target));
        }
      }
      return;
    }
    _ticking = true;
    try {
      final measured = backend.positionNow.inMilliseconds;
      final a = syncController.decide(
        playing: s.playing,
        positionMs: s.positionMs,
        positionAtMs: s.positionAt,
        jamNowMs: c.jamNowMs(),
        measuredMs: measured,
        backendPlaying: _backendPlaying,
        speed: _speed,
        latencyMs: latencyMs,
      );
      if (s.playing && c.jamNowMs() >= s.positionAt) {
        final expected =
            s.positionMs + (c.jamNowMs() - s.positionAt) + latencyMs;
        onSyncError?.call(measured - expected);
      }
      if (!a.isNoop) {
        AppLog.d(
          'jam sync: measured ${measured}ms, offset ${c.offsetMs}ms, '
          'lat ${latencyMs}ms -> $a',
        );
      }
      if (a.seekToMs != null) {
        await backend.seek(Duration(milliseconds: a.seekToMs! < 0 ? 0 : a.seekToMs!));
      }
      if (a.speed != null && a.speed != _speed) {
        _speed = a.speed!;
        await backend.setSpeed(_speed);
      }
      if (a.play == true) {
        _startTimer?.cancel();
        await backend.play();
      } else if (a.play == false) {
        _startTimer?.cancel();
        await backend.pause();
      }
      final wait = a.playInMs;
      if (wait != null && wait > 0) {
        // Start exactly at the scheduled instant instead of on the next tick.
        _startTimer?.cancel();
        _startTimer = Timer(Duration(milliseconds: wait), () {
          _startTimer = null;
          unawaited(_tick());
        });
      }
    } finally {
      _ticking = false;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _syncTimer?.cancel();
    _startTimer?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    await backend.dispose();
  }
}
