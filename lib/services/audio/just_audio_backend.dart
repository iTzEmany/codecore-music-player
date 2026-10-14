import 'dart:io';

import 'package:just_audio/just_audio.dart';

import '../../core/app_log.dart';
import 'audio_backend.dart';

class JustAudioBackend implements AudioBackend {
  JustAudioBackend() : _player = AudioPlayer();

  final AudioPlayer _player;

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
      throw const BackendException('file mancante');
    }
    try {
      await _player.setFilePath(filePath);
    } on Object catch (e, st) {
      AppLog.w('load failed: $filePath', e, st);
      throw BackendException('file non riproducibile: $e');
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
  Future<void> dispose() => _player.dispose();
}
