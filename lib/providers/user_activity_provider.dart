import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_providers.dart';

/// When the user last did something (scroll, typed a search) and whether a
/// download, import or transfer is running: the background enrichment waits
/// for both. A plain value read by its consumer, never watched by the UI.
class UserActivity {
  UserActivity({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  DateTime? _last;
  bool _busy = false;

  DateTime? get lastActivityAt => _last;

  void touch() => _last = _now();

  bool get isBusy => _busy;

  /// Set from the running activities; the end of a busy spell counts as activity.
  set busy(bool v) {
    if (_busy && !v) touch();
    _busy = v;
  }

  bool idleFor(Duration d) =>
      !_busy && (_last == null || _now().difference(_last!) >= d);

  Future<void> waitIdle(
    Duration d, {
    Duration poll = const Duration(seconds: 1),
  }) async {
    while (!idleFor(d)) {
      await Future<void>.delayed(poll);
    }
  }
}

// Not enrichBackground: the completion would wait for itself.
const _busyKinds = {
  ActivityKind.download,
  ActivityKind.import,
  ActivityKind.transfer,
  ActivityKind.enrich,
  ActivityKind.scan,
};

/// Keep it listened (the shell does): a provider nobody listens to is paused
/// and its [activityProvider] listener would not run.
final userActivityProvider = Provider<UserActivity>((ref) {
  final a = UserActivity();
  void sync(ActivityState s) =>
      // A paused import waits for the user, it is not work in progress.
      a.busy = s.running.any((i) => _busyKinds.contains(i.kind) && !i.paused);
  ref.listen(activityProvider, (_, next) => sync(next), fireImmediately: true);
  return a;
});
