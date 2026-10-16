import 'dart:io';

import 'package:just_audio/just_audio.dart';

import '../../core/app_log.dart';
import 'audio_backend.dart';
import 'equalizer.dart';

class JustAudioBackend implements AudioBackend {
  /// [withEqualizer] (Android only) puts an `AndroidEqualizer` in the player's
  /// audio pipeline. Only the main player asks for it.
  factory JustAudioBackend({bool withEqualizer = false}) {
    if (withEqualizer && Platform.isAndroid) {
      final eq = AndroidEqualizer();
      return JustAudioBackend._(
        AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [eq])),
        _AndroidEq(eq),
      );
    }
    return JustAudioBackend._(AudioPlayer(), null);
  }

  JustAudioBackend._(this._player, this.equalizer);

  final AudioPlayer _player;

  @override
  final Equalizer? equalizer;

  @override
  Stream<Duration> get position => _player.positionStream;

  @override
  Stream<Duration?> get duration => _player.durationStream;

  @override
  Stream<BackendState> get state =>
      _player.playerStateStream.map((s) => switch (s.processingState) {
            ProcessingState.idle => BackendState.idle,
            ProcessingState.loading ||
            ProcessingState.buffering =>
              BackendState.loading,
            ProcessingState.ready =>
              s.playing ? BackendState.playing : BackendState.paused,
            ProcessingState.completed => BackendState.completed,
          });

  @override
  Future<void> load(String filePath) async {
    if (!await File(filePath).exists()) {
      throw const BackendException('file missing', fileMissing: true);
    }
    try {
      await _player.setFilePath(filePath);
    } on Object catch (e, st) {
      AppLog.w('load failed: $filePath', e, st);
      throw BackendException('unplayable file: $e');
    }
  }

  @override
  Future<void> loadUri(Uri uri,
      {Map<String, String> headers = const {}}) async {
    try {
      await _player.setAudioSource(AudioSource.uri(uri, headers: headers));
    } on Object catch (e, st) {
      AppLog.w('stream load failed: ${uri.host}', e, st);
      throw BackendException('unplayable stream: $e');
    }
  }

  // play() completes only when playback ends or pauses: never await it.
  @override
  Future<void> play() async {
    _player.play().catchError((Object e, StackTrace st) {
      AppLog.e('play failed', e, st);
    });
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Duration get positionNow => _player.position;

  @override
  Future<void> dispose() => _player.dispose();
}

class _AndroidEq implements Equalizer {
  _AndroidEq(this._eq);

  final AndroidEqualizer _eq;

  @override
  Future<EqBands> bands() async {
    final p = await _eq.parameters;
    return EqBands(
      centerHz: [for (final b in p.bands) b.centerFrequency],
      minDb: p.minDecibels,
      maxDb: p.maxDecibels,
    );
  }

  @override
  Future<void> setEnabled(bool enabled) => _eq.setEnabled(enabled);

  @override
  Future<void> setGains(List<double> gainsDb) async {
    final p = await _eq.parameters;
    for (var i = 0; i < p.bands.length; i++) {
      final g = i < gainsDb.length ? gainsDb[i] : 0.0;
      await p.bands[i].setGain(g.clamp(p.minDecibels, p.maxDecibels).toDouble());
    }
  }
}
