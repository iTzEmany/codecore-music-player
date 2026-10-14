import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PlaylistRepository repo;
  late List<int> ids;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = PlaylistRepository(db);
    await TrackRepository(db).upsertBatch([
      for (final n in ['a', 'b', 'c'])
        TracksCompanion.insert(
            path: '/$n',
            title: n,
            albumKey: 'k',
            format: 'mp3',
            sizeBytes: 1,
            mtimeMs: 1,
            addedAt: 1,
            artist: const Value('x')),
    ]);
    ids = (await db.select(db.tracks).get()).map((t) => t.id).toList();
  });
  tearDown(() => db.close());

  test('duplicates are ignored', () async {
    final p = await repo.create('Mix');
    expect(await repo.addTracks(p, [ids[0], ids[1]]), 2);
    expect(await repo.addTracks(p, [ids[1], ids[2]]), 1);
    final tracks = await repo.watchTracks(p).first;
    expect(tracks.map((t) => t.id), ids);
    final all = await repo.watchAll().first;
    expect(all.single.trackCount, 3);
  });

  test('reorder is stable and removal renumbers', () async {
    final p = await repo.create('Mix');
    await repo.addTracks(p, ids);
    await repo.reorder(p, 0, 2);
    expect((await repo.watchTracks(p).first).map((t) => t.id),
        [ids[1], ids[2], ids[0]]);
    await repo.removeTrack(p, ids[2]);
    final rows = await db.select(db.playlistTracks).get();
    expect(rows.map((r) => r.position).toList()..sort(), [0, 1]);
    expect((await repo.watchTracks(p).first).map((t) => t.id), [ids[1], ids[0]]);
  });

  test('deleting a track or playlist cascades', () async {
    await db.customStatement('PRAGMA foreign_keys = ON');
    final p = await repo.create('Mix');
    await repo.addTracks(p, ids);
    await (db.delete(db.tracks)..where((t) => t.id.equals(ids[0]))).go();
    expect((await db.select(db.playlistTracks).get()).length, 2);
    await repo.delete(p);
    expect(await db.select(db.playlistTracks).get(), isEmpty);
  });

  test('favorite toggle', () async {
    final tracks = TrackRepository(db);
    await tracks.setFavorite(ids[0], true);
    expect((await tracks.getById(ids[0]))!.isFavorite, true);
    await tracks.setFavorite(ids[0], false);
    expect((await tracks.getById(ids[0]))!.isFavorite, false);
    expect((await tracks.watchTracks(favoritesOnly: true).first), isEmpty);
  });
}
