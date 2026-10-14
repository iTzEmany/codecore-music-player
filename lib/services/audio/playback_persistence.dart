import 'dart:async';

import '../../core/app_log.dart';
import '../../data/settings/settings_store.dart';
import 'codecore_audio_handler.dart';

/// Debounced (2 s) save of queue/position/volume so playback can resume.
class PlaybackPersistence {
  PlaybackPersistence(this._handler, this._store);

  final CodecoreAudioHandler _handler;
  final SettingsStore _store;
  final List<StreamSubscription<Object?>> _subs = [];
  Timer? _timer;
  double _volume = 1.0;
  Duration _position = Duration.zero;

  /// Restores the saved queue paused at the saved position.
  Future<void> restore() async {
    final s = _store.readPlayback();
    _volume = s.volume;
    await _handler.setVolume(s.volume);
    _handler.setShuffleAndRepeat(shuffle: s.shuffle, repeat: s.repeat);
    if (s.queueIds.isEmpty) return;
    await _handler.restore(
        s.queueIds, s.index, Duration(milliseconds: s.positionMs));
  }

  void start() {
    _subs
      ..add(_handler.positionStream.listen((p) {
        _position = p;
        _schedule();
      }))
      ..add(_handler.queueChanges.listen((_) => _schedule()))
      ..add(_handler.currentTrackStream.listen((_) => _schedule()));
  }

  void setVolume(double v) {
    _volume = v;
    _schedule();
  }

  void _schedule() {
    _timer ??= Timer(const Duration(seconds: 2), () {
      _timer = null;
      unawaited(flush());
    });
  }

  Future<void> flush() async {
    try {
      await _store.writePlayback(SavedPlayback(
        queueIds: _handler.queueIds,
        index: _handler.currentIndex < 0 ? 0 : _handler.currentIndex,
        positionMs: _position.inMilliseconds,
        volume: _volume,
        shuffle: _handler.shuffleEnabled,
        repeat: _handler.repeatMode,
      ));
    } on Object catch (e, st) {
      AppLog.w('persist playback failed', e, st);
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
  }
}
