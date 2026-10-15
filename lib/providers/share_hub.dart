import 'dart:async';
import 'dart:io';
import 'dart:ui' show AppLifecycleState, Locale;

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../core/app_log.dart';
import '../data/db/app_database.dart';
import '../services/share/discovery.dart';
import '../services/share/lan_client.dart';
import '../l10n/app_localizations.dart';
import '../services/share/offers.dart';
import '../services/share/share_notifier.dart';
import '../core/platform.dart';
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
  final _notified = <String>{}; // offers currently shown as notifications
  AppLifecycleListener? _lifecycle;

  /// New pending offers (the shell turns them into a dialog).
  Stream<IncomingOffer> get newIncoming => _newIncoming.stream;

  ShareNotifier get _platform => ref.read(shareNotifierProvider);

  AppLocalizations get _l10n => lookupAppLocalizations(
      Locale(ref.read(settingsProvider).language));

  bool get _inForeground {
    final s = WidgetsBinding.instance.lifecycleState;
    return s == null || s == AppLifecycleState.resumed;
  }

  @override
  ShareHubState build() {
    ref.onDispose(_teardown);
    final platform = ref.read(shareNotifierProvider);
    platform.onOfferAction = _onNotificationAction;
    platform.onDisableReceive = () => ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(receiveFromLan: false));
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    ref.listen(settingsProvider.select((s) => s.receiveFromLan),
        (_, on) => _applyReceiveSetting(on));
    if (ref.read(settingsProvider).receiveFromLan) {
      scheduleMicrotask(() => _applyReceiveSetting(true));
    }
    return const ShareHubState();
  }

  /// "Receive from the local network" on/off: endpoint, discovery and (on
  /// Android) the foreground service with its notification.
  Future<void> _applyReceiveSetting(bool on) async {
    if (!ref.mounted) return;
    if (on) {
      if (isAndroid) await Permission.notification.request();
      await _ensureRunning();
      final l = _l10n;
      await _platform.startService(
        title: l.receiveServiceTitle,
        text: l.receiveServiceText,
        disable: l.receiveServiceDisable,
      );
    } else {
      await _platform.stopService();
      _maybeStop();
    }
  }

  void _onNotificationAction(String offerId, bool accept) {
    final o = _service?.incoming[offerId];
    if (o == null || o.status != OfferStatus.pending) return;
    _notified.remove(offerId);
    accept ? this.accept(o) : decline(o);
  }

  void _onResume() {
    // Offers that arrived while in the background become a normal dialog.
    for (final id in _notified.toList()) {
      final o = _service?.incoming[id];
      _platform.clearOffer(id);
      if (o != null && o.status == OfferStatus.pending) _newIncoming.add(o);
    }
    _notified.clear();
  }

  void _surfaceIncoming(IncomingOffer o) {
    if (_inForeground) {
      _newIncoming.add(o);
      return;
    }
    final l = _l10n;
    final mb = (o.totalBytes / 1048576).toStringAsFixed(1);
    _notified.add(o.offerId);
    _platform.showOffer(
      offerId: o.offerId,
      title: l.incomingTitle(o.fromName),
      body: l.incomingBody(o.items.length, mb),
      accept: l.accept,
      decline: l.decline,
    );
  }

  void _clearStaleNotifications() {
    final s = _service;
    if (s == null) return;
    for (final id in _notified.toList()) {
      final o = s.incoming[id];
      if (o == null || o.status != OfferStatus.pending) {
        _notified.remove(id);
        _platform.clearOffer(id);
      }
    }
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
          _surfaceIncoming(o);
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
        _clearStaleNotifications();
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
    _lifecycle?.dispose();
    _lifecycle = null;
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
  // Creating the hub is enough: it applies the saved setting by itself.
  ref.read(shareHubProvider);
});

final shareNotifierProvider =
    Provider<ShareNotifier>((ref) => createShareNotifier());
