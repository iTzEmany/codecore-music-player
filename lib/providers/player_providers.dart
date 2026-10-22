import 'dart:async';

import '../core/app_log.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/platform.dart';
import '../data/db/app_database.dart';
import '../services/audio/codecore_audio_handler.dart';
import '../services/audio/online_entries.dart';
import '../services/audio/play_queue.dart';
import '../services/radio/radio_station.dart';
import '../services/audio/playback_persistence.dart';
import 'database_providers.dart';
import 'queue_tracks.dart';
import 'settings_providers.dart';

/// Overridden in `main` once the handler has been created (and, on Android,
/// registered with `AudioService.init`).
final audioHandlerProvider = Provider<CodecoreAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider not overridden'),
);

/// The streamed entries of the queue (negative ids); null where there are none.
final onlineEntriesProvider = Provider<OnlineEntries?>(
  (ref) => ref.watch(audioHandlerProvider).online,
);

final playbackPersistenceProvider = Provider<PlaybackPersistence?>(
  (ref) => null,
);

final playerErrorsProvider = Provider<Stream<PlaybackFailure>>(
  (ref) => const Stream<PlaybackFailure>.empty(),
);

/// Where the current queue came from, shown as «In riproduzione da».
enum PlayContextKind { album, artist, playlist, favorites, library, search, podcast, radio }

class PlayContext {
  const PlayContext(this.kind, [this.name]);

  final PlayContextKind kind;

  /// Album / playlist / artist name; null for the fixed kinds.
  final String? name;
}

class PlayContextNotifier extends Notifier<PlayContext?> {
  @override
  PlayContext? build() => null;

  void set(PlayContext? c) => state = c;
}

/// In memory only: not persisted across launches.
final playContextProvider = NotifierProvider<PlayContextNotifier, PlayContext?>(
  PlayContextNotifier.new,
);

class PlayerController {
  PlayerController(
    this._handler,
    this._persistence, {
    this.onContext,
    this.shufflePlus,
    this.setShufflePlus,
  });

  /// The Shuffle+ flag of the settings, and a way to change it.
  final bool Function()? shufflePlus;
  final void Function(bool)? setShufflePlus;

  final CodecoreAudioHandler _handler;
  final void Function(PlayContext?)? onContext;
  final PlaybackPersistence? _persistence;
  bool _askedNotifications = false;

  /// Only the ids travel to the player; it resolves tracks via the repository.
  Future<void> playFromList(
    List<Track> snapshot,
    int index, {
    PlayContext? context,
  }) async {
    if (snapshot.isEmpty) return;
    onContext?.call(context);
    _handler.setPlayContext(context?.kind.index, context?.name);
    _requestNotificationPermissionOnce();
    await _handler.playQueue([for (final t in snapshot) t.id], index);
  }

  /// Plays a list of radio stations from [index]; next and previous move
  /// between them. Radio leaves no history and no statistics.
  Future<void> playStations(
    List<RadioStation> stations,
    int index, {
    PlayContext? context,
  }) async {
    if (stations.isEmpty) return;
    final ctx = context ?? const PlayContext(PlayContextKind.radio);
    onContext?.call(ctx);
    _handler.setPlayContext(null, null);
    _requestNotificationPermissionOnce();
    await _handler.playStations(stations, index);
  }

  Future<void> togglePlayPause() => _handler.togglePlayPause();
  Future<void> pause() => _handler.pause();
  Future<void> next() => _handler.skipToNext();
  bool get hasNext => _handler.hasNext;
  Future<void> previous() => _handler.skipToPrevious();
  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> jumpToQueueIndex(int index) => _handler.skipToQueueItem(index);
  Future<void> removeFromQueue(int index) => _handler.removeFromQueue(index);
  Future<void> removeTracks(Set<int> ids) => _handler.removeTracks(ids);
  void reorderQueue(int from, int to) {
    _handler.moveInQueue(from, to);
  }

  /// «Svuota»: see [CodecoreAudioHandler.rebuildUpcoming].
  QueueState? rebuildUpcoming() => _handler.rebuildUpcoming();
  bool get hasQueueSource => _handler.hasSource;
  void restoreQueue(QueueState state) => _handler.restoreQueue(state);

  void playNext(int trackId) => _handler.playNext(trackId);
  void addToQueue(int trackId) => _handler.addToQueue(trackId);

  Future<void> setVolume(double v) {
    _persistence?.setVolume(v);
    return _handler.setVolume(v);
  }

  Future<void> toggleShuffle() => _handler.setShuffleMode(
    _handler.shuffleEnabled
        ? AudioServiceShuffleMode.none
        : AudioServiceShuffleMode.all,
  );

  /// The shuffle button: off, then shuffle, then Shuffle+, then off again.
  Future<void> cycleShuffle() async {
    final plus = shufflePlus?.call() ?? false;
    if (!_handler.shuffleEnabled) {
      setShufflePlus?.call(false);
      await setShuffle(true);
    } else if (!plus) {
      setShufflePlus?.call(true);
    } else {
      setShufflePlus?.call(false);
      await setShuffle(false);
    }
  }

  Future<void> setShuffle(bool on) => _handler.setShuffleMode(
    on ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
  );

  Future<void> cycleRepeat() =>
      _handler.setRepeatMode(switch (_handler.repeatMode) {
        PlayRepeat.off => AudioServiceRepeatMode.all,
        PlayRepeat.all => AudioServiceRepeatMode.one,
        PlayRepeat.one => AudioServiceRepeatMode.none,
      });

  void _requestNotificationPermissionOnce() {
    if (_askedNotifications || !isAndroid) return;
    _askedNotifications = true;
    // No activity (the player was started by a widget or a key): no dialog.
    unawaited(Permission.notification.request().then<void>((_) {}, onError: (Object e) {
      AppLog.d('notification permission not asked', e);
    }));
  }
}

final playerControllerProvider = Provider<PlayerController>(
  (ref) => PlayerController(
    ref.watch(audioHandlerProvider),
    ref.watch(playbackPersistenceProvider),
    onContext: (c) => ref.read(playContextProvider.notifier).set(c),
    shufflePlus: () => ref.read(settingsProvider).shufflePlus,
    setShufflePlus: (on) => ref
        .read(settingsProvider.notifier)
        .update((c) => c.copyWith(shufflePlus: on)),
  ),
);

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
      .map(
        (s) => switch (s.repeatMode) {
          AudioServiceRepeatMode.one => PlayRepeat.one,
          AudioServiceRepeatMode.all ||
          AudioServiceRepeatMode.group => PlayRepeat.all,
          AudioServiceRepeatMode.none => PlayRepeat.off,
        },
      )
      .distinct();
});

/// Separate from everything else so only the slider rebuilds on each tick.
final positionProvider = StreamProvider<Duration>(
  (ref) => ref.watch(audioHandlerProvider).positionStream,
);

final durationProvider = StreamProvider<Duration?>(
  (ref) => ref.watch(audioHandlerProvider).durationStream,
);

final queueProvider = StreamProvider<List<Track>>((ref) async* {
  final h = ref.watch(audioHandlerProvider);
  final repo = ref.watch(trackRepositoryProvider);
  final online = ref.watch(onlineEntriesProvider);
  yield await queueTracks(h.queueIds, repo, online);
  await for (final _ in h.queueChanges) {
    yield await queueTracks(h.queueIds, repo, online);
  }
});

class VolumeNotifier extends Notifier<double> {
  double _beforeMute = 1.0;

  @override
  double build() {
    final sub = ref
        .read(audioHandlerProvider)
        .volumeRequests
        .listen((v) => set(v.clamp(0.0, 1.0)));
    ref.onDispose(sub.cancel);
    return ref.read(settingsStoreProvider).readPlayback().volume;
  }

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

final volumeProvider = NotifierProvider<VolumeNotifier, double>(
  VolumeNotifier.new,
);

final playerFailuresProvider = StreamProvider<PlaybackFailure>(
  (ref) => ref.watch(playerErrorsProvider),
);

/// Current track kept in sync with DB edits (favourite flag, title, ...).
final liveCurrentTrackProvider = StreamProvider<Track?>((ref) {
  final id = ref.watch(currentTrackProvider.select((t) => t.value?.id));
  if (id == null) return Stream.value(null);
  // Streamed entries are not rows: the registry's synthetic track.
  if (isOnlineId(id)) return Stream.value(ref.watch(onlineEntriesProvider)?.trackOf(id));
  return ref.watch(trackRepositoryProvider).watchById(id);
});
