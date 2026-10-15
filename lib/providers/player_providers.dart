import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/platform.dart';
import '../data/db/app_database.dart';
import '../services/audio/codecore_audio_handler.dart';
import '../services/audio/play_queue.dart';
import '../services/audio/playback_persistence.dart';
import 'database_providers.dart';
import 'settings_providers.dart';

/// Overridden in `main` once the handler has been created (and, on Android,
/// registered with `AudioService.init`).
final audioHandlerProvider = Provider<CodecoreAudioHandler>(
    (ref) => throw UnimplementedError('audioHandlerProvider not overridden'));

final playbackPersistenceProvider = Provider<PlaybackPersistence?>((ref) => null);

final playerErrorsProvider = Provider<Stream<PlaybackFailure>>(
    (ref) => const Stream<PlaybackFailure>.empty());

class PlayerController {
  PlayerController(this._handler, this._persistence);

  final CodecoreAudioHandler _handler;
  final PlaybackPersistence? _persistence;
  bool _askedNotifications = false;

  /// Only the ids travel to the player; it resolves tracks via the repository.
  Future<void> playFromList(List<Track> snapshot, int index) async {
    if (snapshot.isEmpty) return;
    _requestNotificationPermissionOnce();
    await _handler.playQueue([for (final t in snapshot) t.id], index);
  }

  Future<void> togglePlayPause() => _handler.togglePlayPause();
  Future<void> next() => _handler.skipToNext();
  bool get hasNext => _handler.hasNext;
  Future<void> previous() => _handler.skipToPrevious();
  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> jumpToQueueIndex(int index) => _handler.skipToQueueItem(index);
  Future<void> removeFromQueue(int index) => _handler.removeFromQueue(index);
  void reorderQueue(int from, int to) {
    _handler.moveInQueue(from, to);
  }

  void playNext(int trackId) => _handler.playNext(trackId);
  void addToQueue(int trackId) => _handler.addToQueue(trackId);

  Future<void> setVolume(double v) {
    _persistence?.setVolume(v);
    return _handler.setVolume(v);
  }

  Future<void> toggleShuffle() => _handler.setShuffleMode(_handler.shuffleEnabled
      ? AudioServiceShuffleMode.none
      : AudioServiceShuffleMode.all);

  Future<void> setShuffle(bool on) => _handler.setShuffleMode(
      on ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);

  Future<void> cycleRepeat() => _handler.setRepeatMode(
        switch (_handler.repeatMode) {
          PlayRepeat.off => AudioServiceRepeatMode.all,
          PlayRepeat.all => AudioServiceRepeatMode.one,
          PlayRepeat.one => AudioServiceRepeatMode.none,
        },
      );

  void _requestNotificationPermissionOnce() {
    if (_askedNotifications || !isAndroid) return;
    _askedNotifications = true;
    unawaited(Permission.notification.request());
  }
}

final playerControllerProvider = Provider<PlayerController>((ref) =>
    PlayerController(ref.watch(audioHandlerProvider),
        ref.watch(playbackPersistenceProvider)));

final currentTrackProvider = StreamProvider<Track?>((ref) async* {
  final h = ref.watch(audioHandlerProvider);
  yield h.currentTrack;
  yield* h.currentTrackStream;
});

final isPlayingProvider = StreamProvider<bool>((ref) {
  final h = ref.watch(audioHandlerProvider);
  return h.playbackState.map((s) => s.playing).distinct();
});

final shuffleProvider = StreamProvider<bool>((ref) {
  final h = ref.watch(audioHandlerProvider);
  return h.playbackState
      .map((s) => s.shuffleMode != AudioServiceShuffleMode.none)
      .distinct();
});

final repeatProvider = StreamProvider<PlayRepeat>((ref) {
  final h = ref.watch(audioHandlerProvider);
  return h.playbackState
      .map((s) => switch (s.repeatMode) {
            AudioServiceRepeatMode.one => PlayRepeat.one,
            AudioServiceRepeatMode.all ||
            AudioServiceRepeatMode.group =>
              PlayRepeat.all,
            AudioServiceRepeatMode.none => PlayRepeat.off,
          })
      .distinct();
});

/// Separate from everything else so only the slider rebuilds on each tick.
final positionProvider = StreamProvider<Duration>(
    (ref) => ref.watch(audioHandlerProvider).positionStream);

final durationProvider = StreamProvider<Duration?>(
    (ref) => ref.watch(audioHandlerProvider).durationStream);

final queueProvider = StreamProvider<List<Track>>((ref) async* {
  final h = ref.watch(audioHandlerProvider);
  final repo = ref.watch(trackRepositoryProvider);
  yield await repo.getByIds(h.queueIds);
  await for (final _ in h.queueChanges) {
    yield await repo.getByIds(h.queueIds);
  }
});

class VolumeNotifier extends Notifier<double> {
  double _beforeMute = 1.0;

  @override
  double build() => ref.read(settingsStoreProvider).readPlayback().volume;

  void set(double v) {
    state = v;
    ref.read(playerControllerProvider).setVolume(v);
  }

  void toggleMute() {
    if (state > 0) {
      _beforeMute = state;
      set(0);
    } else {
      set(_beforeMute <= 0 ? 1.0 : _beforeMute);
    }
  }
}

final volumeProvider =
    NotifierProvider<VolumeNotifier, double>(VolumeNotifier.new);

final playerFailuresProvider = StreamProvider<PlaybackFailure>(
    (ref) => ref.watch(playerErrorsProvider));

/// Current track kept in sync with DB edits (favourite flag, title, ...).
final liveCurrentTrackProvider = StreamProvider<Track?>((ref) {
  final id = ref.watch(currentTrackProvider.select((t) => t.value?.id));
  if (id == null) return Stream.value(null);
  return ref.watch(trackRepositoryProvider).watchById(id);
});
