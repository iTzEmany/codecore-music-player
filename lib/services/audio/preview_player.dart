import 'dart:async';

import '../../core/app_log.dart';
import '../../data/db/app_database.dart';
import 'audio_backend.dart';

/// What the preview is doing right now.
class PreviewState {
  const PreviewState({this.trackId, this.startedAt});

  /// The track being previewed; null when nothing is.
  final int? trackId;
  final DateTime? startedAt;

  bool get active => trackId != null;
}

/// A short listen to a track (a third of the way in) on its own player, so the
/// main queue and play counts are never touched. A new preview closes the
/// previous one; it ends by itself after [length].
class PreviewPlayer {
  PreviewPlayer(
    this._factory, {
    this.length = const Duration(seconds: 20),
    this.fade = const Duration(milliseconds: 300),
    this.step = const Duration(milliseconds: 50),
  });

  final AudioBackend Function() _factory;
  final Duration length, fade, step;

  Timer? _timer;
  Completer<void>? _sleeping;

  /// A wait that [_release] can cut short (no timer is left running).
  Future<void> _wait(Duration d) {
    final done = _sleeping = Completer<void>();
    _timer = Timer(d, () {
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  final _changes = StreamController<PreviewState>.broadcast();
  Stream<PreviewState> get changes => _changes.stream;

  AudioBackend? _backend;
  StreamSubscription<BackendState>? _sub;
  int _token = 0;
  PreviewState _state = const PreviewState();

  PreviewState get state => _state;

  void _emit(PreviewState s) {
    _state = s;
    if (!_changes.isClosed) _changes.add(s);
  }

  /// Starts previewing [t]; returns once the sound is on its way.
  Future<void> start(Track t) async {
    await _release(); // silently: a replacement is not an ending
    final token = ++_token;
    final backend = _factory();
    _backend = backend;
    try {
      await backend.load(t.path);
      if (token != _token) return;
      await backend.setVolume(0);
      if (t.durationMs > 0) {
        await backend.seek(Duration(milliseconds: t.durationMs ~/ 3));
      }
      _sub = backend.state.listen((s) {
        if (s == BackendState.completed) unawaited(_finish(token));
      });
      await backend.play();
      if (token != _token) return;
      _emit(PreviewState(trackId: t.id, startedAt: DateTime.now()));
      unawaited(_run(token, backend));
    } on BackendException catch (e) {
      AppLog.w('preview failed: ${e.message}');
      if (token == _token) await _finish(token);
    }
  }

  Future<void> _run(int token, AudioBackend backend) async {
    await _ramp(backend, 0, 1, token);
    final rest = length - fade * 2;
    if (rest > Duration.zero) await _wait(rest);
    if (token != _token) return;
    await _ramp(backend, 1, 0, token);
    await _finish(token);
  }

  /// Linear volume ramp; stops early if the preview was replaced or stopped.
  Future<void> _ramp(AudioBackend b, double from, double to, int token) async {
    final steps = (fade.inMilliseconds / step.inMilliseconds).ceil();
    for (var i = 1; i <= steps; i++) {
      if (token != _token) return;
      await b.setVolume(from + (to - from) * i / steps);
      await _wait(step);
    }
  }

  /// Ends the preview now (button released, Esc, another click).
  Future<void> stop() async {
    final backend = _backend;
    final token = _token;
    if (backend == null) return;
    await backend.setVolume(0);
    await _finish(token);
  }

  Future<void> _finish(int token) async {
    if (token != _token) return;
    await _release();
    _emit(const PreviewState());
  }

  /// Tears the current player down without announcing anything.
  Future<void> _release() async {
    _token++;
    _timer?.cancel();
    _timer = null;
    final sleeping = _sleeping;
    if (sleeping != null && !sleeping.isCompleted) sleeping.complete();
    final backend = _backend;
    _backend = null;
    await _sub?.cancel();
    _sub = null;
    if (backend != null) {
      try {
        await backend.stop();
        await backend.dispose();
      } on Object catch (e, st) {
        AppLog.w('preview player cleanup failed', e, st);
      }
    }
  }

  Future<void> dispose() async {
    await _release();
    await _changes.close();
  }
}
