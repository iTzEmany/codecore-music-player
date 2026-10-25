import 'dart:async';
import 'dart:math';

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
import '../services/online/youtube_service.dart';
import 'youtube_providers.dart' show downloadIndexProvider;
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
    this.libraryIdOf,
    Random? random,
  }) : _random = random ?? Random();

  final Random _random;

  /// The Shuffle+ flag of the settings, and a way to change it.
  final bool Function()? shufflePlus;
  final void Function(bool)? setShufflePlus;

  /// The library track already holding [YtResult] (a download), if any.
  final Future<int?> Function(YtResult)? libraryIdOf;

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

  /// The list's Play button: from a random track when shuffle is on (the
  /// queue keeps it first and shuffles the rest), else from the first.
  Future<void> playAll(List<Track> snapshot, {PlayContext? context}) =>
      playFromList(
        snapshot,
        _handler.shuffleEnabled && snapshot.isNotEmpty
            ? _random.nextInt(snapshot.length)
            : 0,
        context: context,
      );

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

  /// The queue id of [r]: its library track when downloaded (D-81), else a
  /// new online entry; null without an online registry.
  Future<int?> _idOf(YtResult r) async =>
      await libraryIdOf?.call(r) ?? _handler.online?.register(r);

  /// Plays [id] alone, with the search context (empty queue, or radio: no stations to insert among).
  Future<void> _playAlone(int id) {
    onContext?.call(const PlayContext(PlayContextKind.search));
    _handler.setPlayContext(PlayContextKind.search.index, null);
    _requestNotificationPermissionOnce();
    return _handler.playQueue([id], 0);
  }

  Future<int?> _idOrLog(YtResult r) async {
    final int? id;
    try {
      id = await _idOf(r);
    } on Object catch (e, st) {
      AppLog.w('online play ignored: lookup failed for ${r.indexKey}', e, st);
      return null;
    }
    if (id == null) AppLog.w('online play ignored: no online registry');
    return id;
  }

  /// Tap on an online result: plays it right after the current track (R-01).
  /// A library id already in the queue appears twice (accepted).
  /// shortcut: with a Jam active the UI routes taps (D-89, phase 47); here local only.
  Future<void> playOnline(YtResult r) async {
    final id = await _idOrLog(r);
    if (id == null) return;
    if (_handler.queueIds.isEmpty || _handler.isRadio) return _playAlone(id);
    _requestNotificationPermissionOnce();
    final at = _handler.currentIndex + 1;
    _handler.insertAt(at, id);
    await _handler.skipToQueueItem(at);
  }

  Future<void> enqueueOnline(YtResult r) async {
    final id = await _idOrLog(r);
    if (id == null) return;
    if (_handler.isRadio) return _playAlone(id);
    _handler.addToQueue(id);
  }

  Future<void> playOnlineNext(YtResult r) async {
    final id = await _idOrLog(r);
    if (id == null) return;
    if (_handler.isRadio) return _playAlone(id);
    _handler.playNext(id);
  }

  /// Plays [list] in order; [shuffle] turns plain shuffle on (else off), never Shuffle+ (R-18).
  Future<void> playOnlineList(List<YtResult> list, {bool shuffle = false}) async {
    if (list.isEmpty) return;
    final ids = <int>[];
    try {
      for (final r in list) {
        ids.add((await _idOf(r))!);
      }
    } on Object catch (e, st) {
      AppLog.w('online list not played', e, st);
      return;
    }
    onContext?.call(const PlayContext(PlayContextKind.search));
    _handler.setPlayContext(PlayContextKind.search.index, null);
    _requestNotificationPermissionOnce();
    await _handler.playQueue(ids, 0);
    // After playQueue: it would shuffle the upcoming of a shuffle already on.
    setShufflePlus?.call(false);
    await setShuffle(shuffle);
  }

  Future<void> setVolume(double v) {
    _persistence?.setVolume(v);
    return _handler.setVolume(v);
  }

  /// The shuffle button of a list: on or off, never starts playback.
  Future<void> toggleShuffle() {
    final on = !_handler.shuffleEnabled;
    if (!on) setShufflePlus?.call(false);
    return setShuffle(on);
  }

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
    libraryIdOf: (r) async {
      final path = (await ref.read(downloadIndexProvider.future))
          .pathFor(r.id, source: r.source);
      return path == null ? null : ref.read(trackRepositoryProvider).idForPath(path);
    },
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

/// A stream is loading (R-02): a bool of its own, so nothing rebuilds for the download progress (K-03).
final streamLoadingProvider = StreamProvider<bool>((ref) {
  final h = ref.watch(audioHandlerProvider);
  return h.playbackState.map((_) => h.loadingStream).distinct();
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
final liveCurrentTrackProvider = StreamProvider<Track?>((ref) async* {
  final id = ref.watch(currentTrackProvider.select((t) => t.value?.id));
  if (id == null) {
    yield null;
    return;
  }
  final repo = ref.watch(trackRepositoryProvider);
  if (!isOnlineId(id)) {
    yield* repo.watchById(id);
    return;
  }
  // A streamed entry shows its synthetic track until the preparer makes the
  // shadow row; then the row's data (lyrics and trivia appear as enrichment
  // ends) under the entry's own negative id, so the online menus and cover keep working.
  final entries = ref.watch(onlineEntriesProvider);
  yield entries?.trackOf(id);
  final entry = entries?.entryOf(id);
  if (entries == null || entry == null) return;
  final rowIds = entry.trackId != null
      ? Stream.value(entry.trackId!)
      : entries.bound
          .where((i) => i == id)
          .take(1)
          .map((_) => entries.entryOf(id)?.trackId)
          .where((r) => r != null)
          .cast<int>();
  yield* rowIds.asyncExpand((r) => repo.watchById(r).map((t) => t?.copyWith(id: id)));
});
