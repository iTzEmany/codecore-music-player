import '../../core/app_log.dart';
import '../../data/repositories/radio_repository.dart';
import 'radio_browser_client.dart';
import 'radio_prefs.dart';

const kSavedRefreshEvery = Duration(days: 1);

/// Reads the saved Radio Browser stations again, at most once a day: a changed
/// address is updated, a station Radio Browser no longer knows is marked as
/// not answering (never deleted). Stations added by hand are left alone.
/// [onRequest] is called right before the request. Returns whether the request succeeded. A failure is logged, not thrown: the
/// saved addresses keep working without Radio Browser.
Future<bool> refreshSavedRadios({
  required RadioRepository repo,
  required RadioBrowserClient client,
  required RadioPrefs prefs,
  DateTime Function()? now,
  void Function()? onRequest,
}) async {
  final clock = (now ?? DateTime.now)();
  try {
    final last = await prefs.refreshedAt();
    if (last != null &&
        clock.difference(DateTime.fromMillisecondsSinceEpoch(last)) < kSavedRefreshEvery) {
      return false;
    }
    final ids = [
      for (final r in await repo.getAll())
        if (!r.stationId.startsWith('manual:')) r.stationId,
    ];
    if (ids.isEmpty) return false;
    onRequest?.call();
    final fresh = await client.byUuids(ids);
    final found = {for (final s in fresh) s.id};
    await repo.applyRefresh(fresh, [
      for (final id in ids)
        if (!found.contains(id)) id,
    ]);
    await prefs.setRefreshedAt(clock.millisecondsSinceEpoch);
    return true;
  } on Object catch (e, st) {
    AppLog.w('refreshing the saved radios failed', e, st);
    return false;
  }
}
