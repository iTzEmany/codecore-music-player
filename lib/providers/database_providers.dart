import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories/folder_repository.dart';
import '../data/repositories/track_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.production();
  ref.onDispose(db.close);
  return db;
});

final trackRepositoryProvider =
    Provider<TrackRepository>((ref) => TrackRepository(ref.watch(databaseProvider)));

final folderRepositoryProvider =
    Provider<FolderRepository>((ref) => FolderRepository(ref.watch(databaseProvider)));
