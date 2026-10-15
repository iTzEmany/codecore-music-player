import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/app_log.dart';
import '../core/paths.dart';
import '../data/db/app_database.dart';
import '../services/audio/audio_backend.dart';
import '../services/audio/just_audio_backend.dart';
import '../services/jam/jam_cache.dart';
import '../services/jam/jam_guest.dart';
import '../services/jam/jam_host.dart';
import '../services/jam/jam_models.dart';
import '../services/jam/jam_output.dart';
import '../services/share/discovery.dart';
import 'database_providers.dart';
import 'player_providers.dart';
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
  });

  final JamPhase phase;
  final JamRole? role;
  final JamState? jam;
  final String peerName, peerId;

  /// Result of the last request (declined, busy, unreachable...).
  final JamJoinOutcome? outcome;
  final bool lost;

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
  }) =>
      JamUiState(
        phase: phase ?? this.phase,
        role: role ?? this.role,
        jam: jam ?? this.jam,
        peerName: peerName ?? this.peerName,
        peerId: peerId ?? this.peerId,
        outcome: outcome ?? this.outcome,
        lost: lost ?? this.lost,
      );
}

/// Creates the backend used for Jam playback (overridden in tests).
final jamBackendFactoryProvider =
    Provider<AudioBackend Function()>((ref) => JustAudioBackend.new);

final jamCacheDirProvider = FutureProvider<Directory>((ref) async =>
    Directory(p.join(await appSupportDir(), 'jam_cache')));

/// Orchestrates one Jam: protocol (host or guest), playback and cache.
class JamController extends Notifier<JamUiState> {
  JamGuest? _guest;
  JamOutput? _output;
  JamCache? _cache;
  StreamSubscription<void>? _hostSub, _guestSub, _lostSub;
  StreamSubscription<JamRequest>? _reqSub;
  JamRequest? _guestInfo; // host side: the connected guest
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
    hub.onJamAction = (req, accept) => accept ? acceptRequest(req) : decline(req);
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
        phase: JamPhase.requesting, peerName: peer.name, peerId: peer.id);
    await _hold();
    final host = _host, port = _hub.port;
    if (host == null || port == null) {
      await _release();
      state = state.copyWith(
          phase: JamPhase.idle, outcome: JamJoinOutcome.unreachable);
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

  /// Host side: the user accepted [req].
  Future<void> acceptRequest(JamRequest req) async {
    final host = _host;
    if (host == null || state.active) return;
    final s = host.accept(req.id);
    if (s == null) return;
    _guestInfo = req;
    await _hold();
    _hostSub = host.changes.listen((_) {
      final js = host.state;
      if (js != null) _onState(js);
    });
    state = state.copyWith(peerName: req.fromName, peerId: req.fromId);
    await _begin(JamRole.host, s);
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
    _output = JamOutput(
      deviceId: _ownId,
      backend: ref.read(jamBackendFactoryProvider)(),
      resolve: _resolve,
    )
      ..onTrackEnded = (id) {
        send(JamCommand.trackEnded(id));
      }
      ..onItemFailed = _onItemFailed;
    _host?.resolveFile = _localFile;
    state = state.copyWith(phase: JamPhase.active, role: role, jam: s);
    _onState(s);
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
    if (s == null) return null;
    if (state.role == JamRole.guest) {
      final base = _guest?.hostBase, sid = _guest?.sessionId;
      return base == null ? null : Uri.parse('$base/$sid/file/${item.id}');
    }
    final g = _guestInfo, sid = _host?.sessionId;
    if (g == null || sid == null) return null;
    return Uri.parse('http://${g.fromHost}:${g.fromPort}/jam/$sid/file/${item.id}');
  }

  Map<String, String> get _headers => {
        'x-jam-token': (state.role == JamRole.guest
                ? _guest?.sessionToken
                : _host?.sessionToken) ??
            '',
      };

  Future<JamSource?> _resolve(JamItem item) async {
    if (item.ownerDeviceId == _ownId) {
      final path = await _localFile(item);
      return path == null ? null : JamSource.local(path);
    }
    final uri = _remoteUri(item);
    final remote = uri == null ? null : JamSource.remote(uri, _headers);
    final cached = _cache?.sourceFor(item, remote);
    return cached;
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
    final next = nextIdx >= 0 && nextIdx < s.items.length ? s.items[nextIdx] : null;
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
      final err = await send(JamCommand.add(JamItem(
        id: 0,
        ownerDeviceId: _ownId,
        title: t.title,
        artist: t.artist,
        album: t.album,
        durationMs: t.durationMs,
        ext: ext,
        sizeBytes: t.sizeBytes,
        ref: t.id.toString(),
      )));
      if (err == null) added++;
      if (err == JamError.full) break;
    }
    return added;
  }

  Future<void> setOutput(String deviceId) =>
      send(JamCommand.setOutput(deviceId));

  /// Host ends for both; the guest just leaves.
  Future<void> end() async {
    if (state.role == JamRole.host) {
      _host?.endSession();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    await _finish();
  }

  Future<void> _finish({bool lost = false}) async {
    if (state.phase == JamPhase.ended || state.phase == JamPhase.idle) return;
    state = state.copyWith(phase: JamPhase.ended, lost: lost);
    await _teardown();
  }

  Future<void> _teardown({bool release = true}) async {
    await _hostSub?.cancel();
    await _guestSub?.cancel();
    await _lostSub?.cancel();
    _hostSub = _guestSub = _lostSub = null;
    await _output?.dispose();
    _output = null;
    await _cache?.clear();
    _cache = null;
    _host?.resolveFile = null;
    _host?.clearSession();
    final g = _guest;
    _guest = null;
    await g?.dispose();
    _guestInfo = null;
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

final jamProvider =
    NotifierProvider<JamController, JamUiState>(JamController.new);

/// Requests to show as an accept/decline dialog.
final jamRequestsProvider = StreamProvider<JamRequest>(
    (ref) => ref.watch(jamProvider.notifier).incomingRequests);
