import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_info.dart';
import '../core/app_log.dart';
import '../services/online/update_checker.dart';
import 'online_providers.dart';
import 'settings_providers.dart';

/// The repository to ask; overridden in tests.
final releaseRepoProvider = Provider<String>((ref) => kReleaseRepo);

final updateCheckerProvider = Provider<UpdateChecker?>((ref) {
  final repo = ref.watch(releaseRepoProvider);
  if (repo.isEmpty) return null;
  return UpdateChecker(ref.watch(webClientProvider), repo: repo, current: kAppVersion);
});

/// «Controlla all'avvio»: off by default.
class CheckUpdatesOnStartNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsStoreProvider).readCheckUpdatesOnStart();

  void set(bool on) {
    state = on;
    ref.read(settingsStoreProvider).writeCheckUpdatesOnStart(on).catchError((Object e, StackTrace st) {
      AppLog.w('could not save the update setting', e, st);
    });
  }
}

final checkUpdatesOnStartProvider =
    NotifierProvider<CheckUpdatesOnStartNotifier, bool>(CheckUpdatesOnStartNotifier.new);

int _epochDay(DateTime now) => now.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

/// The check made once at start-up (when enabled): at most one a day, a
/// failure is silent. The new release, or null.
final updateOnStartProvider = FutureProvider<UpdateInfo?>(
  (ref) async {
    final checker = ref.watch(updateCheckerProvider);
    if (checker == null || !ref.read(checkUpdatesOnStartProvider)) return null;
    final store = ref.read(settingsStoreProvider);
    final today = _epochDay(DateTime.now());
    if (store.readLastUpdateCheckDay() == today) return null;
    await store.writeLastUpdateCheckDay(today);
    final r = await checker.check();
    return r.status == UpdateStatus.newer ? r.info : null;
  },
  retry: (_, _) => null,
);
