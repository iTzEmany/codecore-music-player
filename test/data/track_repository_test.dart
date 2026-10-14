import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

TracksCompanion row(String path, String title,
        {int mtime = 1, int? folderId}) =>
    TracksCompanion.insert(
      path: path,
      title: title,
      albumKey: 'k',
      format: 'mp3',
      sizeBytes: 10,
      mtimeMs: mtime,
      addedAt: 5,
      folderId: Value(folderId),
    );

void main() {
  late AppDatabase db;
  late TrackRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrackRepository(db);
  });
  tearDown(() => db.close());

  test('upsert twice keeps one row and preserves favorite', () async {
    await repo.upsertBatch([row('/a.mp3', 'A')]);
    final id = (await db.select(db.tracks).getSingle()).id;
    await (db.update(db.tracks)..where((t) => t.id.equals(id)))
        .write(const TracksCompanion(isFavorite: Value(true)));
    await repo.upsertBatch([row('/a.mp3', 'A2', mtime: 9)]);
    final t = await db.select(db.tracks).getSingle();
    expect(t.title, 'A2');
    expect(t.mtimeMs, 9);
    expect(t.isFavorite, true);
    expect(t.addedAt, 5);
  });

  test('userEdited keeps title', () async {
    await repo.upsertBatch([row('/a.mp3', 'A')]);
    await db.update(db.tracks).write(const TracksCompanion(
        userEdited: Value(true), title: Value('Mine')));
    await repo.upsertBatch([row('/a.mp3', 'FromFile')]);
    expect((await db.select(db.tracks).getSingle()).title, 'Mine');
  });

  test('search treats % literally', () async {
    await repo.upsertBatch([row('/a.mp3', '100% Pure'), row('/b.mp3', 'Other')]);
    final r = await repo.watchTracks(query: '%').first;
    expect(r.map((t) => t.title), ['100% Pure']);
    final u = await repo.watchTracks(query: '_').first;
    expect(u, isEmpty);
  });

  test('missing excluded, getByIds keeps order, count', () async {
    await repo.upsertBatch([row('/a.mp3', 'A'), row('/b.mp3', 'B')]);
    await repo.markMissing({'/b.mp3'}, true);
    expect((await repo.watchTracks().first).length, 1);
    final all = await db.select(db.tracks).get();
    final ids = all.map((t) => t.id).toList().reversed.toList();
    expect((await repo.getByIds(ids)).map((t) => t.id), ids);
    expect(await repo.countAll(), 2);
  });
}
