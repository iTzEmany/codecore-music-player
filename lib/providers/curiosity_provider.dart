import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart' show Track;
import '../services/online/curiosity_service.dart';
import 'database_providers.dart';
import 'online_providers.dart';
import 'settings_providers.dart';

export '../services/online/curiosity_service.dart' show CuriosityOutcome;

/// The curiosity search of one track (by id): loading while it runs, then how it
/// went (null before the first search). The results are saved in the DB here.
class CuriosityNotifier extends AsyncNotifier<CuriosityOutcome?> {
  CuriosityNotifier(this.trackId);

  final int trackId;

  @override
  CuriosityOutcome? build() => null;

  Future<CuriosityOutcome> fetch(Track t) async {
    state = const AsyncLoading();
    final out = await ref
        .read(curiosityServiceProvider)
        .fetch(t, ref.read(settingsProvider).language);
    state = AsyncData(out);
    return out;
  }
}

final curiosityServiceProvider = Provider(
  (ref) => CuriosityService(
    finder: ref.watch(curiosityFinderProvider),
    tracks: ref.watch(trackRepositoryProvider),
    artistInfos: ref.watch(artistInfoRepositoryProvider),
  ),
);

final curiosityProvider = AsyncNotifierProvider.autoDispose
    .family<CuriosityNotifier, CuriosityOutcome?, int>(CuriosityNotifier.new);
