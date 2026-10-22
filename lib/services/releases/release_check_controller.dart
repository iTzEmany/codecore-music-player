import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/app_log.dart';
import '../../core/network_kind.dart';
import '../../data/repositories/follow_repository.dart';
import '../../data/settings/settings_store.dart';
import 'check_schedule.dart';
import 'release_checker.dart';

/// Called with the new releases worth telling the user about (not muted,
/// at most one call a day). 34.9 plugs the Android notification in here.
typedef ReleaseNotifyHook = Future<void> Function(List<FreshRelease> fresh);

/// Decides when a round of release checks runs: [startDelay] after start, then
/// every [every] it looks whether one is due (see [isCheckDue]). The automatic
/// round is silent; [checkNow] is the manual one. Stops a running round when
/// the network goes away or the options forbid it.
class ReleaseCheckController {
  ReleaseCheckController({
    required this.store,
    required this.follows,
    required this.network,
    required this.buildChecker,
    required this.autoFollow,
    required this.notify,
    this.networkChanges = const Stream.empty(),
    DateTime Function()? now,
    this.startDelay = const Duration(seconds: 30),
    this.every = const Duration(hours: 1),
  }) : _now = now ?? DateTime.now;

  final SettingsStore store;
  final FollowRepository follows;
  final Future<NetworkKind> Function() network;
  final Stream<void> networkChanges;
  final ReleaseChecker Function() buildChecker;

  /// One round of `AutoFollowService.run` (only called with «Più ascoltati» on).
  final Future<void> Function() autoFollow;
  final ReleaseNotifyHook notify;
  final Duration startDelay, every;
  final DateTime Function() _now;

  Timer? _first, _hourly;
  StreamSubscription<void>? _netSub;
  CheckCancel? _cancel;
  bool _disposed = false;

  /// True while a round (or a one-artist check) runs.
  final running = ValueNotifier<bool>(false);

  /// Starts the schedule: the first look after [startDelay], then every [every].
  void start() {
    if (_disposed || _first != null || _hourly != null) return;
    _netSub = networkChanges.listen((_) => unawaited(_onNetworkChanged()));
    _first = Timer(startDelay, () {
      _hourly = Timer.periodic(every, (_) => unawaited(tick()));
      unawaited(tick());
    });
  }

  /// The automatic look: runs a round when it is due.
  Future<CheckOutcome?> tick() => _round(force: false);

  /// «Controlla ora»: skips the 24 h wait, not a pause asked by YouTube.
  Future<CheckOutcome?> checkNow() => _round(force: true);

  /// The first check of a just followed artist (it stores everything as seen).
  /// Null when it did not run: another round is going, offline, a metered
  /// network with «Solo su Wi-Fi», or a pause asked by YouTube.
  Future<CheckOutcome?> checkArtist(String id) async {
    if (_disposed || running.value) return null;
    final retry = store.releasesRetryAt;
    if (retry != null && _now().millisecondsSinceEpoch < retry) return null;
    final net = await network();
    if (mustCancelCheck(network: net, unmeteredOnly: store.releasesUnmeteredOnly)) return null;
    return _run(() async => buildChecker().run(cancel: _cancel, only: id), notifyUser: false);
  }

  /// An option changed (call after writing it): stops a round that is no
  /// longer allowed.
  Future<void> optionsChanged() => _stopIfForbidden();

  Future<void> _onNetworkChanged() async {
    await _stopIfForbidden();
    if (!running.value && !_disposed && (_first == null || _hourly != null)) {
      unawaited(tick());
    }
  }

  Future<void> _stopIfForbidden() async {
    final c = _cancel;
    if (c == null || !running.value) return;
    final net = await network();
    if (mustCancelCheck(network: net, unmeteredOnly: store.releasesUnmeteredOnly)) c.cancel();
  }

  Future<CheckOutcome?> _round({required bool force}) async {
    if (_disposed || running.value) return null;
    final net = await network();
    final now = _now();
    DateTime? at(int? ms) => ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    final topArtists = store.releasesTopArtists;
    final hasArtists = topArtists || (await follows.toCheck(limit: 1)).isNotEmpty;
    final due = isCheckDue(
      lastRunAt: at(store.releasesLastRunAt),
      retryAt: at(store.releasesRetryAt),
      now: now,
      hasArtists: hasArtists,
      network: net,
      unmeteredOnly: store.releasesUnmeteredOnly,
      force: force,
    );
    if (!due) return null;
    return _run(() async {
      if (topArtists) {
        try {
          await autoFollow();
        } catch (e, st) {
          AppLog.w('auto-follow of the most listened artists failed', e, st);
        }
        if ((_cancel?.isCancelled ?? false) || (await follows.toCheck(limit: 1)).isEmpty) {
          return const CheckOutcome();
        }
      }
      return buildChecker().run(cancel: _cancel);
    }, notifyUser: true);
  }

  Future<CheckOutcome?> _run(Future<CheckOutcome> Function() body, {required bool notifyUser}) async {
    if (running.value) return null;
    running.value = true;
    _cancel = CheckCancel();
    try {
      final out = await body();
      if (notifyUser) await _finish(out);
      return out;
    } catch (e, st) {
      AppLog.w('release check failed', e, st);
      return null;
    } finally {
      _cancel = null;
      running.value = false;
    }
  }

  /// Remembers the round (it counts unless the network or the user stopped it
  /// or YouTube asked for a pause) and tells the user once a day.
  Future<void> _finish(CheckOutcome out) async {
    final now = _now();
    final stop = out.stoppedBy;
    if (out.retryAt != null) {
      await store.writeReleasesRetryAt(out.retryAt!.millisecondsSinceEpoch);
    } else if (stop == CheckStop.offline || stop == CheckStop.cancelled) {
      return;
    } else {
      await store.writeReleasesRetryAt(null);
      await store.writeReleasesLastRunAt(now.millisecondsSinceEpoch);
    }
    final last = store.releasesLastNotifiedAt;
    final toTell = releasesToNotify(
      fresh: out.fresh,
      enabled: store.releasesNotify,
      lastNotifiedAt: last == null ? null : DateTime.fromMillisecondsSinceEpoch(last),
      now: now,
    );
    if (toTell == null) return;
    await store.writeReleasesLastNotifiedAt(now.millisecondsSinceEpoch);
    try {
      await notify(toTell);
    } catch (e, st) {
      AppLog.w('release notification failed', e, st);
    }
  }

  void dispose() {
    _disposed = true;
    _cancel?.cancel();
    _first?.cancel();
    _hourly?.cancel();
    unawaited(_netSub?.cancel());
    running.dispose();
  }
}
