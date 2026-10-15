import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/app_log.dart';
import '../core/paths.dart';
import '../data/db/app_database.dart';
import '../data/repositories/track_repository.dart';
import '../services/audio/audio_backend.dart';
import '../services/audio/codecore_audio_handler.dart';
import '../services/audio/just_audio_backend.dart';
import '../services/jam/jam_cache.dart';
import '../services/jam/jam_clock.dart';
import '../services/jam/jam_guest.dart';
import '../services/jam/jam_host.dart';
import '../services/jam/jam_models.dart';
import '../services/jam/jam_output.dart';
import '../services/share/discovery.dart';
import 'database_providers.dart';
import 'player_providers.dart';
import 'settings_providers.dart';
import 'share_hub.dart';
import 'share_providers.dart';

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

class JamController extends Notifier<JamUiState> {
  JamGuest? _guest;
  JamOutput? _output;
  JamCache? _cache;
  JamClock? _clock;
  StreamSubscription<void>? _hostSub, _guestSub, _lostSub;
  StreamSubscription<JamRequest>? _reqSub;
  Timer? _alive;
  var _syncLogs = 0;
  var _failures = 0;
  var _held = false;

  final _incoming = StreamController<JamRequest>.broadcast();

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
      final n = await addTracks(seed);
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

  Future<void> _begin(JamRole role, JamState s) async {
    // Local playback yields to the Jam.
    try {
      await ref.read(audioHandlerProvider).pause();
    } on Object catch (e) {
      AppLog.d('jam: could not pause local player', e);
    }
    final dir = await ref.read(jamCacheDirProvider.future);
    _cache = JamCache(dir);
    await _cache!.clear();
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
    state = state.copyWith(jam: s);
    if (s.ended) {
      unawaited(_finish());
      return;
    }
    unawaited(_output?.apply(s));
    _precache(s);
  }

  void _onItemFailed(int id) {
    _failures++;
    if (_failures > 3) {
      send(const JamCommand.pause());
      return;
    }
    send(JamCommand.trackEnded(id)); // skip to the next one
  }

  Uri? _remoteUri(JamItem item) {
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
    return base == null ? null : Uri.parse('$base/$sid/file/${item.id}');
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
    return _cache?.sourceFor(item, remote);
  }

  Future<String?> _localFile(JamItem item) async {
    final id = int.tryParse(item.ref ?? '');
    if (id == null) return null;
    final track = await ref.read(trackRepositoryProvider).getById(id);
    return track?.path;
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
    for (final i in [cur, next]) {
      if (i == null || i.ownerDeviceId == _ownId) continue;
      final uri = _remoteUri(i);
      if (uri != null) unawaited(cache.fetch(i, uri, _headers));
    }
  }

  // ---- commands ------------------------------------------------------------

  Future<JamError?> send(JamCommand cmd) async {
    if (!state.active) return JamError.ended;
    if (state.role == JamRole.host) {
      final r = _host?.apply(cmd);
      return r?.error;
    }
    final r = await _guest?.send(cmd);
    return r?.error;
  }

  /// Adds library tracks, owned by this device, to the shared queue.
  Future<int> addTracks(List<Track> tracks) async {
    var added = 0;
    for (final t in tracks) {
      final ext = p.extension(t.path).replaceFirst('.', '').toLowerCase();
      if (!jamExts.contains(ext)) continue;
      final err = await send(
        JamCommand.add(
          JamItem(
            id: 0,
            ownerDeviceId: _ownId,
            title: t.title,
            artist: t.artist,
            album: t.album,
            durationMs: t.durationMs,
            ext: ext,
            sizeBytes: t.sizeBytes,
            ref: t.id.toString(),
          ),
        ),
      );
      if (err == null) added++;
      if (err == JamError.full) break;
    }
    return added;
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
    await _output?.dispose();
    _output = null;
    await _cache?.clear();
    _cache = null;
    _host?.resolveFile = null;
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

final jamProvider = NotifierProvider<JamController, JamUiState>(
  JamController.new,
);

/// Requests to show as an accept/decline dialog.
final jamRequestsProvider = StreamProvider<JamRequest>(
  (ref) => ref.watch(jamProvider.notifier).incomingRequests,
);
