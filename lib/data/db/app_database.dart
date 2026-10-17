import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/clock.dart';
import '../../core/uuid.dart';
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
  Podcasts,
  PodcastEpisodes,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.production() : super(driftDatabase(name: 'codecore'));

  @override
  int get schemaVersion => 10;

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
          if (from < 9) {
            // Podcasts: one column on tracks, two new tables; nothing existing
            // is touched and every existing track stays music (kind 0).
            await m.addColumn(tracks, tracks.kind);
            await m.createIndex(tracksKind);
            await m.createTable(podcasts);
            await m.createTable(podcastEpisodes);
            await m.createIndex(podcastEpisodesPodcast);
          }
          if (from < 10) {
            // Playlists get an identity that survives a sync, and a change
            // time (the creation time until the first change).
            await m.addColumn(playlists, playlists.uuid);
            await m.addColumn(playlists, playlists.updatedAt);
            await customStatement('UPDATE playlists SET updated_at = created_at');
            for (final row in await customSelect('SELECT id FROM playlists').get()) {
              await customStatement(
                'UPDATE playlists SET uuid = ? WHERE id = ?',
                [newUuid(), row.read<int>('id')],
              );
            }
            await m.createIndex(playlistsUuid);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
