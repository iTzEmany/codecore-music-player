import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/app_log.dart';
import '../data/db/app_database.dart';
import '../services/share/discovery.dart';
import '../services/share/lan_client.dart';
import '../services/share/offers.dart';
import 'database_providers.dart';
import 'library_providers.dart';
import 'settings_providers.dart';
import 'share_providers.dart';
import 'youtube_providers.dart';

class ShareHubState {
  const ShareHubState({
    this.active = false,
    this.peers = const [],
    this.incoming = const [],
    this.outgoing = const [],
    this.error,
  });

  final bool active;
  final List<Peer> peers;
  final List<IncomingOffer> incoming;
  final List<OutgoingOffer> outgoing;
  final LanError? error;

  ShareHubState copyWith({
    bool? active,
    List<Peer>? peers,
    List<IncomingOffer>? incoming,
    List<OutgoingOffer>? outgoing,
    LanError? error,
    bool clearError = false,
  }) =>
      ShareHubState(
        active: active ?? this.active,
        peers: peers ?? this.peers,
        incoming: incoming ?? this.incoming,
        outgoing: outgoing ?? this.outgoing,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Owns the offer endpoint and the discovery beacon. It runs while someone
/// needs it (Share screen open, "receive from LAN" on) or an outgoing offer
/// is still open, so the sender can leave the screen.
class ShareHubNotifier extends Notifier<ShareHubState> {
  OfferService? _service;
  OfferNode? _node;
  LanDiscovery? _discovery;
  StreamSubscription<List<Peer>>? _peerSub;
  StreamSubscription<void>? _changeSub;
  Timer? _sweep;
  int _users = 0;
  bool _starting = false;
  final _cancels = <String, CancelToken>{};
  final _newIncoming = StreamController<IncomingOffer>.broadcast();

  /// New pending offers (the shell turns them into a dialog).
  Stream<IncomingOffer> get newIncoming => _newIncoming.stream;

  @override
  ShareHubState build() {
    ref.onDispose(_teardown);
    return const ShareHubState();
  }

  Future<void> enter() async {
    _users++;
    await _ensureRunning();
  }

  Future<void> leave() async {
    if (_users > 0) _users--;
    _maybeStop();
  }

  Future<void> _ensureRunning() async {
    if (_node?.running == true || _starting) return;
    _starting = true;
    try {
      final store = ref.read(settingsStoreProvider);
      final service = OfferService(
        deviceId: await store.deviceId(),
        deviceName: ref.read(deviceNameProvider),
      )..onIncoming = (o) {
          _publish();
          _newIncoming.add(o);
        };
      final node = OfferNode(service);
      final port = await node.start();
      final discovery = LanDiscovery(
        deviceId: service.deviceId,
        deviceName: service.deviceName,
      );
      await discovery.start(port);
      if (!ref.mounted) {
        await discovery.dispose();
        await node.stop();
        service.dispose();
        return;
      }
      _service = service;
      _node = node;
      _discovery = discovery;
      _peerSub = discovery.peers.listen((_) => _publish());
      _changeSub = service.changes.listen((_) {
        _publish();
        _maybeStop();
      });
      _sweep = Timer.periodic(const Duration(seconds: 5), (_) {
        service.expire();
        _publish();
        _maybeStop();
      });
      state = state.copyWith(active: true, clearError: true);
      _publish();
    } on Object catch (e, st) {
      AppLog.e('share hub start failed', e, st);
      await _shutdown();
    } finally {
      _starting = false;
    }
  }

  void _publish() {
    final s = _service;
    if (s == null || !ref.mounted) return;
    state = state.copyWith(
      peers: _discovery?.current ?? const [],
      incoming: s.incoming.values.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt)),
      outgoing: s.outgoing.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  bool get _busy {
    final s = _service;
    if (s == null) return false;
    return s.hasOpenOutgoing || _cancels.isNotEmpty;
  }

  void _maybeStop() {
    if (!ref.mounted) return;
    final wantsOn =
        _users > 0 || ref.read(settingsProvider).receiveFromLan || _busy;
    if (!wantsOn && _node != null) unawaited(_shutdown());
  }

  Future<void> _shutdown() async {
    await _teardown();
    if (ref.mounted) state = const ShareHubState();
  }

  /// Stops sockets and timers; safe to call from `onDispose` (touches no state).
  Future<void> _teardown() async {
    _sweep?.cancel();
    _sweep = null;
    await _peerSub?.cancel();
    await _changeSub?.cancel();
    _peerSub = _changeSub = null;
    await _discovery?.dispose();
    await _node?.stop();
    _service?.dispose();
    _discovery = null;
    _node = null;
    _service = null;
  }

  // ---- sending -------------------------------------------------------------

  /// Sends an offer (metadata only) to [peer]. Returns false if delivery fails.
  Future<bool> sendOffer(Peer peer, List<Track> tracks) async {
    await _ensureRunning();
    final service = _service;
    final node = _node;
    if (service == null || node == null || node.port == null) return false;
    final entries = await buildShareEntries(ref, tracks);
    if (entries.isEmpty) return false;
    final offer = service.createOutgoing(
        toId: peer.id, toName: peer.name, entries: entries);
    try {
      await ref.read(lanClientProvider).sendOffer(
          peer.host, peer.port, service.offerPayload(offer, node.port!));
      _publish();
      return true;
    } on LanException catch (e) {
      offer.status = OfferStatus.failed;
      state = state.copyWith(error: e.error);
      service.notify();
      return false;
    }
  }

  Future<void> cancelOutgoing(OutgoingOffer offer, Peer? peer) async {
    if (!offer.open) return;
    offer.status = OfferStatus.cancelled;
    _service?.notify();
    if (peer != null) {
      try {
        await ref
            .read(lanClientProvider)
            .offerAction(peer.host, peer.port, offer.offerId, 'cancel', offer.token);
      } on LanException {
        // The receiver may be gone; the offer is closed on our side anyway.
      }
    }
  }

  // ---- receiving -----------------------------------------------------------

  Future<void> decline(IncomingOffer o) async {
    o.status = OfferStatus.declined;
    _service?.notify();
    try {
      await ref
          .read(lanClientProvider)
          .offerAction(o.fromHost, o.fromPort, o.offerId, 'decline', o.token);
    } on LanException catch (e) {
      AppLog.w('decline not delivered: $e');
    }
  }

  Future<void> accept(IncomingOffer o) async {
    if (o.status != OfferStatus.pending) return;
    final client = ref.read(lanClientProvider);
    try {
      await client.offerAction(
          o.fromHost, o.fromPort, o.offerId, 'accept', o.token);
    } on LanException catch (e) {
      AppLog.w('offer accept failed: $e');
      o.status = OfferStatus.failed;
      state = state.copyWith(error: e.error);
      _service?.notify();
      return;
    }
    o.status = OfferStatus.accepted;
    _service?.notify();
    final cancel = _cancels[o.offerId] = CancelToken();
    final saved = <String>[];
    try {
      final base = await resolveDownloadFolder(ref.read(folderRepositoryProvider));
      if (base == null) {
        AppLog.w('offer: no destination folder');
        throw const LanException(LanError.failed);
      }
      final out = Directory(p.join(base.$1.path, 'Ricevuti'));
      for (final item in o.items) {
        if (cancel.isCancelled) break;
        await for (final e in client.downloadOfferItem(
            o.fromHost, o.fromPort, o.offerId, o.token, item, out,
            cancel: cancel)) {
          if (e.path != null) saved.add(e.path!);
        }
        o.received++;
        _service?.notify();
      }
      if (saved.isNotEmpty) {
        await ref
            .read(libraryScannerProvider)
            .scanFiles(base.$2, saved)
            .drain<void>();
      }
      o.status = o.received == o.items.length ? OfferStatus.done : OfferStatus.failed;
      try {
        await client.offerAction(
            o.fromHost, o.fromPort, o.offerId, 'done', o.token);
      } on LanException {
        // Informational only.
      }
    } on LanException catch (e) {
      AppLog.w('offer download failed: $e');
      o.status = OfferStatus.failed;
      state = state.copyWith(error: e.error);
    } finally {
      _cancels.remove(o.offerId);
      _service?.notify();
    }
  }

  void clearFinished() {
    final s = _service;
    if (s == null) return;
    s.incoming.removeWhere((_, o) => o.status != OfferStatus.pending &&
        o.status != OfferStatus.accepted);
    s.outgoing.removeWhere((_, o) => !o.open);
    _publish();
  }
}

final shareHubProvider =
    NotifierProvider<ShareHubNotifier, ShareHubState>(ShareHubNotifier.new);

/// New pending offers, for the app-wide accept/decline dialog.
final shareOffersProvider = StreamProvider<IncomingOffer>(
    (ref) => ref.watch(shareHubProvider.notifier).newIncoming);

/// Starts listening at launch when "receive from the local network" is on.
final shareAutoStartProvider = Provider<void>((ref) {
  if (ref.read(settingsProvider).receiveFromLan) {
    ref.read(shareHubProvider.notifier).enter();
  }
});
