import '../../data/db/app_database.dart';
import '../../data/repositories/track_repository.dart';
import 'audio_backend.dart';
import 'play_queue.dart';
import 'resume_point.dart';

/// Keeps the backend's «next track» in step with the queue: the queue decides
/// (`peekNext`), the backend only holds what it is told. Asked again after any
/// change of the queue, it does nothing when nothing changed.
class NextWindow {
  NextWindow(this._queue, this._tracks, this._backend);

  final PlayQueue _queue;
  final TrackRepository _tracks;
  final GaplessCapable _backend;

  Track? _track;
  int _token = 0;
  int? _forCurrent;
  int _forRevision = -1;
  bool _forEnabled = false;

  /// The track the backend was told to play next, if any.
  Track? get track => _track;

  /// Returns the prepared track and forgets it (the backend has moved on).
  Track? consume() {
    final t = _track;
    clear();
    return t;
  }

  /// Forces the next [refresh] to tell the backend again (the way tracks are
  /// joined changed, not the queue).
  void invalidate() => _forRevision = -1;

  void clear() {
    _token++;
    _track = null;
    _forCurrent = null;
    _forRevision = -1;
  }

  /// Prepares what follows [current]. With [enabled] false nothing follows.
  /// [volumeFor] and [overlap] give the volume of the next track and whether
  /// the two may play over each other (a crossfade).
  Future<void> refresh(
    Track current, {
    required bool enabled,
    required double Function(Track next) volumeFor,
    required bool Function(Track current, Track next) overlap,
  }) async {
    if (_forCurrent == current.id &&
        _forRevision == _queue.revision &&
        _forEnabled == enabled) {
      return;
    }
    if (!enabled && _track == null) {
      // Normal mode never touches the backend's window.
      _remember(current, enabled);
      return;
    }
    final token = ++_token;
    final id = enabled ? _queue.peekNext() : null;
    final revision = _queue.revision;
    Track? next;
    if (id != null) {
      next = id == current.id ? current : await _tracks.getById(id);
      if (token != _token) return;
    }
    // A track with a saved place must start there: that is a normal load.
    if (next != null && resumeStartFor(next.resumePositionMs) != null) {
      next = null;
    }
    _track = next;
    _forCurrent = current.id;
    _forRevision = revision;
    _forEnabled = enabled;
    await _backend.setNext(
      next?.path,
      volume: next == null ? 1.0 : volumeFor(next),
      overlap: next != null && overlap(current, next),
    );
  }

  void _remember(Track current, bool enabled) {
    _forCurrent = current.id;
    _forRevision = _queue.revision;
    _forEnabled = enabled;
  }
}
