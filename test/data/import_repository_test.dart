import 'package:codecore/core/import_row.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/import_repository.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ImportRepository repo;
  late int playlistId;

  List<ImportRow> rows(int n) => [
        for (var i = 0; i < n; i++)
          ImportRow(
            index: i,
            title: 'T$i',
            artists: const ['A', 'B'],
            album: 'Al',
            durationMs: 1000 + i,
            isrc: 'I$i',
          ),
      ];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = ImportRepository(db);
    playlistId = await PlaylistRepository(db).create('Imported');
  });
  tearDown(() => db.close());

  test('creates the import with all rows in order', () async {
    final id = await repo.create(
        playlistId: playlistId, sourceName: 'x.csv', rows: rows(3));
    final items = await repo.items(id);
    expect(items.map((i) => i.title), ['T0', 'T1', 'T2']);
    expect(items.first.artistList, ['A', 'B']);
    expect(items.first.state, ImportItemStatus.pending);
    expect(items.first.toRow().durationMs, 1000);
    expect((await repo.get(id))!.state, ImportStatus.running);
  });

  test('nextPending follows the CSV order and skips handled rows', () async {
    final id = await repo.create(
        playlistId: playlistId, sourceName: 'x', rows: rows(3));
    expect((await repo.nextPending(id))!.rowIndex, 0);
    await repo.setItem(id, 0, status: ImportItemStatus.linked, trackId: const Value(null));
    await repo.setItem(id, 1,
        status: ImportItemStatus.review,
        candidates: const Value('[{"id":"a"}]'),
        score: const Value(0.6));
    expect((await repo.nextPending(id))!.rowIndex, 2);
    final item = (await repo.item(id, 1))!;
    expect(item.state, ImportItemStatus.review);
    expect(item.candidates, '[{"id":"a"}]');
    expect(item.score, 0.6);
  });

  test('counts per status', () async {
    final id = await repo.create(
        playlistId: playlistId, sourceName: 'x', rows: rows(4));
    await repo.setItem(id, 0, status: ImportItemStatus.downloaded);
    await repo.setItem(id, 1, status: ImportItemStatus.downloaded);
    await repo.setItem(id, 2, status: ImportItemStatus.notFound);
    final c = await repo.counts(id);
    expect(c[ImportItemStatus.downloaded], 2);
    expect(c[ImportItemStatus.notFound], 1);
    expect(c[ImportItemStatus.pending], 1);
  });

  test('restart: running becomes paused, queued goes back to pending', () async {
    final id = await repo.create(
        playlistId: playlistId, sourceName: 'x', rows: rows(2));
    await repo.setItem(id, 0, status: ImportItemStatus.queued);
    await repo.setItem(id, 1, status: ImportItemStatus.downloaded);
    await repo.recoverAfterRestart();
    expect((await repo.get(id))!.state, ImportStatus.paused);
    expect((await repo.item(id, 0))!.state, ImportItemStatus.pending);
    expect((await repo.item(id, 1))!.state, ImportItemStatus.downloaded);
    final unfinished = await repo.watchUnfinished().first;
    expect(unfinished.single.id, id);
  });

  test('finished imports are not listed as unfinished', () async {
    final id = await repo.create(
        playlistId: playlistId, sourceName: 'x', rows: rows(1));
    await repo.setStatus(id, ImportStatus.finished);
    expect(await repo.watchUnfinished().first, isEmpty);
  });

  test('retry puts failed and not-found rows back to pending', () async {
    final id = await repo.create(
        playlistId: playlistId, sourceName: 'x', rows: rows(3));
    await repo.setItem(id, 0, status: ImportItemStatus.notFound);
    await repo.setItem(id, 1, status: ImportItemStatus.failed);
    await repo.setItem(id, 2, status: ImportItemStatus.downloaded);
    await repo.resetItems(id, {ImportItemStatus.notFound, ImportItemStatus.failed});
    final c = await repo.counts(id);
    expect(c[ImportItemStatus.pending], 2);
    expect(c[ImportItemStatus.downloaded], 1);
  });

  test('deleting the playlist deletes the import and its rows', () async {
    final id = await repo.create(
        playlistId: playlistId, sourceName: 'x', rows: rows(2));
    await PlaylistRepository(db).delete(playlistId);
    expect(await repo.get(id), isNull);
    expect(await repo.items(id), isEmpty);
  });
}
