import 'dart:async';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';

import '../../core/app_log.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/play_history_repository.dart';
import '../../data/repositories/track_repository.dart';
import 'audio_backend.dart';
import 'crossfade_engine.dart';
import 'equalizer.dart';
import 'next_window.dart';
import 'play_queue.dart';
import 'remote_transport.dart';
import 'resume_point.dart';

enum PlaybackFailureReason { fileMissing, unplayable, notInLibrary }

class PlaybackFailure {
  const PlaybackFailure(this.title, this.reason);

  final String? title;
  final PlaybackFailureReason reason;
}

class CodecoreAudioHandler extends BaseAudioHandler with SeekHandler {
  CodecoreAudioHandler(
    AudioBackend backend,
    this._queue,
    this._tracks, {
    required this.onError,
    this.coverPathFor,
    this.history,
  })  : _backend = backend,
        _window = backend is GaplessCapable
            ? NextWindow(_queue, _tracks, backend as GaplessCapable)
            : null {
    _subs
      ..add(_backend.state.listen(_onBackendState))
      ..add(_backend.position.listen(_onPosition))
      ..add(_backend.duration.listen((d) => _duration = d));
    if (backend is GaplessCapable) {
      _subs.add((backend as GaplessCapable)
          .advanced
          .listen((_) => unawaited(_onAdvanced())));
    }
  }

  static const maxConsecutiveErrors = 3;

  final AudioBackend _backend;
  final PlayHistoryRepository? history;
  final NextWindow? _window;
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
  RemoteTransport? _remote;
  StreamSubscription<RemoteStatus>? _remoteSub;

  /// The listening history (`plays`) is written only while this is on.
  bool recordHistory = true;
  int? _contextKind;
  String? _contextName;

  // The listen being timed: the row (once it counted as played), the time
  // really spent playing the current track and the last position seen.
  Future<int?>? _playRow;
  int _playedMs = 0;
  int _flushedMs = 0;
  Duration? _lastTick;
  Duration _lastResumeSave = Duration.zero;
  bool _handlingCompleted = false;

  /// Sleep timer "end of track": the next track is loaded but not started.
  bool get pauseAtTrackEnd => _pauseAtTrackEnd;
  set pauseAtTrackEnd(bool value) {
    _pauseAtTrackEnd = value;
    unawaited(_refreshWindow()); // nothing may follow on its own
  }

  bool _pauseAtTrackEnd = false;

  TransitionMode _transition = TransitionMode.normal;
  TransitionMode get transition => _transition;

  /// In the crossfade, tracks of the same album follow each other plainly.
  bool _plainInAlbum = false;
  int _crossfadeSeconds = 6;

  /// Playback speed, kept by the handler so every new track gets it again.
  static const minSpeed = 0.5, maxSpeed = 2.0;
  double _speed = 1.0;
  double get speed => _speed;

  double _baseVolume = 1.0;
  bool _normalize = false;
  double _gainFactor = 1.0;

  /// The main player's equalizer, or null where there is none.
  Equalizer? get equalizer => _backend.equalizer;

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
    _endListen();
    _saveResume();
    _lastResumeSave = Duration.zero;
    // An explicit position (restoring a session) wins over the bookmark.
    final start = (startAt != null && startAt > Duration.zero)
        ? startAt
        : resumeStartFor(track.resumePositionMs);
    _enterTrack(track);
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
      unawaited(_refreshWindow());
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

  /// Makes [track] the current one (state, gain, notification).
  void _enterTrack(Track track) {
    _playCounted = false;
    _playedMs = 0;
    _flushedMs = 0;
    _lastTick = null;
    _gainFactor = gainFactor(track.replayGainDb);
    if (_normalize) unawaited(_applyVolume());
    _position = Duration.zero;
    _duration = track.durationMs > 0 ? Duration(milliseconds: track.durationMs) : null;
    _current = track;
    _trackController.add(track);
    mediaItem.add(_toMediaItem(track));
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
    _endListen();
    _saveResume();
    _window?.clear();
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
    if (wasPlaying && s == BackendState.paused) {
      _saveResume();
      _flushListen();
    }
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
      _forgetBookmarkOfFinished();
      final next = _queue.next(auto: true);
      final stay = _pauseAtTrackEnd;
      _pauseAtTrackEnd = false;
      if (next == null) {
        await _goIdle();
      } else {
        await _loadCurrent(play: !stay);
      }
    } finally {
      _handlingCompleted = false;
    }
  }

  /// A track played to its end has no place to come back to.
  void _forgetBookmarkOfFinished() {
    final finished = _current;
    if (finished != null &&
        (finished.resumePositionMs != null || _savedResume[finished.id] != null)) {
      unawaited(_writeResume(finished, null));
    }
  }

  /// The backend moved on by itself to the track prepared in the window.
  Future<void> _onAdvanced() async {
    _endListen();
    final prepared = _window?.consume();
    _forgetBookmarkOfFinished();
    final id = _queue.next(auto: true);
    if (prepared == null || id != prepared.id) {
      // The queue changed after the window was set: play what the queue says.
      if (id == null) {
        await _goIdle();
      } else {
        await _loadCurrent(play: true);
      }
      return;
    }
    _consecutiveErrors = 0;
    _lastResumeSave = Duration.zero;
    _enterTrack(prepared);
    _publish(AudioProcessingState.ready);
    await _refreshWindow();
  }

  double _volumeFor(Track t) =>
      (_baseVolume * (_normalize ? gainFactor(t.replayGainDb) : 1.0)).clamp(0, 1).toDouble();

  Future<void> _refreshWindow() async {
    final window = _window;
    final current = _current;
    if (window == null || current == null) return;
    try {
      await window.refresh(
        current,
        enabled: _transition != TransitionMode.normal && !_pauseAtTrackEnd,
        volumeFor: _volumeFor,
        overlap: (a, b) =>
            _transition == TransitionMode.crossfade &&
            !(_plainInAlbum && a.albumKey == b.albumKey),
      );
    } on Object catch (e, st) {
      AppLog.w('could not prepare the next track', e, st);
    }
  }

  /// Chooses how tracks follow each other. Takes effect from the next join.
  Future<void> setTransition(
    TransitionMode mode, {
    bool plainInAlbum = false,
    int crossfadeSeconds = 6,
  }) async {
    if (mode == _transition &&
        plainInAlbum == _plainInAlbum &&
        crossfadeSeconds == _crossfadeSeconds) {
      return;
    }
    _transition = mode;
    _plainInAlbum = plainInAlbum;
    _crossfadeSeconds = crossfadeSeconds;
    final engine = _backend;
    if (engine is CrossfadeEngine) {
      engine.crossfade =
          mode == TransitionMode.crossfade ? Duration(seconds: crossfadeSeconds) : null;
    }
    _window?.invalidate();
    await _refreshWindow();
  }

  /// Time really spent playing the current track: the position moving on while
  /// playing (a seek is a jump, not time; at 2× it is half the music).
  void _tickPlayed(Duration p) {
    final prev = _lastTick;
    _lastTick = p;
    if (prev == null || _state != BackendState.playing) return;
    final d = p - prev;
    if (d > Duration.zero && d < const Duration(seconds: 3)) {
      _playedMs += (d.inMilliseconds / _speed).round();
    }
  }

  /// Where the listen being recorded came from (`PlayContextKind.index`).
  void setPlayContext(int? kind, String? name) {
    _contextKind = kind;
    _contextName = name;
  }

  /// The track just counted as played: opens its row in the history.
  void _beginListen(Track track) {
    final repo = history;
    // Podcast episodes are not music: they stay out of the history and the recap.
    if (repo == null || !recordHistory || track.kind != 0) return;
    _flushedMs = _playedMs;
    _playRow = repo
        .start(
          track.id,
          DateTime.now().millisecondsSinceEpoch,
          context: _contextKind,
          contextName: _contextName,
          msPlayed: _playedMs,
        )
        .then<int?>((id) => id)
        .catchError((Object e, StackTrace st) {
          AppLog.w('could not record the listen', e, st);
          return null;
        });
  }

  /// Writes the time played so far into the row (it only grows).
  void _flushListen() {
    final row = _playRow;
    if (row == null || _playedMs == _flushedMs) return;
    final ms = _playedMs;
    _flushedMs = ms;
    unawaited(row.then((id) async {
      if (id != null) await history!.finish(id, ms);
    }).catchError((Object e, StackTrace st) {
      AppLog.w('could not update the listen', e, st);
    }));
  }

  void _endListen() {
    _flushListen();
    _playRow = null;
    _playedMs = 0;
    _flushedMs = 0;
    _lastTick = null;
  }

  void _onPosition(Duration p) {
    _position = p;
    final track = _current;
    _tickPlayed(p);
    if (_playRow != null && _playedMs - _flushedMs >= 30000) _flushListen();
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
      _beginListen(track);
    }
  }

  void _publish(AudioProcessingState processing) {
    if (_remote != null) return; // the Jam owns the notification
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
    final remote = _remote;
    if (remote != null) return remote.play();
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
  Future<void> pause() => _remote?.pause() ?? _backend.pause();

  @override
  Future<void> stop() async {
    final remote = _remote;
    if (remote != null) return remote.pause(); // ending the Jam is its own button
    await _goIdle();
  }

  @override
  Future<void> seek(Duration position) async {
    final remote = _remote;
    if (remote != null) return remote.seek(position);
    _position = position;
    await _backend.seek(position);
    _publish(playbackState.value.processingState);
  }

  @override
  Future<void> skipToNext() async {
    final remote = _remote;
    if (remote != null) return remote.next();
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
    final remote = _remote;
    if (remote != null) {
      await remote.seek(Duration.zero); // a Jam has no «previous»
      return;
    }
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
    if (wasCurrent) {
      await _loadCurrent(play: _state == BackendState.playing);
    } else {
      unawaited(_refreshWindow());
    }
  }

  void moveInQueue(int from, int to) {
    _queue.move(from, to);
    _queueController.add(null);
    unawaited(_refreshWindow());
  }

  void playNext(int trackId) {
    _queue.insertNext(trackId);
    _queueController.add(null);
    unawaited(_refreshWindow());
  }

  void addToQueue(int trackId) {
    _queue.append(trackId);
    _queueController.add(null);
    unawaited(_refreshWindow());
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _queue.shuffle = shuffleMode != AudioServiceShuffleMode.none;
    _queueController.add(null);
    unawaited(_refreshWindow());
    _publish(playbackState.value.processingState);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _queue.repeat = switch (repeatMode) {
      AudioServiceRepeatMode.none => PlayRepeat.off,
      AudioServiceRepeatMode.one => PlayRepeat.one,
      _ => PlayRepeat.all,
    };
    unawaited(_refreshWindow());
    _publish(playbackState.value.processingState);
  }

  void setShuffleAndRepeat({required bool shuffle, required PlayRepeat repeat}) {
    _queue.shuffle = shuffle;
    _queue.repeat = repeat;
    unawaited(_refreshWindow());
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
    _volumeChangedForWindow();
    return _applyVolume();
  }

  /// ReplayGain: scale the volume down for loud tracks (never above 1.0).
  Future<void> setNormalize(bool enabled) {
    _normalize = enabled;
    _volumeChangedForWindow();
    return _applyVolume();
  }

  /// The next track is announced with its own volume: tell the backend again.
  void _volumeChangedForWindow() {
    final window = _window;
    if (window == null ||
        window.track == null ||
        _transition != TransitionMode.crossfade) {
      return; // only a crossfade plays the next track before its turn
    }
    window.invalidate();
    unawaited(_refreshWindow());
  }

  static double gainFactor(double? db) =>
      db == null ? 1.0 : (db >= 0 ? 1.0 : _pow10(db / 20));

  static double _pow10(double x) => math.exp(x * math.ln10);

  Future<void> _applyVolume() => _backend
      .setVolume((_baseVolume * (_normalize ? _gainFactor : 1.0)).clamp(0, 1));

  /// Hands the system controls to [transport] (a Jam) until it is detached
  /// with null. The local queue and backend are not touched meanwhile.
  void attachRemote(RemoteTransport? transport) {
    _remoteSub?.cancel();
    _remoteSub = null;
    _remote = transport;
    if (transport == null) {
      // Back to what the local player says.
      final t = _current;
      mediaItem.add(t == null ? null : _toMediaItem(t));
      _publish(_publishedProcessing);
      return;
    }
    _showRemote(transport.status);
    _remoteSub = transport.changes.listen(_showRemote);
  }

  void _showRemote(RemoteStatus s) {
    mediaItem.add(s.hasItem
        ? MediaItem(
            id: 'jam',
            title: s.title!,
            artist: s.artist,
            album: s.album,
            duration: s.duration,
          )
        : null);
    playbackState.add(PlaybackState(
      processingState:
          s.hasItem ? AudioProcessingState.ready : AudioProcessingState.idle,
      playing: s.playing,
      controls: [
        s.playing ? MediaControl.pause : MediaControl.play,
        if (s.canSkip) MediaControl.skipToNext,
      ],
      androidCompactActionIndices: s.canSkip ? const [0, 1] : const [0],
      systemActions: const {MediaAction.seek},
      updatePosition: s.position,
      speed: 1,
    ));
  }

  AudioProcessingState get _publishedProcessing =>
      playbackState.value.processingState;

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
    _endListen();
    await _remoteSub?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    await _trackController.close();
    await _queueController.close();
    await _backend.dispose();
  }
}
