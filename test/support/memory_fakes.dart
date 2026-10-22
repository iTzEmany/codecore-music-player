import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/providers/memory_providers.dart';
import 'package:codecore/providers/nav_providers.dart';
import 'package:codecore/services/memory/app_data.dart';
import 'package:codecore/services/memory/disk_space.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/misc.dart' show Override;

const gb = 1073741824, mb = 1048576;

/// The Memoria tab is shown (its tab index is selected).
class MemoryTab extends NavIndexNotifier {
  @override
  int build() => NavTab.memory.index;
}

class FakeMemoryActions implements MemoryActions {
  int calls = 0;

  @override
  Future<CacheClearResult> clearCaches() async {
    calls++;
    return const CacheClearResult(freedBytes: 5 * mb, jamSkipped: false);
  }
}

final memoryDisk = DiskSpace(totalBytes: 128 * gb, freeBytes: (11.2 * gb).round());

Future<void> _addTrack(AppDatabase db, String title, int size, {String format = 'mp3'}) =>
    db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/m/$title.$format',
          title: title,
          albumKey: 'artist|$title',
          format: format,
          sizeBytes: size,
          mtimeMs: 1,
          addedAt: 1,
          artist: const Value('Artist'),
          album: Value('Album $title'),
          durationMs: const Value(185000),
        ));

/// 38.4 GB of music: one big FLAC and six 10 MB mp3 (7 heavy tracks, none
/// ever played), a playlist holding the FLAC. [suffix] lengthens the titles.
Future<void> seedMemory(AppDatabase db, {String playlistName = 'Gym', String suffix = ''}) async {
  await _addTrack(db, 'Big Flac$suffix', 41231686042 - 6 * 10 * mb, format: 'flac');
  for (var i = 0; i < 6; i++) {
    await _addTrack(db, 'Heavy $i$suffix', 10 * mb);
  }
  final pid = await db.into(db.playlists).insert(PlaylistsCompanion.insert(name: playlistName, createdAt: 1));
  final tid = await (db.select(db.tracks)..where((t) => t.title.equals('Big Flac$suffix'))).map((t) => t.id).getSingle();
  await db.into(db.playlistTracks).insert(PlaylistTracksCompanion.insert(playlistId: pid, trackId: tid, position: 0));
}

List<Override> memoryOverrides(FakeMemoryActions actions, DiskSpace? disk) => [
      navIndexProvider.overrideWith(MemoryTab.new),
      memoryActionsProvider.overrideWithValue(actions),
      musicDiskSpaceProvider.overrideWith((ref) async => disk),
      appDataUsageProvider.overrideWith((ref) async => const [
            AppDataItem(AppDataKind.covers, 52 * mb, detailBytes: 8 * mb),
            AppDataItem(AppDataKind.database, 4 * mb),
            AppDataItem(AppDataKind.imageMemory, 20 * mb),
            AppDataItem(AppDataKind.jamCache, 0),
            AppDataItem(AppDataKind.tagBackups, 200 * 1024),
            AppDataItem(AppDataKind.log, 500 * 1024),
          ]),
    ];
