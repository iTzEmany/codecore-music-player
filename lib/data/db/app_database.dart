import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tracks, Folders, Playlists, PlaylistTracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.production() : super(driftDatabase(name: 'codecore'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
