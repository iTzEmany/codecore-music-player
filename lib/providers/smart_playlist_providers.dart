import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import 'database_providers.dart';

/// One random order per run of the app: a «random» smart playlist keeps its
/// order while something else changes, and reshuffles at the next start.
final sessionSeed = Random().nextInt(1 << 30);

final smartPlaylistsProvider = StreamProvider<List<SmartPlaylist>>(
  (ref) => ref.watch(smartPlaylistRepositoryProvider).watchAll(),
);

final smartPlaylistProvider = StreamProvider.family<SmartPlaylist?, int>(
  (ref, id) => ref.watch(smartPlaylistRepositoryProvider).watch(id),
);

/// The tracks of smart playlist [id], recomputed when its rules or the library
/// change.
final smartTracksProvider = StreamProvider.family<List<Track>, int>((ref, id) {
  final p = ref.watch(smartPlaylistProvider(id)).value;
  if (p == null) return const Stream.empty();
  return ref
      .watch(smartPlaylistRepositoryProvider)
      .watchTracks(p, randomSeed: sessionSeed);
});

/// How many tracks some rule text selects (the editor's preview). The rules
/// are the argument, so typing makes a new request.
final ruleCountProvider = FutureProvider.autoDispose.family<int, String>(
  (ref, rules) => ref.watch(smartPlaylistRepositoryProvider).count(rules),
);
