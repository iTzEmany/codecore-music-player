import 'dart:async';
import 'dart:io';
import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/app_log.dart';
import '../core/paths.dart';
import '../data/db/app_database.dart';
import '../data/repositories/track_kinds.dart';
import '../data/repositories/track_repository.dart';
import '../services/stream/stream_key.dart';
import '../services/audio/audio_backend.dart';
import '../services/audio/codecore_audio_handler.dart';
import '../services/audio/just_audio_backend.dart';
import '../services/audio/playback_persistence.dart';
import '../services/jam/jam_cache.dart';
import '../services/jam/jam_clock.dart';
import '../services/jam/jam_guest.dart';
import '../services/jam/jam_host.dart';
import '../services/jam/jam_models.dart';
import '../services/jam/jam_online_adder.dart';
import '../services/jam/jam_output.dart';
import '../services/jam/jam_part_feeder.dart';
import '../services/jam/jam_suggestion.dart';
import '../services/jam/jam_state.dart';
import '../services/online/download_index.dart';
import '../services/online/youtube_service.dart' show YtResult;
import '../services/share/track_meta.dart';
import '../services/stream/stream_cache.dart';
import '../services/jam/jam_transport.dart';
import '../services/share/discovery.dart';
import 'database_providers.dart';
import 'library_providers.dart' show coverStoreProvider, libraryQueriesProvider;
import 'online_providers.dart' show creditsRepositoryProvider;
import 'player_providers.dart';
import 'settings_providers.dart';
import 'share_hub.dart';
import 'share_providers.dart';
import 'youtube_providers.dart' show downloadIndexProvider;
import 'stream_providers.dart';

enum JamPhase { idle, requesting, active, ended }

enum JamRole { host, guest }

class JamUiState {
  const JamUiState({
    this.phase = JamPhase.idle,
    this.role,
    this.jam,
    this.peerName = '',
    this.peerId = '',
    this.outcome,
    this.lost = false,
    this.syncErrorMs,
  });

  final JamPhase phase;
  final JamRole? role;
  final JamState? jam;
  final String peerName, peerId;

  /// Result of the last request (declined, busy, unreachable...).
  final JamJoinOutcome? outcome;
  final bool lost;

  /// Last measured offset from the shared position while synchronised (ms).
  final int? syncErrorMs;

  bool get active => phase == JamPhase.active;
  bool get isHost => role == JamRole.host;

  JamUiState copyWith({
    JamPhase? phase,
    JamRole? role,
    JamState? jam,
    String? peerName,
    String? peerId,
    JamJoinOutcome? outcome,
    bool? lost,
    int? syncErrorMs,
  }) => JamUiState(
    phase: phase ?? this.phase,
    role: role ?? this.role,
    jam: jam ?? this.jam,
    peerName: peerName ?? this.peerName,
    peerId: peerId ?? this.peerId,
    outcome: outcome ?? this.outcome,
    lost: lost ?? this.lost,
    syncErrorMs: syncErrorMs ?? this.syncErrorMs,
  );
}

/// Creates the backend used for Jam playback (overridden in tests).
final jamBackendFactoryProvider = Provider<AudioBackend Function()>(
  (ref) => JustAudioBackend.new,
);

final jamCacheDirProvider = FutureProvider<Directory>(
  (ref) async => Directory(p.join(await appSupportDir(), 'jam_cache')),
);

/// Orchestrates one Jam: protocol (host or guest), playback and cache.
/// The queue as it plays out: from the current track to the end, then the
/// ones that came before it. Nothing is dropped.
List<int> rotateQueueFromCurrent(List<int> ids, int currentIndex) {
  if (currentIndex <= 0 || currentIndex >= ids.length) return [...ids];
  return [...ids.sublist(currentIndex), ...ids.sublist(0, currentIndex)];
}

/// The host's local queue, as tracks, to be the Jam's starting queue.
Future<List<Track>> jamSeedTracks(
  CodecoreAudioHandler handler,
  TrackRepository repo,
) async {
  final ids = rotateQueueFromCurrent(handler.queueIds, handler.currentIndex);
  return [
    for (final t in await repo.getByIds(ids))
      if (!t.missing) t,
  ];
}

/// The Jam item of library track [t] owned by [ownId]; null when its format cannot go in a Jam.
JamItem? jamItemOfTrack(Track t, String ownId,
    {bool inherited = false, String? partKey, bool suggested = false}) {
  final ext = p.extension(t.path).replaceFirst('.', '').toLowerCase();
  if (!jamExts.contains(ext)) return null;
  return JamItem(
    id: 0,
    ownerDeviceId: ownId,
    title: t.title,
    artist: t.artist,
    album: t.album,
    durationMs: t.durationMs,
    ext: ext,
    sizeBytes: t.sizeBytes,
    ref: t.id.toString(),
    inherited: inherited,
    suggested: suggested,
    partKey: partKey,
  );
}

const _ytPrefix = 'yt:';

/// The owner's [TrackMeta] of [item] from [uri]; on no answer, 404 or garbage, the
/// basic data the item carries (R-24). Never throws.
Future<TrackMeta> jamFetchMeta(JamItem item, Uri? uri, Map<String, String> headers, {Dio? dio}) async {
  final basic = TrackMeta(title: item.title, artist: item.artist, album: item.album);
  if (uri == null) return basic;
  try {
    final r = await (dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)))).getUri<Object>(uri,
        options: Options(
            headers: headers,
            responseType: ResponseType.json,
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 8)));
    return TrackMeta.tryParse(r.data) ?? basic;
  } on DioException catch (e) {
    AppLog.w('jam: no meta for ${item.title}', e);
    return basic;
  }
}

/// The cache key of an online item's `ref` (`yt:<key>`), else null.
String? jamCacheKey(JamItem i) {
  final r = i.ref;
  return r != null && r.startsWith(_ytPrefix) && r.length > _ytPrefix.length
      ? r.substring(_ytPrefix.length)
      : null;
}

/// The owner-side file of [item]: `yt:<key>` is a cache file, a number a library track
/// (K-07); anything else has none. A `yt:` file that left the cache (downloaded into
/// the library meanwhile) is found through [index].
Future<String?> jamLocalFile(JamItem item, StreamCache cache, TrackRepository tracks,
    {DownloadIndex? index}) async {
  final key = jamCacheKey(item);
  if (key != null) return (await cache.fileFor(key))?.path ?? index?.pathForKey(key);
  final id = int.tryParse(item.ref ?? '');
  return id == null ? null : (await tracks.getById(id))?.path;
}

/// Cache keys of [ownId]'s online items still to play (current and upcoming).
Set<String> jamPinKeys(JamState? s, String ownId) => {
      for (final (n, i) in (s?.items ?? const <JamItem>[]).indexed)
        if (n >= s!.currentIndex && i.ownerDeviceId == ownId) ?jamCacheKey(i),
    };

class JamController extends Notifier<JamUiState> {
  JamGuest? _guest;
  JamOutput? _output;
  JamCache? _cache;
  JamClock? _clock;
  JamTransport? _transport;
  CodecoreAudioHandler? _attachedTo;
  StreamSubscription<void>? _hostSub, _guestSub, _lostSub;
  StreamSubscription<JamRequest>? _reqSub;
  Timer? _alive;
  var _syncLogs = 0;
  var _failures = 0;
  var _held = false;

  /// Our part of «Coda insieme» (R-99): fed into the Jam while the mode is `together`.
  JamPartFeeder? _feeder;

  /// The library ids of our queue from before the Jam: the genres of the suggestions (R-102).
  var _beforeIds = const <int>[];

  /// Our part worked out when the guest presses «Esci», before the host drops our tracks.
  List<int>? _exitPart;

  @visibleForTesting
  JamPartFeeder? get debugFeeder => _feeder;

  @visibleForTesting
  void debugState(JamState s) => _onState(s);
  Map<String, int>? _genres;
  final _random = Random();

  /// Cache keys pinned for the queue (counted pins: the player's own pins add up).
  final _pinned = <String>{};

  /// Keys whose own download failed: not retried on every state change.
  final _selfFailed = <String>{};

  Dio? _dio;
  Dio get _http => _dio ??= Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));

  final _incoming = StreamController<JamRequest>.broadcast();
  final _onlineFailed = StreamController<YtResult>.broadcast();
  JamOnlineAdder? _adder;

  /// Online tracks whose download failed after [addOnline] had accepted them.
  Stream<YtResult> get onlineFailures => _onlineFailed.stream;

  /// Requests to show as a dialog (accept/decline).
  Stream<JamRequest> get incomingRequests => _incoming.stream;

  // Captured in build(): `ref` must not be read while disposing.
  late ShareHubNotifier _hub;

  @override
  JamUiState build() {
    ref.onDispose(_dispose);
    final hub = _hub = ref.read(shareHubProvider.notifier);
    _reqSub = hub.newJamRequests.listen(_incoming.add);
    hub.onJamEnd = end;
    hub.onJamAction = (req, accept) =>
        accept ? acceptRequest(req) : decline(req);
    return const JamUiState();
  }

  Future<void> _dispose() async {
    await _reqSub?.cancel();
    await _teardown(release: false);
    await _incoming.close();
    await _onlineFailed.close();
  }

  String get _ownId => _hub.deviceId ?? '';
  JamHost? get _host => _hub.jamHost;

  // ---- starting ------------------------------------------------------------

  /// Asks [peer] to start a Jam with this device (this device is the guest).
  Future<void> request(Peer peer) async {
    if (state.phase == JamPhase.requesting || state.active) return;
    state = JamUiState(
      phase: JamPhase.requesting,
      peerName: peer.name,
      peerId: peer.id,
    );
    await _hold();
    final host = _host, port = _hub.port;
    if (host == null || port == null) {
      await _release();
      state = state.copyWith(
        phase: JamPhase.idle,
        outcome: JamJoinOutcome.unreachable,
      );
      return;
    }
    final guest = JamGuest(local: host);
    _guest = guest;
    final outcome = await guest.join(
      host: peer.host,
      port: peer.port,
      ownDeviceId: _ownId,
      ownName: ref.read(deviceNameProvider),
      ownPort: port,
    );
    if (outcome != JamJoinOutcome.accepted) {
      _guest = null;
      await guest.dispose();
      await _release();
      state = state.copyWith(phase: JamPhase.idle, outcome: outcome);
      return;
    }
    _lostSub = guest.lost.listen((_) => _finish(lost: true));
    _guestSub = guest.states.listen(_onState);
    await _begin(JamRole.guest, guest.state!);
  }

  void cancelRequest() => _guest?.cancelJoin();

  /// The user accepted [req]: the host admits it directly; a guest forwards
  /// the invitation to the host.
  Future<void> acceptRequest(JamRequest req) async {
    final host = _host;
    if (host == null) return;
    if (state.active) {
      if (state.role == JamRole.host) {
        host.accept(req.id);
      } else if (!await (_guest?.invite(req) ?? Future.value(false))) {
        host.decline(req.id);
      }
      return;
    }
    final s = host.accept(req.id);
    if (s == null) return;
    await _hold();
    _hostSub = host.changes.listen((_) {
      final js = host.state;
      if (js != null) _onState(js);
    });
    state = state.copyWith(peerName: req.fromName, peerId: req.fromId);
    // Read before the Jam pauses the local player: what was queued here
    // becomes the Jam's starting queue.
    final handler = ref.read(audioHandlerProvider);
    final seed = await jamSeedTracks(
      handler,
      ref.read(trackRepositoryProvider),
    );
    final wasPlaying = handler.isPlaying;
    final position = ref.read(positionProvider).value ?? Duration.zero;
    await _begin(JamRole.host, host.state ?? s);
    if (seed.isNotEmpty) {
      // What does not fit in the Jam stays in our part for «Coda insieme» (R-99).
      if (state.active) _startFeeder([for (final t in seed) t.id]);
      final n = await _addTracks(seed, inherited: true, keyed: true);
      AppLog.i('jam: $n of ${seed.length} queued tracks added to the Jam');
      // Music that was playing keeps playing, from the same point.
      if (n > 0 && wasPlaying) {
        if (position > const Duration(seconds: 1)) {
          await send(JamCommand.seek(position.inMilliseconds));
        }
        await send(const JamCommand.play());
      }
    }
  }

  void decline(JamRequest req) => _host?.decline(req.id);

  /// The guest's own queue from before the Jam (R-90); null for a host.
  ({List<int> ids, int index, Duration position})? _saved;
  PlaybackPersistence? _persistence;
  CodecoreAudioHandler? _localHandler;

  /// Keeps the local queue, track and position on disk and in memory.
  @visibleForTesting
  Future<void> saveLocalQueue() async {
    final handler = ref.read(audioHandlerProvider);
    _localHandler = handler;
    // The live position: a paused player emits none, so the stream can be 0.
    final position = handler.playbackState.value.position;
    _saved = (
      ids: List.of(handler.queueIds),
      index: handler.currentIndex < 0 ? 0 : handler.currentIndex,
      position: position,
    );
    await (_persistence = ref.read(playbackPersistenceProvider))
        ?.hold(position);
  }

  /// Puts the queue back as it was, paused, and lets the disk follow again.
  /// A Jam left in «Coda insieme» gives back our part not yet played, from its first
  /// track (D-209); never an empty queue when there was one before (invariant 6).
  Future<void> _restoreLocalQueue() async {
    final s = _saved;
    _saved = null;
    if (s == null) return;
    var (ids, index, position) = (s.ids, s.index, s.position);
    final part = _exitPart ?? _unplayedPart();
    if (part.isNotEmpty) (ids, index, position) = (part, 0, Duration.zero);
    try {
      await _localHandler?.restore(ids, index, position);
    } on Object catch (e, st) {
      AppLog.w('jam: could not restore the local queue', e, st);
    }
    _persistence?.release(position);
    await _persistence?.flush();
    _persistence = null;
  }

  /// Library ids of our part left to play when the Jam was in «Coda insieme»: our items after
  /// the current one, in order, then what the feeder still holds. Online items stay in the
  /// Jam for the host (D-93) and are not part of the queue given back. Empty in «Coda dell'host».
  List<int> _unplayedPart() {
    final js = state.jam, feeder = _feeder;
    if (js == null || feeder == null || js.mode != JamMode.together) return const [];
    final inJam = {
      for (final (n, i) in js.items.indexed)
        if (n > js.currentIndex && i.ownerDeviceId == _ownId) i.partKey,
    };
    return [
      for (final (n, i) in js.items.indexed)
        if (n > js.currentIndex && i.ownerDeviceId == _ownId) ?int.tryParse(i.ref ?? ''),
      for (final k in feeder.unsent)
        if (!inJam.contains(k)) ?jamPartKeyId(k),
    ];
  }

  void _startFeeder(List<int> ids) {
    _beforeIds = ids;
    _genres = null;
    _feeder = JamPartFeeder(
      ownId: _ownId,
      part: jamPartKeys(ids),
      send: _sendResult,
      itemOf: _partItem,
      suggest: _suggestion,
    );
  }

  Future<JamItem?> _partItem(String key) async {
    final id = jamPartKeyId(key);
    final t = id == null ? null : await ref.read(trackRepositoryProvider).getById(id);
    return t == null || t.missing ? null : jamItemOfTrack(t, _ownId, partKey: key);
  }

  /// A track for a part that ran out: by the genres of our queue from before, none played in this Jam.
  Future<JamItem?> _suggestion(JamState s) async {
    final q = ref.read(libraryQueriesProvider);
    final genres = _genres ??= await q.genreCounts(_beforeIds);
    final played = s.items.take(s.currentIndex + 1);
    final ids = {
      for (final i in played)
        if (i.ownerDeviceId == _ownId) ?int.tryParse(i.ref ?? ''),
    };
    final titles = {for (final i in played) suggestionKey(i.title, i.artist)};
    final t = await pickSuggestion<Track>(
      genreWeights: genres,
      random: _random,
      candidates: (g) async => [
        for (final t in await q.randomTracks(genre: g))
          if (jamItemOfTrack(t, _ownId) != null) t,
      ],
      isPlayed: (t) => ids.contains(t.id) || titles.contains(suggestionKey(t.title, t.artist)),
    );
    return t == null ? null : jamItemOfTrack(t, _ownId, suggested: true);
  }

  @visibleForTesting
  Future<void> debugFinish({bool lost = false}) => _finish(lost: lost);

  @visibleForTesting
  Future<void> debugBegin(JamRole role, JamState s) => _begin(role, s);

  Future<void> _begin(JamRole role, JamState s) async {
    if (role == JamRole.guest) await saveLocalQueue();
    // Lost or ended while saving: _finish already tore everything down.
    if (state.phase == JamPhase.ended) return;
    final saved = _saved;
    if (role == JamRole.guest && saved != null) {
      _startFeeder(rotateQueueFromCurrent(saved.ids, saved.index));
    } else if (role == JamRole.host) {
      _startFeeder(const []); // an empty queue still gets suggestions (R-102); the seed replaces it
    }
    try {
      await _beginJam(role, s);
    } on Object catch (e, st) {
      // Do not leave the disk held for the whole session.
      AppLog.w('jam: start failed', e, st);
      state = state.copyWith(phase: JamPhase.ended, lost: true);
      await _teardown();
      rethrow;
    }
  }

  Future<void> _beginJam(JamRole role, JamState s) async {
    // Local playback yields to the Jam.
    try {
      await ref.read(audioHandlerProvider).pause();
    } on Object catch (e) {
      AppLog.d('jam: could not pause local player', e);
    }
    if (state.phase == JamPhase.ended) return;
    final dir = await ref.read(jamCacheDirProvider.future);
    if (state.phase == JamPhase.ended) return;
    final cache = JamCache(dir);
    await cache.clear();
    if (state.phase == JamPhase.ended) return;
    _cache = cache;
    _failures = 0;
    final clock = _clock = _makeClock(role);
    _output =
        JamOutput(
            deviceId: _ownId,
            backend: ref.read(jamBackendFactoryProvider)(),
            resolve: _resolve,
            clock: clock,
            latencyMs: ref.read(settingsProvider).jamLatencyMs,
          )
          ..onSyncError = (e) {
            if (!state.active) return;
            state = state.copyWith(syncErrorMs: e);
            if (++_syncLogs % 10 == 0) {
              AppLog.i(
                'jam sync: error ${e}ms, clock offset '
                '${_clock?.offsetMs}ms (rtt ${_clock?.rttMs}ms)',
              );
            }
          }
          ..onTrackEnded = (id) {
            send(JamCommand.trackEnded(id));
          }
          ..onItemFailed = _onItemFailed;
    _host?.resolveFile = _localFile;
    _host?.resolveMeta = _localMeta;
    _host?.resolveCover = _localCover;
    // The notification and the lock screen now speak for the Jam.
    final handler = ref.read(audioHandlerProvider);
    _attachedTo = handler;
    final transport = _transport = JamTransport(
      send: send,
      nowMs: jamNowMs,
    );
    handler.attachRemote(transport);
    state = state.copyWith(phase: JamPhase.active, role: role, jam: s);
    if (role == JamRole.host) {
      // A guest that vanished (crash, Wi-Fi off) must not keep the Jam open.
      _alive = Timer.periodic(const Duration(seconds: 10), (_) {
        _host?.dropStale(const Duration(seconds: 75));
        final js = _host?.state;
        if (js != null) _onState(js);
      });
    }
    _onState(s);
  }

  /// Reference clock: the host's own for a host, estimated for a guest.
  JamClock _makeClock(JamRole role) {
    if (role == JamRole.host) {
      return JamClock(
        probe: () async => null,
        localNowMs: () => DateTime.now().millisecondsSinceEpoch,
      );
    }
    late final JamClock c;
    c = JamClock(probe: () async => _guest?.probeHostTime(c.localNowMs));
    unawaited(c.sync().then((_) => c.start()));
    return c;
  }

  /// Latency compensation changed in the settings.
  void setLatencyMs(int ms) {
    final v = ms.clamp(-500, 1000);
    ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(jamLatencyMs: v));
    _output?.latencyMs = v;
  }

  // ---- state & playback ----------------------------------------------------

  void _onState(JamState s) {
    if (state.phase != JamPhase.active) return;
    // Leaving: the part to give back is already worked out; a late state without our tracks is ignored.
    if (_exitPart != null) return;
    state = state.copyWith(jam: s);
    _transport?.update(s);
    if (s.ended) {
      unawaited(_finish());
      return;
    }
    unawaited(_output?.apply(s));
    _precache(s);
    _syncPins(s);
    _adder?.seen(s.items);
    unawaited(_feeder?.update(s));
  }

  void _onItemFailed(int id) {
    _failures++;
    if (_failures > 3) {
      send(const JamCommand.pause());
      return;
    }
    send(JamCommand.trackEnded(id)); // skip to the next one
  }

  Uri? _remoteUri(JamItem item, {String route = 'file'}) {
    final s = state.jam;
    final sid = state.role == JamRole.guest
        ? _guest?.sessionId
        : _host?.sessionId;
    if (s == null || sid == null) return null;
    final owner = s.participant(item.ownerDeviceId);
    if (owner == null) return null;
    // The host is reached at the address a guest used to join; a guest at
    // the one the host saw for it.
    String? base;
    if (owner.id == s.hostDeviceId) {
      base = state.role == JamRole.guest ? _guest?.hostBase : null;
    } else if (owner.host.isNotEmpty) {
      base = 'http://${owner.host}:${owner.port}/jam';
    }
    return base == null ? null : Uri.parse('$base/$sid/$route/${item.id}');
  }

  Map<String, String> get _headers => {
    jamFileHeader:
        (state.role == JamRole.guest ? _guest?.fileToken : _host?.fileToken) ??
        '',
  };

  Future<JamSource?> _resolve(JamItem item) async {
    if (item.ownerDeviceId == _ownId) {
      final path = await _localFile(item);
      return path == null ? null : JamSource.local(path);
    }
    final uri = _remoteUri(item);
    final remote = uri == null ? null : JamSource.remote(uri, _headers);
    // Synchronised outputs play from the local copy: no network jitter.
    if (uri != null && (state.jam?.synced ?? false) && _cache != null) {
      await _cache!.fetch(item, uri, _headers);
    }
    // Owner gone or not answering: an online track comes from its YouTube id.
    final sj = state.jam;
    if (sj != null && uri == null) {
      final own = await _selfFetch(item);
      if (own != null) return JamSource.local(own.path);
    }
    return _cache?.sourceFor(item, remote);
  }

  /// The row of an item this device owns: library, or the shadow row of a `yt:` track.
  /// Full rows: lyrics and curiosities are there.
  Future<Track?> _localRow(JamItem item) async {
    final tracks = ref.read(trackRepositoryProvider);
    final key = jamCacheKey(item);
    final id = int.tryParse(item.ref ?? '');
    if (key != null) {
      final path = (await ref.read(downloadIndexProvider.future)).pathForKey(key);
      return await tracks.streamRow(key) ?? (path == null ? null : await tracks.byPath(path));
    }
    return id == null
        ? null
        : tracks.getById(id);
  }

  Future<TrackMeta?> _localMeta(JamItem item) async {
    final row = await _localRow(item);
    if (row == null) return null;
    final c = await ref.read(creditsRepositoryProvider).portableOf(row.id);
    return TrackMeta.fromTrack(row, credits: c.credits, details: c.details);
  }

  Future<String?> _localCover(JamItem item) async {
    final key = (await _localRow(item))?.coverKey;
    return key == null ? null : ref.read(coverStoreProvider).fileFor(key)?.path;
  }

  /// The owner's cover image, or null (ours: the screen has it locally; any failure: no cover).
  Future<Uint8List?> fetchCover(JamItem item) async {
    final uri = item.ownerDeviceId == _ownId ? null : _remoteUri(item, route: 'cover');
    if (uri == null) return null;
    try {
      final r = await _http.getUri<List<int>>(uri,
          options: Options(
              headers: _headers,
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(seconds: 8)));
      final d = r.data;
      return d == null ? null : Uint8List.fromList(d);
    } on DioException catch (e) {
      AppLog.w('jam: no cover for ${item.title}', e);
      return null;
    }
  }

  /// What the info screen shows: from the owner (ours: local), else the item's own fields.
  Future<TrackMeta> fetchMeta(JamItem item) async {
    if (item.ownerDeviceId == _ownId) {
      return await _localMeta(item) ??
          TrackMeta(title: item.title, artist: item.artist, album: item.album);
    }
    return jamFetchMeta(item, _remoteUri(item, route: 'meta'), _headers, dio: _http);
  }

  Future<File?> _selfFetch(JamItem item) {
    if (!item.selfFetchable) return Future.value();
    return jamFetchByVideoId(item, (k, r) => ref.read(streamPreparerProvider).ready(k, r));
  }

  Future<String?> _localFile(JamItem item) async => jamLocalFile(
      item, ref.read(streamCacheProvider), ref.read(trackRepositoryProvider),
      index: await ref.read(downloadIndexProvider.future));

  /// Our own online items still to play (current and upcoming) stay in the cache (D-81).
  void _syncPins(JamState? s) {
    final want = jamPinKeys(s, _ownId);
    if (want.isEmpty && _pinned.isEmpty) return; // no cache needed in a library-only Jam
    final cache = ref.read(streamCacheProvider);
    for (final k in _pinned.difference(want)) {
      cache.unpin(k);
    }
    for (final k in want.difference(_pinned)) {
      cache.pin(k);
    }
    _pinned
      ..clear()
      ..addAll(want);
  }

  /// Next remote item goes to the cache; everything else is dropped.
  void _precache(JamState s) {
    final cache = _cache;
    if (cache == null) return;
    final keep = <int>{};
    final cur = s.current;
    final nextIdx = s.currentIndex + 1;
    final next = nextIdx >= 0 && nextIdx < s.items.length
        ? s.items[nextIdx]
        : null;
    for (final i in [cur, next]) {
      if (i == null) continue;
      keep.add(i.id);
    }
    unawaited(cache.prune(keep));
    for (final i in jamSelfFetchTargets(s, _ownId, failed: _selfFailed)) {
      unawaited(_selfFetch(i).then((f) {
        if (f == null) _selfFailed.add(jamCacheKey(i)!);
      }));
    }
    for (final i in [cur, next]) {
      if (i == null || i.ownerDeviceId == _ownId) continue;
      final uri = _remoteUri(i);
      if (uri != null) unawaited(cache.fetch(i, uri, _headers));
    }
  }

  // ---- commands ------------------------------------------------------------

  Future<JamError?> send(JamCommand cmd) async {
    if (!state.active) return JamError.ended;
    // Removing our own fed track takes it out of our part for good (R-100): before the
    // new state reaches the feeder, which would see it as lost.
    final key = _ownPartKey(cmd);
    if (key != null) _feeder?.forget(key);
    return (await _dispatch(cmd))?.error;
  }

  Future<JamResult?> _dispatch(JamCommand cmd) async =>
      state.role == JamRole.host ? _host?.apply(cmd) : await _guest?.send(cmd);

  Future<JamResult> _sendResult(JamCommand cmd) async {
    if (!state.active) return const JamResult.fail(JamError.ended);
    return await _dispatch(cmd) ?? const JamResult.fail(JamError.notFound);
  }

  /// The part key of our own item that [cmd] removes, if any.
  String? _ownPartKey(JamCommand cmd) {
    if (cmd.type != JamCommandType.remove) return null;
    final i = state.jam?.items.where((i) => i.id == cmd.itemId).firstOrNull;
    return i?.ownerDeviceId == _ownId ? i?.partKey : null;
  }

  @visibleForTesting
  // ignore: use_setters_to_change_properties
  void debugSetClock(JamClock c) => _clock = c;

  /// The Jam's reference clock (the host's), the one `JamState.positionAt` is on.
  int jamNowMs() => _clock?.jamNowMs() ?? DateTime.now().millisecondsSinceEpoch;

  /// The host decides (R-95); a host from before `previous` answers `invalid`
  /// and we fall back to the rule on our own state.
  Future<JamError?> _previousOrFallback(JamState s) async {
    final e = await send(const JamCommand.previous());
    return e == JamError.invalid ? send(jamPreviousCommand(s, jamNowMs())) : e;
  }

  /// «Previous» as in the player (D-160): restart, or the item before.
  Future<JamError?> previous() {
    final s = state.jam;
    if (s == null) return Future.value(JamError.ended);
    return _previousOrFallback(s);
  }

  /// Library ids to the shared queue; a shadow row (`stream:` path, no extension) goes as an online result.
  Future<void> addLibraryIds(List<int> ids) async {
    try {
      final files = <Track>[];
      for (final t in await ref.read(trackRepositoryProvider).getByIds(ids)) {
        final key = t.kind == kStreamKind ? keyOfStreamPath(t.path) : null;
        if (key == null) {
          files.add(t);
        } else {
          addOnline(streamResultOfRow(key, t));
        }
      }
      await addTracks(files);
    } on Object catch (e, st) {
      AppLog.w('jam: could not queue $ids', e, st);
    }
  }

  /// Adds library tracks, owned by this device, to the shared queue.
  Future<int> addTracks(List<Track> tracks, {bool inherited = false}) =>
      _addTracks(tracks, inherited: inherited);

  /// [keyed]: each track carries its part key (the host's seed, see [jamPartKeys]).
  Future<int> _addTracks(List<Track> tracks, {bool inherited = false, bool keyed = false}) async {
    var added = 0;
    final keys = keyed ? jamPartKeys(tracks.map((t) => t.id)) : null;
    for (final (n, t) in tracks.indexed) {
      final item = jamItemOfTrack(t, _ownId, inherited: inherited, partKey: keys?[n]);
      if (item == null) continue;
      final err = await send(JamCommand.add(item));
      if (err == null) added++;
      if (err == JamError.full) break;
    }
    return added;
  }

  /// Accepts [r] for the shared queue right away (false: no Jam). It is added when its
  /// file is ready, in the order of the calls; a failed download goes to [onlineFailures].
  bool addOnline(YtResult r) {
    if (!state.active) return false;
    (_adder ??= JamOnlineAdder(
      ownId: _ownId,
      cache: ref.read(streamCacheProvider),
      ready: (key, r) => ref.read(streamPreparerProvider).ready(key, r),
      send: send,
      onFailed: _onlineFailed.add,
    )).add(r);
    return true;
  }

  Future<void> setOutput(String deviceId) =>
      send(JamCommand.setOutput(deviceId));

  /// Turns [deviceId] on or off as an output (at least one stays on).
  Future<void> toggleOutput(String deviceId) {
    final now = state.jam?.outputs ?? const <String>[];
    final next = now.contains(deviceId)
        ? now.where((d) => d != deviceId).toList()
        : [...now, deviceId];
    if (next.isEmpty) return Future.value();
    return send(
      next.length == 1
          ? JamCommand.setOutput(next.first)
          : JamCommand.setOutputs(next),
    );
  }

  /// Host ends for both; the guest just leaves.
  Future<void> end() async {
    if (state.role == JamRole.host) {
      _host?.endSession();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } else {
      _exitPart = _unplayedPart();
      await _guest?.leave();
    }
    await _finish();
  }

  Future<void> _finish({bool lost = false}) async {
    if (state.phase == JamPhase.ended || state.phase == JamPhase.idle) return;
    state = state.copyWith(phase: JamPhase.ended, lost: lost);
    await _teardown();
  }

  Future<void> _teardown({bool release = true}) async {
    _alive?.cancel();
    _alive = null;
    await _hostSub?.cancel();
    await _guestSub?.cancel();
    await _lostSub?.cancel();
    _hostSub = _guestSub = _lostSub = null;
    _clock?.stop();
    _clock = null;
    // Give the system controls back to the local player.
    _attachedTo?.attachRemote(null);
    _attachedTo = null;
    _feeder?.dispose();
    // Not while the app itself is going away: the saved queue stays on disk.
    if (release) await _restoreLocalQueue();
    _feeder = null;
    _beforeIds = const [];
    _genres = null;
    _exitPart = null;
    await _transport?.dispose();
    _transport = null;
    await _output?.dispose();
    _output = null;
    await _cache?.clear();
    _cache = null;
    _adder?.dispose();
    _adder = null;
    _syncPins(null);
    _selfFailed.clear();
    _dio?.close();
    _dio = null;
    _host?.resolveFile = null;
    _host?.resolveMeta = null;
    _host?.resolveCover = null;
    _host?.clearSession();
    final g = _guest;
    _guest = null;
    await g?.dispose();
    if (release) await _release();
  }

  Future<void> _hold() async {
    if (_held) return;
    _held = true;
    await _hub.holdJam();
  }

  Future<void> _release() async {
    if (!_held) return;
    _held = false;
    if (ref.mounted) await _hub.releaseJam();
  }

  /// Back to idle after the "ended" screen was shown.
  void reset() {
    if (state.phase == JamPhase.ended) state = const JamUiState();
  }
}

/// The cover bytes of another device's queue item [id] (null: show the placeholder).
final jamTrackCoverProvider = FutureProvider.autoDispose.family<Uint8List?, int>((ref, id) {
  final item = ref.read(jamProvider).jam?.items.where((i) => i.id == id).firstOrNull;
  return item == null ? Future.value() : ref.read(jamProvider.notifier).fetchCover(item);
});

/// The meta of the queue item [id] for the info screen (47.6).
final jamTrackMetaProvider = FutureProvider.autoDispose.family<TrackMeta, int>((ref, id) {
  final ctrl = ref.read(jamProvider.notifier);
  final item = ref.read(jamProvider).jam?.items.where((i) => i.id == id).firstOrNull;
  return item == null ? Future.value(const TrackMeta()) : ctrl.fetchMeta(item);
});

final jamProvider = NotifierProvider<JamController, JamUiState>(
  JamController.new,
);

/// Online tracks the Jam accepted but could not download or add.
final jamOnlineFailuresProvider = StreamProvider<YtResult>(
  (ref) => ref.watch(jamProvider.notifier).onlineFailures,
);

/// Requests to show as an accept/decline dialog.
final jamRequestsProvider = StreamProvider<JamRequest>(
  (ref) => ref.watch(jamProvider.notifier).incomingRequests,
);
