import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories/folder_repository.dart';
import '../data/repositories/playlist_repository.dart';
import '../data/repositories/track_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.production();
  ref.onDispose(db.close);
  return db;
});

final trackRepositoryProvider = Provider<TrackRepository>(
  (ref) => TrackRepository(ref.watch(databaseProvider)),
);

final folderRepositoryProvider = Provider<FolderRepository>(
  (ref) => FolderRepository(ref.watch(databaseProvider)),
);

final playlistRepositoryProvider = Provider<PlaylistRepository>(
  (ref) => PlaylistRepository(ref.watch(databaseProvider)),
);

final playlistsProvider = StreamProvider<List<PlaylistSummary>>(
  (ref) => ref.watch(playlistRepositoryProvider).watchAll(),
);

final playlistTracksProvider = StreamProvider.family<List<Track>, int>(
  (ref, id) => ref.watch(playlistRepositoryProvider).watchTracks(id),
);
