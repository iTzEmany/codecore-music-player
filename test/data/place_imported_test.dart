import 'package:codecore/core/import_row.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/import_repository.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PlaylistRepository playlists;
  late ImportRepository imports;
  late List<int> ids;
  late int playlistId;
  late int importId;

  Future<void> arrive(int row) async {
    await imports.setItem(importId, row,
        status: ImportItemStatus.downloaded, trackId: Value(ids[row]));
    await playlists.placeImported(playlistId, importId, row, ids[row]);
  }

  Future<List<String>> order() async =>
      (await playlists.watchTracks(playlistId).first).map((t) => t.title).toList();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    playlists = PlaylistRepository(db);
    imports = ImportRepository(db);
    await TrackRepository(db).upsertBatch([
      for (final n in ['t0', 't1', 't2', 't3', 'manual'])
        TracksCompanion.insert(
            path: '/$n',
            title: n,
            albumKey: 'k',
            format: 'mp3',
            sizeBytes: 1,
            mtimeMs: 1,
            addedAt: 1),
    ]);
    final all = await db.select(db.tracks).get();
    ids = [for (final n in ['t0', 't1', 't2', 't3', 'manual']) all.firstWhere((t) => t.title == n).id];
    playlistId = await playlists.create('Imported');
    importId = await imports.create(playlistId: playlistId, sourceName: 'x', rows: [
      for (var i = 0; i < 4; i++)
        ImportRow(index: i, title: 't$i', artists: const ['A']),
    ]);
  });
  tearDown(() => db.close());

  test('rows arriving out of order end up in CSV order', () async {
    await arrive(2);
    await arrive(0);
    await arrive(3);
    await arrive(1);
    expect(await order(), ['t0', 't1', 't2', 't3']);
  });

  test('a manually added track keeps its place', () async {
    await arrive(0);
    await arrive(2);
    await playlists.addTracks(playlistId, [ids[4]]);
    await arrive(1);
    await arrive(3);
    // t3 has no later row to go before, so it goes to the end.
    expect(await order(), ['t0', 't1', 't2', 'manual', 't3']);
  });

  test('a track already in the playlist is not duplicated', () async {
    await arrive(0);
    final again = await playlists.placeImported(playlistId, importId, 0, ids[0]);
    expect(again, isFalse);
    expect(await order(), ['t0']);
  });

  test('positions stay contiguous', () async {
    await arrive(1);
    await arrive(0);
    final rows = await db.select(db.playlistTracks).get();
    expect(rows.map((r) => r.position).toList()..sort(), [0, 1]);
  });
}
