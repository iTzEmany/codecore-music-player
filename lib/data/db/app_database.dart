import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Tracks,
  Folders,
  Playlists,
  PlaylistTracks,
  PlaylistImports,
  PlaylistImportItems,
  Plays,
  SmartPlaylists,
  UserTags,
  TrackTags,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.production() : super(driftDatabase(name: 'codecore'));

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(playlists, playlists.coverKey);
          if (from < 3) await m.addColumn(tracks, tracks.replayGainDb);
          if (from < 4) {
            // Created from the current definition, v5 columns included.
            await m.createTable(playlistImports);
            await m.createTable(playlistImportItems);
          } else if (from < 5) {
            await m.addColumn(playlistImports, playlistImports.sourceKind);
            await m.addColumn(playlistImports, playlistImports.folderPath);
            await m.addColumn(playlistImports, playlistImports.numberFiles);
            await m.addColumn(playlistImports, playlistImports.linkOnly);
            await m.addColumn(playlistImports, playlistImports.planFirst);
            await m.addColumn(playlistImports, playlistImports.fetchCovers);
            await m.addColumn(playlistImportItems, playlistImportItems.note);
            await m.addColumn(playlistImportItems, playlistImportItems.location);
          }
          if (from < 6) await m.addColumn(tracks, tracks.resumePositionMs);
          if (from < 7) {
            // History, smart playlists and user tags: new tables, nothing
            // existing is touched.
            await m.createTable(plays);
            await m.createIndex(playsTrack);
            await m.createIndex(playsAt);
            await m.createTable(smartPlaylists);
            await m.createTable(userTags);
            await m.createTable(trackTags);
          }
          if (from < 8) await m.addColumn(tracks, tracks.ignored);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
