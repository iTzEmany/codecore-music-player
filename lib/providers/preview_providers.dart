import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../services/audio/audio_backend.dart';
import '../services/audio/just_audio_backend.dart';
import '../services/audio/preview_player.dart';
import 'jam_providers.dart';
import 'player_providers.dart';

/// Creates the player used for previews (overridden in tests).
final previewBackendFactoryProvider = Provider<AudioBackend Function()>(
  (ref) => JustAudioBackend.new,
);

/// «Anteprima di 20 s»: pauses the main player only if it was playing and
/// gives it back when the preview ends. Queue and play counts are untouched.
class PreviewNotifier extends Notifier<PreviewState> {
  late final PreviewPlayer _player;
  StreamSubscription<PreviewState>? _sub;
  bool _resumeMain = false;

  @override
  PreviewState build() {
    _player = PreviewPlayer(ref.read(previewBackendFactoryProvider));
    _sub = _player.changes.listen(_onChange);
    ref.onDispose(() {
      _sub?.cancel();
      unawaited(_player.dispose());
    });
    return const PreviewState();
  }

  /// Not during a Jam: the second player there is busy with the Jam.
  Future<void> start(Track track) async {
    if (ref.read(jamProvider).active) return;
    final handler = ref.read(audioHandlerProvider);
    if (!state.active) {
      _resumeMain = handler.isPlaying;
      if (_resumeMain) await handler.pause();
    }
    await _player.start(track);
    // A preview that could not start must not leave the music paused.
    if (!_player.state.active) _onChange(const PreviewState());
  }

  Future<void> stop() => _player.stop();

  void _onChange(PreviewState s) {
    state = s;
    if (!s.active && _resumeMain) {
      _resumeMain = false;
      unawaited(ref.read(audioHandlerProvider).play());
    }
  }
}

final previewProvider =
    NotifierProvider<PreviewNotifier, PreviewState>(PreviewNotifier.new);
