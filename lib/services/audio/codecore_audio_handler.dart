import 'dart:async';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';

import '../../core/app_log.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/track_repository.dart';
import 'audio_backend.dart';
import 'play_queue.dart';
import 'resume_point.dart';

enum PlaybackFailureReason { fileMissing, unplayable, notInLibrary }

class PlaybackFailure {
  const PlaybackFailure(this.title, this.reason);

  final String? title;
  final PlaybackFailureReason reason;
}

class CodecoreAudioHandler extends BaseAudioHandler with SeekHandler {
  CodecoreAudioHandler(
    this._backend,
    this._queue,
    this._tracks, {
    required this.onError,
    this.coverPathFor,
  }) {
    _subs
      ..add(_backend.state.listen(_onBackendState))
      ..add(_backend.position.listen(_onPosition))
      ..add(_backend.duration.listen((d) => _duration = d));
  }

  static const maxConsecutiveErrors = 3;

  final AudioBackend _backend;
  final PlayQueue _queue;
  final TrackRepository _tracks;
  final void Function(PlaybackFailure failure) onError;
  final String? Function(Track track)? coverPathFor;
  final List<StreamSubscription<Object?>> _subs = [];
  final _trackController = StreamController<Track?>.broadcast();
  final _queueController = StreamController<void>.broadcast();

  BackendState _state = BackendState.idle;
  Duration _position = Duration.zero;
  Duration? _duration;
  Track? _current;
  int _loadToken = 0;
  int _consecutiveErrors = 0;
  bool _playCounted = false;
  Duration _lastResumeSave = Duration.zero;
  bool _handlingCompleted = false;

  /// Sleep timer "end of track": the next track is loaded but not started.
  bool pauseAtTrackEnd = false;

  /// Playback speed, kept by the handler so every new track gets it again.
  static const minSpeed = 0.5, maxSpeed = 2.0;
  double _speed = 1.0;
  double get speed => _speed;

  double _baseVolume = 1.0;
  bool _normalize = false;
  double _gainFactor = 1.0;

  Track? get currentTrack => _current;
  Stream<Track?> get currentTrackStream => _trackController.stream;
  Stream<void> get queueChanges => _queueController.stream;
  Stream<Duration> get positionStream => _backend.position;
  Stream<Duration?> get durationStream => _backend.duration;
  BackendState get backendState => _state;
  bool get isPlaying => _state == BackendState.playing;
  List<int> get queueIds => _queue.items;
  int get currentIndex => _queue.currentIndex;
  bool get hasNext => _queue.hasNext;
  bool get shuffleEnabled => _queue.shuffle;
  PlayRepeat get repeatMode => _queue.repeat;

  Future<void> playQueue(List<int> ids, int index) async {
    _queue.setItems(ids, startIndex: index);
    _consecutiveErrors = 0;
    _queueController.add(null);
    await _loadCurrent(play: true);
  }

  /// Loads the queue paused, at [position] (used to resume after a restart).
  Future<void> restore(List<int> ids, int index, Duration position) async {
    _queue.setItems(ids, startIndex: index);
    _queueController.add(null);
    await _loadCurrent(play: false, startAt: position);
  }

  Future<void> _loadCurrent({required bool play, Duration? startAt}) async {
    final token = ++_loadToken;
    final id = _queue.currentId;
    if (id == null) {
      await _goIdle();
      return;
    }
    final track = await _tracks.getById(id);
    if (token != _loadToken) return;
    if (track == null) {
      await _failAndSkip(PlaybackFailureReason.notInLibrary, null, token);
      return;
    }
    // The track we are leaving keeps its place (long tracks only).
    _saveResume();
    _lastResumeSave = Duration.zero;
    // An explicit position (restoring a session) wins over the bookmark.
    final start = (startAt != null && startAt > Duration.zero)
        ? startAt
        : resumeStartFor(track.resumePositionMs);
    _playCounted = false;
    _gainFactor = gainFactor(track.replayGainDb);
    if (_normalize) unawaited(_applyVolume());
    _position = Duration.zero;
    _duration = track.durationMs > 0 ? Duration(milliseconds: track.durationMs) : null;
    _current = track;
    _trackController.add(track);
    mediaItem.add(_toMediaItem(track));
    _publish(AudioProcessingState.loading);
    try {
      await _backend.load(track.path);
      if (token != _loadToken) return;
      // Some backends forget the rate when a new file is loaded.
      if (_speed != 1.0) await _backend.setSpeed(_speed);
      if (start != null && start > Duration.zero) {
        await _backend.seek(start);
      }
      _consecutiveErrors = 0;
      if (play) await _backend.play();
    } on BackendException catch (e) {
      if (token != _loadToken) return;
      AppLog.w('load failed: ${e.message}');
      await _failAndSkip(
          e.fileMissing
              ? PlaybackFailureReason.fileMissing
              : PlaybackFailureReason.unplayable,
          track,
          token);
    }
  }

  Future<void> _failAndSkip(
      PlaybackFailureReason reason, Track? track, int token) async {
    _consecutiveErrors++;
    onError(PlaybackFailure(track?.title, reason));
    if (_consecutiveErrors > maxConsecutiveErrors) {
      await _goIdle();
      return;
    }
    final next = _queue.next(auto: true);
    if (next == null) {
      await _goIdle();
      return;
    }
    await _loadCurrent(play: true);
  }

  Future<void> _goIdle() async {
    _saveResume();
    _loadToken++;
    await _backend.stop();
    _current = null;
    _position = Duration.zero;
    _trackController.add(null);
    mediaItem.add(null);
    _publish(AudioProcessingState.idle);
  }

  MediaItem _toMediaItem(Track t) {
    final cover = coverPathFor?.call(t);
    return MediaItem(
      id: '${t.id}',
      title: t.title,
      artist: t.artist,
      album: t.album,
      duration: _duration,
      artUri: cover == null ? null : Uri.file(cover),
    );
  }

  void _onBackendState(BackendState s) {
    final wasPlaying = _state == BackendState.playing;
    _state = s;
    if (wasPlaying && s == BackendState.paused) _saveResume();
    if (s == BackendState.completed) {
      unawaited(_onCompleted());
      return;
    }
    _publish(switch (s) {
      BackendState.idle => AudioProcessingState.idle,
      BackendState.loading => AudioProcessingState.loading,
      BackendState.error => AudioProcessingState.error,
      _ => AudioProcessingState.ready,
    });
  }

  Future<void> _onCompleted() async {
    if (_handlingCompleted) return;
    _handlingCompleted = true;
    try {
      final finished = _current;
      if (finished != null &&
          (finished.resumePositionMs != null || _savedResume[finished.id] != null)) {
        unawaited(_writeResume(finished, null));
      }
      final next = _queue.next(auto: true);
      final stay = pauseAtTrackEnd;
      pauseAtTrackEnd = false;
      if (next == null) {
        await _goIdle();
      } else {
        await _loadCurrent(play: !stay);
      }
    } finally {
      _handlingCompleted = false;
    }
  }

  void _onPosition(Duration p) {
    _position = p;
    final track = _current;
    if (track != null &&
        _state == BackendState.playing &&
        (p - _lastResumeSave).abs() >= kResumeSaveEvery) {
      _lastResumeSave = p;
      _saveResume();
    }
    if (_playCounted || track == null || _state != BackendState.playing) return;
    final total = _duration;
    final half = total != null && total > Duration.zero && p * 2 >= total;
    if (half || p >= const Duration(seconds: 30)) {
      _playCounted = true;
      _tracks.registerPlay(track.id).catchError((Object e, StackTrace st) {
        AppLog.w('registerPlay failed', e, st);
      });
    }
  }

  void _publish(AudioProcessingState processing) {
    final playing = _state == BackendState.playing;
    playbackState.add(PlaybackState(
      processingState: processing,
      playing: playing,
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      systemActions: const {MediaAction.seek},
      updatePosition: _position,
      speed: _speed,
      queueIndex: _queue.currentIndex < 0 ? null : _queue.currentIndex,
      shuffleMode: _queue.shuffle
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      repeatMode: switch (_queue.repeat) {
        PlayRepeat.off => AudioServiceRepeatMode.none,
        PlayRepeat.all => AudioServiceRepeatMode.all,
        PlayRepeat.one => AudioServiceRepeatMode.one,
      },
    ));
  }

  Future<void> togglePlayPause() async {
    if (_queue.currentId == null) return;
    if (_state == BackendState.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> play() async {
    if (_queue.currentId == null) return;
    if (_current == null ||
        _state == BackendState.idle ||
        _state == BackendState.completed) {
      await _loadCurrent(play: true);
      return;
    }
    await _backend.play();
  }

  @override
  Future<void> pause() => _backend.pause();

  @override
  Future<void> stop() async {
    await _goIdle();
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    await _backend.seek(position);
    _publish(playbackState.value.processingState);
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.currentId == null) return;
    final next = _queue.next();
    if (next == null) {
      await _goIdle();
      return;
    }
    await _loadCurrent(play: true);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.currentId == null) return;
    if (_position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }
    _queue.previous();
    await _loadCurrent(play: true);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    _queue.jumpTo(index);
    await _loadCurrent(play: true);
  }

  Future<void> removeFromQueue(int index) async {
    final wasCurrent = _queue.removeAt(index);
    _queueController.add(null);
    if (wasCurrent) await _loadCurrent(play: _state == BackendState.playing);
  }

  void moveInQueue(int from, int to) {
    _queue.move(from, to);
    _queueController.add(null);
  }

  void playNext(int trackId) {
    _queue.insertNext(trackId);
    _queueController.add(null);
  }

  void addToQueue(int trackId) {
    _queue.append(trackId);
    _queueController.add(null);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _queue.shuffle = shuffleMode != AudioServiceShuffleMode.none;
    _queueController.add(null);
    _publish(playbackState.value.processingState);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _queue.repeat = switch (repeatMode) {
      AudioServiceRepeatMode.none => PlayRepeat.off,
      AudioServiceRepeatMode.one => PlayRepeat.one,
      _ => PlayRepeat.all,
    };
    _publish(playbackState.value.processingState);
  }

  void setShuffleAndRepeat({required bool shuffle, required PlayRepeat repeat}) {
    _queue.shuffle = shuffle;
    _queue.repeat = repeat;
  }

  /// 0.5×–2×, tone unchanged (mpv `scaletempo`, ExoPlayer pitch 1.0).
  @override
  Future<void> setSpeed(double value) async {
    final v = value.clamp(minSpeed, maxSpeed).toDouble();
    if (v == _speed) return;
    _speed = v;
    await _backend.setSpeed(v);
    _publish(playbackState.value.processingState);
  }

  Future<void> setVolume(double v) {
    _baseVolume = v.clamp(0, 1).toDouble();
    return _applyVolume();
  }

  /// ReplayGain: scale the volume down for loud tracks (never above 1.0).
  Future<void> setNormalize(bool enabled) {
    _normalize = enabled;
    return _applyVolume();
  }

  static double gainFactor(double? db) =>
      db == null ? 1.0 : (db >= 0 ? 1.0 : _pow10(db / 20));

  static double _pow10(double x) => math.exp(x * math.ln10);

  Future<void> _applyVolume() => _backend
      .setVolume((_baseVolume * (_normalize ? _gainFactor : 1.0)).clamp(0, 1));

  /// Stores where the current track is (only if it is long enough to matter).
  void _saveResume() {
    final t = _current;
    if (t == null) return;
    final length = t.durationMs > 0 ? t.durationMs : (_duration?.inMilliseconds ?? 0);
    final ms = resumePointFor(_position, length);
    if (ms == null && t.resumePositionMs == null && _savedResume[t.id] == null) {
      return;
    }
    if (_savedResume.containsKey(t.id) && _savedResume[t.id] == ms) return;
    unawaited(_writeResume(t, ms));
  }

  /// Last bookmark written per track in this session (avoids repeat writes).
  final _savedResume = <int, int?>{};

  Future<void> _writeResume(Track t, int? ms) async {
    _savedResume[t.id] = ms;
    try {
      await _tracks.setResumePosition(t.id, ms);
    } on Object catch (e, st) {
      AppLog.w('could not save the resume position of "${t.title}"', e, st);
    }
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _trackController.close();
    await _queueController.close();
    await _backend.dispose();
  }
}
