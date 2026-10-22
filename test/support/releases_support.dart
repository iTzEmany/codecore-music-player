import 'package:codecore/core/network_kind.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/follow_repository.dart';
import 'package:codecore/data/repositories/release_repository.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/releases_providers.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/releases/release_check_controller.dart';
import 'package:codecore/services/releases/release_checker.dart';
import 'package:codecore/services/releases/release_diff.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// A check controller whose pages come from [fetch] (every id asked for goes
/// to [asked]); put [override] in the overrides and `dispose` it at the end.
class FakeChecks {
  FakeChecks(AppDatabase db, SettingsStore store, {Future<YtmArtistPage> Function(String id)? fetch})
      : follows = FollowRepository(db),
        releases = ReleaseRepository(db) {
    controller = ReleaseCheckController(
      store: store,
      follows: follows,
      network: () async => const NetworkKind(),
      buildChecker: () => ReleaseChecker(
        (id) async {
          asked.add(id);
          return fetch == null ? YtmArtistPage(ref: YtmArtistRef(id: id, name: id), shelves: const []) : fetch(id);
        },
        follows,
        releases,
        wait: (_) async {},
      ),
      autoFollow: () async {},
      notify: (_) async {},
    );
  }

  final FollowRepository follows;
  final ReleaseRepository releases;
  final asked = <String>[];
  late final ReleaseCheckController controller;

  Override get override => releaseCheckControllerProvider.overrideWithValue(controller);

  void dispose() => controller.dispose();
}

/// Follows [artist] (already checked once) and stores one release flagged new.
Future<void> seedNewRelease(
  AppDatabase db,
  YtmArtistRef artist,
  String browseId,
  String title, {
  int year = 2026,
  ReleaseKind kind = ReleaseKind.album,
}) async {
  final follows = FollowRepository(db);
  await follows.follow(artist);
  await follows.markChecked(artist.id);
  final r = NewRelease(
    release: YtmRelease(browseId: browseId, title: title, subtitle: '$year'),
    kind: kind,
    year: year,
    groupKey: title.toLowerCase(),
  );
  await ReleaseRepository(db).store(artist.id, ReleaseDiff([r], [r]));
}
