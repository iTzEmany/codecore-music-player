import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_log.dart';
import '../services/audio/audio_backend.dart';
import '../services/audio/just_audio_backend.dart';
import '../services/online/youtube_service.dart';
import 'jam_providers.dart';
import 'player_providers.dart';
import 'youtube_providers.dart';

enum ListenPhase { idle, resolving, playing, paused }

/// «Ascolta»: an online result played straight from the network.
class ListenState {
  const ListenState({
    this.result,
    this.phase = ListenPhase.idle,
    this.position = Duration.zero,
    this.duration,
    this.error,
  });

  final YtResult? result;
  final ListenPhase phase;
  final Duration position;
  final Duration? duration;

  /// Why the last listen could not start (shown once by the UI).
  final YtErrorKind? error;

  bool get active => phase != ListenPhase.idle;
  bool isOf(YtResult r) => result?.indexKey == r.indexKey;

  ListenState copyWith({ListenPhase? phase, Duration? position, Duration? duration}) =>
      ListenState(
        result: result,
        phase: phase ?? this.phase,
        position: position ?? this.position,
        duration: duration ?? this.duration,
      );
}

/// Where a result is played from (overridden in tests); null without yt-dlp.
final streamResolverProvider = Provider<Future<Uri> Function(YtResult)?>((ref) {
  final s = ref.watch(ytDlpServiceProvider);
  return s is StreamSource ? (s as StreamSource).streamUrl : null;
});

/// The player of the listens (overridden in tests).
final listenBackendFactoryProvider = Provider<AudioBackend Function()>(
  (ref) => JustAudioBackend.new,
);

/// One listen at a time, on its own player: the main queue, play counts and
/// history are never touched. The music that was playing pauses and comes
/// back when the listen ends.
class ListenNotifier extends Notifier<ListenState> {
  AudioBackend? _backend;
  final _subs = <StreamSubscription<Object?>>[];
  int _token = 0;
  bool _resumeMain = false;

  @override
  ListenState build() {
    // Music started from the library ends the listen (and is not paused again).
    ref.listen(isPlayingProvider, (_, playing) {
      if (playing.value == true && state.active && _backend != null) {
        _resumeMain = false;
        unawaited(stop());
      }
    });
    ref.onDispose(() => unawaited(_release()));
    return const ListenState();
  }

  bool get isActive => state.active;

  /// Plays [r]; on the one already playing it pauses or resumes it.
  Future<void> toggle(YtResult r) async {
    if (state.isOf(r) && state.phase == ListenPhase.playing) return pause();
    if (state.isOf(r) && state.phase == ListenPhase.paused) return resume();
    if (state.isOf(r) && state.phase == ListenPhase.resolving) return;
    await start(r);
  }

  Future<void> start(YtResult r) async {
    if (ref.read(jamProvider).active) return;
    final resolve = ref.read(streamResolverProvider);
    if (resolve == null) {
      state = const ListenState(error: YtErrorKind.toolMissing);
      return;
    }
    await _release();
    final token = ++_token;
    final handler = ref.read(audioHandlerProvider);
    if (!_resumeMain && handler.isPlaying) {
      _resumeMain = true;
      await handler.pause();
    }
    state = ListenState(result: r, phase: ListenPhase.resolving);
    final watch = Stopwatch()..start();
    try {
      final uri = await resolve(r);
      if (token != _token) return;
      final resolved = watch.elapsedMilliseconds;
      final backend = ref.read(listenBackendFactoryProvider)();
      _backend = backend;
      _subs
        ..add(backend.position.listen((p) {
          if (token == _token) state = state.copyWith(position: p);
        }))
        ..add(backend.duration.listen((d) {
          if (token == _token && d != null) state = state.copyWith(duration: d);
        }))
        ..add(backend.state.listen((s) {
          if (token == _token && s == BackendState.completed) unawaited(stop());
        }));
      await backend.loadUri(uri);
      if (token != _token) return;
      await backend.play();
      state = state.copyWith(phase: ListenPhase.playing, duration: r.duration);
      AppLog.i('listen ${r.source.name}: address in $resolved ms, '
          'playing after ${watch.elapsedMilliseconds} ms');
    } on YtException catch (e) {
      AppLog.w('listen: no stream for ${r.indexKey}', e);
      if (token == _token) await _end(error: e.kind);
    } on BackendException catch (e) {
      AppLog.w('listen: stream not playable: ${e.message}');
      if (token == _token) await _end(error: YtErrorKind.network);
    }
  }

  Future<void> pause() async {
    await _backend?.pause();
    if (state.active) state = state.copyWith(phase: ListenPhase.paused);
  }

  Future<void> resume() async {
    await _backend?.play();
    if (state.active) state = state.copyWith(phase: ListenPhase.playing);
  }

  Future<void> seek(Duration to) async => _backend?.seek(to);

  /// Ends the listen and gives the music back.
  Future<void> stop() => _end();

  Future<void> _end({YtErrorKind? error}) async {
    _token++;
    await _release();
    state = ListenState(error: error);
    if (_resumeMain) {
      _resumeMain = false;
      unawaited(ref.read(audioHandlerProvider).play());
    }
  }

  Future<void> _release() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    final backend = _backend;
    _backend = null;
    if (backend == null) return;
    try {
      await backend.stop();
      await backend.dispose();
    } on Object catch (e, st) {
      AppLog.w('listen player cleanup failed', e, st);
    }
  }
}

final listenProvider = NotifierProvider<ListenNotifier, ListenState>(ListenNotifier.new);
