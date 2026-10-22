import 'dart:async';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';

import '../../core/app_log.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/play_history_repository.dart';
import '../../data/repositories/track_repository.dart';
import 'audio_backend.dart';
import '../online/google_thumb.dart';
import '../online/youtube_service.dart';
import 'crossfade_engine.dart';
import 'equalizer.dart';
import '../radio/icy_title.dart';
import '../radio/radio_station.dart';
import 'next_window.dart';
import 'online_entries.dart';
import 'media_browse_tree.dart';
import 'play_queue.dart';
import 'remote_transport.dart';
import 'resume_point.dart';
import 'stream_address_cache.dart';

enum PlaybackFailureReason {
  fileMissing,
  unplayable,
  notInLibrary,
  onlineUnavailable,
  radioUnavailable,
}

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
    this.onEpisodeHeard,
    this.online,
    this.addresses,
    this.onRadioStart,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        _backend = backend,
        _window = backend is GaplessCapable
            ? NextWindow(_queue, _tracks, backend as GaplessCapable)
            : null {
    _subs
      ..add(_backend.state.listen(_onBackendState))
      ..add(_backend.position.listen(_onPosition))
      ..add(_backend.duration.listen(_onBackendDuration))
      ..add(_backend.streamTitle.listen(_onStreamTitle));
    if (backend is GaplessCapable) {
      _subs.add((backend as GaplessCapable)
          .advanced
          .listen((_) => unawaited(_onAdvanced())));
    }
  }

  static const maxConsecutiveErrors = 3;

  /// Waits before the 1st, 2nd and 3rd new attempt when a radio stream drops.
  static const radioRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 15),
  ];

  /// A radio paused for longer has lost its stream: resuming connects again.
  static const radioResumeAfter = Duration(seconds: 30);
  static const _radioSteadyAfter = Duration(seconds: 10);

  final AudioBackend _backend;
  final PlayHistoryRepository? history;

  /// Told once per session when a podcast episode (track kind 1) has been
  /// listened to from 95 % on, or to its end. The handler knows nothing else
  /// about podcasts.
  final void Function(int trackId)? onEpisodeHeard;

  /// Streamed (not owned) entries of the queue, which have negative ids, and
  /// where their direct addresses come from. Both null: the queue holds only
  /// library tracks.
  final OnlineEntries? online;
  final StreamAddressCache? addresses;

  /// Told (without waiting) each time a radio station starts, not on a
  /// reconnection: the click Radio Browser asks for, the «last played» of a
  /// saved station.
  final void Function(RadioStation station)? onRadioStart;
  final DateTime Function() _clock;
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

  // Live radio: the cleaned «now playing» text, the new attempts after a drop
  // and when the stream was left paused.
  String? _onAir;
  final _onAirController = StreamController<String?>.broadcast();
  int _radioRetries = 0;
  bool _radioBusy = false;
  bool _radioStale = false;
  Timer? _retryTimer;
  Timer? _steadyTimer;
  DateTime? _radioPausedAt;
  ({bool shuffle, PlayRepeat repeat})? _beforeRadio;

  /// The station playing now, if the current entry is a radio.
  RadioEntry? get _radioNow {
    final id = _current?.id;
    return id == null || !isOnlineId(id) ? null : online?.radioOf(id);
  }

  /// Whether the current entry is a live radio (no length, no seeking).
  bool get isRadio => _radioNow != null;

  /// What the station says is on air, or null.
  String? get onAir => _onAir;
  Stream<String?> get onAirStream => _onAirController.stream;

  /// Sleep timer "end of track": the next track is loaded but not started.
  bool get pauseAtTrackEnd => _pauseAtTrackEnd;
  set pauseAtTrackEnd(bool value) {
    _pauseAtTrackEnd = value;
    unawaited(_refreshWindow()); // nothing may follow on its own
  }

  bool _pauseAtTrackEnd = false;

  /// Fires when [pauseAtTrackEnd] has been honoured (or playback ended with
  /// it on), so the sleep timer can clear its state.
  Stream<void> get pausedAtTrackEnd => _pausedAtTrackEnd.stream;
  final _pausedAtTrackEnd = StreamController<void>.broadcast();

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
  double get volume => _baseVolume;
  final _volumeController = StreamController<double>.broadcast();
  final _volumeRequests = StreamController<double>.broadcast();

  /// Every change of the base volume (slider, sleep-timer fade, MPRIS).
  Stream<double> get volumeStream => _volumeController.stream;

  /// Volume asked from outside the app (MPRIS): the UI owner applies it so
  /// the slider and the saved setting follow.
  Stream<double> get volumeRequests => _volumeRequests.stream;

  void requestVolume(double v) {
    if (_volumeRequests.hasListener) {
      _volumeRequests.add(v);
    } else {
      unawaited(setVolume(v));
    }
  }
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

  /// The list playback was started from (a playlist, an album, the search
  /// results…): «Svuota» builds what follows again from it.
  List<int>? _source;

  /// The list playback was started from, if any.
  List<int>? get sourceIds => _source == null ? null : List.unmodifiable(_source!);

  Future<void> playQueue(List<int> ids, int index) async {
    _leaveRadioMode();
    _source = List.of(ids);
    _queue.setItems(ids, startIndex: index);
    _consecutiveErrors = 0;
    _queueController.add(null);
    await _loadCurrent(play: true);
  }

  /// Plays [stations] from [index]: the queue is that list, so next and
  /// previous move between stations. Shuffle and repeat are set aside until
  /// something else is played.
  Future<void> playStations(List<RadioStation> stations, int index) async {
    final registry = online;
    if (registry == null || stations.isEmpty) return;
    final ids = [for (final s in stations) registry.registerRadio(s)];
    _beforeRadio ??= (shuffle: _queue.shuffle, repeat: _queue.repeat);
    _queue.shuffle = false;
    _queue.repeat = PlayRepeat.off;
    _source = List.of(ids);
    _queue.setItems(ids, startIndex: index);
    _consecutiveErrors = 0;
    _queueController.add(null);
    await _loadCurrent(play: true);
  }

  void _leaveRadioMode() {
    final before = _beforeRadio;
    if (before == null) return;
    _beforeRadio = null;
    _queue.shuffle = before.shuffle;
    _queue.repeat = before.repeat;
  }

  /// What Android Auto and other media browsers see (set at start-up).
  MediaBrowseTree? browse;

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    try {
      return await browse?.children(parentMediaId) ?? const [];
    } on Object catch (e, st) {
      AppLog.w('browse $parentMediaId failed', e, st);
      return const [];
    }
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    try {
      return await browse?.item(mediaId);
    } on Object catch (e, st) {
      AppLog.w('browse item $mediaId failed', e, st);
      return null;
    }
  }

  @override
  Future<List<MediaItem>> search(String query,
      [Map<String, dynamic>? extras]) async {
    try {
      return await browse?.search(query) ?? const [];
    } on Object catch (e, st) {
      AppLog.w('browse search failed', e, st);
      return const [];
    }
  }

  @override
  Future<void> playFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    try {
      final radio = await browse?.resolveRadio(mediaId);
      if (radio != null) {
        await playStations(radio.stations, radio.index);
        return;
      }
      final r = await browse?.resolve(mediaId);
      if (r != null) await playQueue(r.ids, r.index);
    } on Object catch (e, st) {
      AppLog.w('play from $mediaId failed', e, st);
    }
  }

  /// Loads the queue paused, at [position] (used to resume after a restart).
  Future<void> restore(List<int> ids, int index, Duration position) async {
    _leaveRadioMode();
    _source = List.of(ids);
    _queue.setItems(ids, startIndex: index, alreadyShuffled: true);
    _queueController.add(null);
    await _loadCurrent(play: false, startAt: position);
  }

  Future<void> _loadCurrent({required bool play, Duration? startAt}) async {
    final token = ++_loadToken;
    _cancelRadioTimers();
    final id = _queue.currentId;
    if (id == null) {
      await _goIdle();
      return;
    }
    final isOnline = isOnlineId(id);
    final entry = isOnline ? online?.entryOf(id) : null;
    final radio = isOnline ? online?.radioOf(id) : null;
    final track = isOnline ? online?.trackOf(id) : await _tracks.getById(id);
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
        : (isOnline ? null : resumeStartFor(track.resumePositionMs));
    _enterTrack(track);
    _publish(AudioProcessingState.loading);
    try {
      if (radio != null) {
        _radioBusy = true;
        if (play) _notifyRadioStart(radio.station);
        await _backend.loadUri(_streamUri(radio.station));
      } else if (entry != null) {
        await _loadStream(entry.result);
      } else {
        await _backend.load(track.path);
      }
      if (token != _loadToken) return;
      // Some backends forget the rate when a new file is loaded. A live
      // stream cannot be sped up: it plays at 1× until a track comes.
      if (radio != null) {
        _radioBusy = false;
        if (_speed != 1.0) await _backend.setSpeed(1.0);
      } else if (_speed != 1.0) {
        await _backend.setSpeed(_speed);
      }
      if (start != null && start > Duration.zero) {
        await _backend.seek(start);
      }
      _consecutiveErrors = 0;
      // A backend that was playing keeps playing a newly loaded file.
      if (play) {
        await _backend.play();
      } else {
        await _backend.pause();
      }
      unawaited(_refreshWindow());
    } on BackendException catch (e) {
      if (token != _loadToken) return;
      AppLog.w('load failed: ${e.message}');
      if (radio != null) {
        _radioBusy = false;
        _radioRetries = 0;
        _scheduleRadioRetry(radio, token);
        return;
      }
      await _failAndSkip(
          isOnline
              ? PlaybackFailureReason.onlineUnavailable
              : e.fileMissing
                  ? PlaybackFailureReason.fileMissing
                  : PlaybackFailureReason.unplayable,
          track,
          token);
    }
  }

  Uri _streamUri(RadioStation s) {
    final uri = Uri.tryParse(s.streamUrl);
    if (uri == null || !uri.hasScheme) {
      throw const BackendException('bad stream address');
    }
    return uri;
  }

  void _notifyRadioStart(RadioStation station) {
    try {
      onRadioStart?.call(station);
    } on Object catch (e, st) {
      AppLog.w('radio start hook failed', e, st);
    }
  }

  void _cancelRadioTimers() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _steadyTimer?.cancel();
    _steadyTimer = null;
    _radioBusy = false;
  }

  /// The stream dropped or could not be opened: tries again after 2, 5 and
  /// 15 seconds, then gives up. It never jumps to another station.
  void _scheduleRadioRetry(RadioEntry radio, int token) {
    if (_radioRetries >= radioRetryDelays.length) {
      _radioRetries = 0;
      onError(PlaybackFailure(radio.station.name, PlaybackFailureReason.radioUnavailable));
      unawaited(_goIdle());
      return;
    }
    final delay = radioRetryDelays[_radioRetries++];
    AppLog.w('radio "${radio.station.name}" down, new attempt in ${delay.inSeconds}s');
    _publish(AudioProcessingState.loading);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (token != _loadToken) return;
      unawaited(_reconnectRadio(radio, token));
    });
  }

  Future<void> _reconnectRadio(RadioEntry radio, int token) async {
    _radioBusy = true;
    _publish(AudioProcessingState.loading);
    try {
      await _backend.loadUri(_streamUri(radio.station));
      if (token != _loadToken) return;
      _radioBusy = false;
      _radioStale = false;
      _radioPausedAt = null;
      await _backend.play();
    } on BackendException catch (e) {
      if (token != _loadToken) return;
      AppLog.w('radio reconnection failed: ${e.message}');
      _radioBusy = false;
      _scheduleRadioRetry(radio, token);
    }
  }

  /// A drop seen while playing; while paused it is only remembered, and the
  /// next play connects again.
  void _onRadioDrop(RadioEntry radio, bool wasLive) {
    if (_radioBusy || (_retryTimer?.isActive ?? false)) return;
    if (!wasLive) {
      _radioStale = true;
      return;
    }
    _radioRetries = 0;
    _scheduleRadioRetry(radio, _loadToken);
  }

  void _onStreamTitle(String? raw) {
    final radio = _radioNow;
    if (radio == null) return;
    _setOnAir(cleanIcyTitle(raw, radio.station.name));
  }

  void _setOnAir(String? value) {
    if (value == _onAir) return;
    _onAir = value;
    _onAirController.add(value);
    final t = _current;
    if (t != null && _remote == null) mediaItem.add(_toMediaItem(t));
  }

  /// Loads an online entry from its direct address. An address that answers
  /// 403 / has expired is dropped and asked for once more; any other failure
  /// (including the resolver's) ends as a [BackendException].
  Future<void> _loadStream(YtResult r) async {
    final cache = addresses;
    if (cache == null) throw const BackendException('no stream resolver');
    for (var attempt = 0;; attempt++) {
      final StreamAddress addr;
      try {
        addr = await cache.address(r);
      } on Object catch (e, st) {
        AppLog.w('no stream address for ${r.id}', e, st);
        throw BackendException('no stream address: $e');
      }
      try {
        await _backend.loadUri(addr.uri, headers: addr.headers);
        return;
      } on BackendException catch (e) {
        if (!e.expired || attempt > 0) rethrow;
        AppLog.d('stream address of ${r.id} expired, asking again'
            '${addr.fast ? ' (default clients)' : ''}');
        cache.invalidate(r);
      }
    }
  }

  /// A podcast file's tags or the feed often carry a wrong length: once the
  /// player knows the real one, the library row takes it.
  void _onBackendDuration(Duration? d) {
    if (isRadio) {
      _duration = null; // a live stream has no length
      return;
    }
    _duration = d;
    final t = _current;
    if (d == null || t == null || t.kind != 1) return;
    final ms = d.inMilliseconds;
    if (ms <= 0 || (ms - t.durationMs).abs() < 2000) return;
    _current = t.copyWith(durationMs: ms);
    _tracks.setDurationMs(t.id, ms).catchError((Object e, StackTrace st) {
      AppLog.w('could not save the length of "${t.title}"', e, st);
    });
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
    if (_onAir != null) {
      _onAir = null;
      _onAirController.add(null);
    }
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
    _cancelRadioTimers();
    _radioRetries = 0;
    _radioStale = false;
    _radioPausedAt = null;
    _endListen();
    _saveResume();
    _window?.clear();
    _loadToken++;
    await _backend.stop();
    _current = null;
    if (_onAir != null) {
      _onAir = null;
      _onAirController.add(null);
    }
    _position = Duration.zero;
    _trackController.add(null);
    mediaItem.add(null);
    _publish(AudioProcessingState.idle);
  }

  MediaItem _toMediaItem(Track t) {
    final radio = isOnlineId(t.id) ? online?.radioOf(t.id) : null;
    if (radio != null) {
      final icon = radio.station.faviconUrl;
      return MediaItem(
        id: 'radio:${radio.station.id}',
        title: _onAir ?? radio.station.name,
        artist: _onAir == null ? null : radio.station.name,
        artUri: icon.isEmpty ? null : Uri.tryParse(icon),
        extras: const {'online': true, 'radio': true},
      );
    }
    final entry = isOnlineId(t.id) ? online?.entryOf(t.id) : null;
    if (entry != null) {
      final thumb = entry.result.thumbnailUrl;
      return MediaItem(
        id: 'online:${entry.result.id}',
        title: t.title,
        artist: t.artist,
        album: t.album,
        duration: _duration,
        artUri: thumb == null ? null : Uri.tryParse(googleThumbAt(thumb, 544)),
        extras: const {'online': true},
      );
    }
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
    final wasLive = wasPlaying || _state == BackendState.loading;
    _state = s;
    final radio = _radioNow;
    if (radio != null) {
      if (wasPlaying && s == BackendState.paused) _radioPausedAt = _clock();
      _steadyTimer?.cancel();
      if (s == BackendState.playing) {
        // A stream that holds for a while has earned a fresh set of attempts.
        _steadyTimer = Timer(_radioSteadyAfter, () => _radioRetries = 0);
      }
      if (s == BackendState.completed || s == BackendState.error) {
        _onRadioDrop(radio, wasLive);
        return;
      }
    } else if (s == BackendState.error) {
      // A player error nobody asked about: the load that caused it reports it.
      AppLog.w('player reported an error');
      return;
    }
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
      if (stay) _pausedAtTrackEnd.add(null);
    } finally {
      _handlingCompleted = false;
    }
  }

  /// A track played to its end has no place to come back to.
  void _forgetBookmarkOfFinished() {
    final finished = _current;
    if (finished == null || isOnlineId(finished.id)) return;
    if (finished.kind == 1) _markHeard(finished);
    if (finished.resumePositionMs != null || _savedResume[finished.id] != null) {
      unawaited(_writeResume(finished, null));
    }
  }

  /// The backend moved on by itself to the track prepared in the window.
  Future<void> _onAdvanced() async {
    _endListen();
    final prepared = _window?.consume();
    _forgetBookmarkOfFinished();
    final id = _queue.next(auto: true);
    // The sleep timer was set too late to stop the backend from moving on by
    // itself: the next track has started, so stop it at its very beginning.
    final stay = _pauseAtTrackEnd;
    _pauseAtTrackEnd = false;
    if (prepared == null || id != prepared.id) {
      // The queue changed after the window was set: play what the queue says.
      if (id == null) {
        await _goIdle();
      } else {
        await _loadCurrent(play: !stay);
      }
      if (stay) _pausedAtTrackEnd.add(null);
      return;
    }
    _consecutiveErrors = 0;
    _lastResumeSave = Duration.zero;
    _enterTrack(prepared);
    if (stay) {
      await _backend.pause();
      await _backend.seek(Duration.zero);
      _pausedAtTrackEnd.add(null);
    }
    _publish(AudioProcessingState.ready);
    await _refreshWindow();
  }

  double _volumeFor(Track t) =>
      (_baseVolume * (_normalize ? gainFactor(t.replayGainDb) : 1.0)).clamp(0, 1).toDouble();

  Future<void> _refreshWindow() async {
    final window = _window;
    final current = _current;
    if (current == null) return;
    // The address of an online entry takes seconds: ask while the one before
    // it plays.
    final next = _queue.peekNext();
    if (next != null && isOnlineId(next)) {
      final r = online?.entryOf(next)?.result;
      if (r != null) addresses?.prefetch(r);
    }
    if (window == null) return;
    try {
      await window.refresh(
        current,
        // Into and out of an online entry the change is a plain new load.
        enabled: _transition != TransitionMode.normal &&
            !_pauseAtTrackEnd &&
            !isOnlineId(current.id),
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
    // Online entries are not in the database: no play count, no history.
    if (isOnlineId(track.id)) return;
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
    final live = isRadio;
    playbackState.add(PlaybackState(
      processingState: processing,
      playing: playing,
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      systemActions: live ? const {} : const {MediaAction.seek},
      updatePosition: _position,
      speed: live ? 1.0 : _speed,
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
    final radio = _radioNow;
    if (radio != null && _radioWentStale()) {
      _radioRetries = 0;
      _cancelRadioTimers();
      await _reconnectRadio(radio, ++_loadToken);
      return;
    }
    await _backend.play();
  }

  bool _radioWentStale() {
    if (_radioStale) return true;
    final since = _radioPausedAt;
    return since != null && _clock().difference(since) > radioResumeAfter;
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
    if (isRadio) return; // live: nothing to seek in
    _position = position;
    await _backend.seek(position);
    _publish(playbackState.value.processingState);
  }

  @override
  Future<void> skipToNext() async {
    final remote = _remote;
    if (remote != null) return remote.next();
    if (_queue.currentId == null) return;
    var next = _queue.next();
    // Past the last station the list starts again.
    if (next == null && isRadio && _queue.items.length > 1) {
      _queue.jumpTo(0);
      next = _queue.currentId;
    }
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
    if (!isRadio && _position > const Duration(seconds: 3)) {
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

  /// Takes every occurrence of [ids] out of the queue and out of the list
  /// playback started from (so «Svuota» never builds them again), for tracks
  /// about to be deleted from disk. When the playing one is among them the
  /// next one is loaded, keeping play/pause (or playback stops with an empty
  /// queue). Completes once the player has let go of the files: on Windows a
  /// file that is open cannot be deleted.
  Future<void> removeTracks(Set<int> ids) async {
    if (ids.isEmpty) return;
    _source = _source?.where((id) => !ids.contains(id)).toList();
    final items = _queue.items;
    final currentGone = _current != null && ids.contains(_current!.id);
    final playing = _state == BackendState.playing;
    var removed = false;
    // From the end, so the natural indices still to visit do not shift.
    for (var i = items.length - 1; i >= 0; i--) {
      if (!ids.contains(items[i])) continue;
      _queue.removeAt(i);
      removed = true;
    }
    if (_queue.isEmpty) _source = null;
    if (!removed && !currentGone) return;
    _queueController.add(null);
    if (currentGone) {
      await _loadCurrent(play: playing);
    }
    // The gapless window may hold the next track open as well.
    await _refreshWindow();
  }

  /// Puts the online (or library) entry [id] at [index] of the play order;
  /// the current track keeps playing.
  void insertAt(int index, int id) {
    if (_queue.isEmpty) _source = null;
    _queue.insertAt(index, id);
    _queueController.add(null);
    unawaited(_refreshWindow());
  }

  /// Swaps the stream entry [oldId] for the library track [newId] (it was
  /// downloaded) at the same place of the queue. The entry now playing keeps
  /// streaming. Returns whether anything changed.
  bool replaceQueueId(int oldId, int newId) {
    if (_queue.replaceId(oldId, newId) == 0) return false;
    _queueController.add(null);
    unawaited(_refreshWindow());
    return true;
  }

  /// Takes the first occurrence of [id] out of the queue (not out of
  /// [sourceIds]); when it was the playing one the next is loaded.
  Future<void> removeQueueId(int id) async {
    final wasCurrent = _queue.removeId(id);
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

  /// «Svuota»: what follows the current track is dropped and, when playback
  /// started from a list, built again from it ([PlayQueue.rebuildUpcoming]).
  /// Returns the queue as it was, for an undo; null with nothing playing.
  QueueState? rebuildUpcoming() {
    if (_queue.currentId == null) return null;
    final before = _queue.saveState();
    _queue.rebuildUpcoming(_source);
    _queueController.add(null);
    unawaited(_refreshWindow());
    return before;
  }

  /// Whether [rebuildUpcoming] has a list to build from.
  bool get hasSource => _source?.isNotEmpty ?? false;

  /// Undoes [rebuildUpcoming] while the same track still plays.
  void restoreQueue(QueueState state) {
    if (!_queue.restoreState(state)) return;
    _queueController.add(null);
    unawaited(_refreshWindow());
  }

  void playNext(int trackId) {
    // A queue started from nothing has no list behind it.
    if (_queue.isEmpty) _source = null;
    _queue.insertNext(trackId);
    _queueController.add(null);
    unawaited(_refreshWindow());
  }

  void addToQueue(int trackId) {
    if (_queue.isEmpty) _source = null;
    _queue.append(trackId);
    _queueController.add(null);
    unawaited(_refreshWindow());
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (isRadio) return; // a list of stations is never shuffled
    _queue.shuffle = shuffleMode != AudioServiceShuffleMode.none;
    _queueController.add(null);
    unawaited(_refreshWindow());
    _publish(playbackState.value.processingState);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    if (isRadio) return;
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
    // A live stream stays at 1×; the rate comes back with the next track.
    if (!isRadio) await _backend.setSpeed(v);
    _publish(playbackState.value.processingState);
  }

  Future<void> setVolume(double v) {
    _baseVolume = v.clamp(0, 1).toDouble();
    _volumeController.add(_baseVolume);
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
    if (transport != null && isRadio) _stopRadioForJam();
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

  /// A Jam starting stops the radio, like it stops local music.
  void _stopRadioForJam() {
    _cancelRadioTimers();
    _radioRetries = 0;
    _loadToken++;
    unawaited(_backend.stop());
    _current = null;
    _onAir = null;
    _trackController.add(null);
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
    if (t == null || isOnlineId(t.id)) return;
    final length = t.durationMs > 0 ? t.durationMs : (_duration?.inMilliseconds ?? 0);
    final episode = t.kind == 1;
    if (episode && episodeHeard(_position, length)) _markHeard(t);
    final ms = resumePointFor(_position, length, episode: episode);
    if (ms == null && t.resumePositionMs == null && _savedResume[t.id] == null) {
      return;
    }
    if (_savedResume.containsKey(t.id) && _savedResume[t.id] == ms) return;
    unawaited(_writeResume(t, ms));
  }

  final _heard = <int>{};

  void _markHeard(Track episode) {
    if (!_heard.add(episode.id)) return;
    try {
      onEpisodeHeard?.call(episode.id);
    } on Object catch (e, st) {
      AppLog.w('could not mark "${episode.title}" as heard', e, st);
    }
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
    _cancelRadioTimers();
    _endListen();
    await _remoteSub?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    await _trackController.close();
    await _queueController.close();
    await _pausedAtTrackEnd.close();
    await _onAirController.close();
    await _backend.dispose();
  }
}
