import 'package:codecore/core/import_row.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/import_repository.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/services/import/csv_parser.dart';
import 'package:codecore/services/import/import_options.dart';
import 'package:codecore/services/import/import_outcome.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one line per row with status, reason, video and score; removed rows left out',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = ImportRepository(db);
    final pl = await PlaylistRepository(db).create('Mood');
    final id = await repo.create(playlistId: pl, sourceName: 'Mood', rows: [
      const ImportRow(
          index: 0,
          title: 'Song, with "quotes"',
          artists: ['A', 'B'],
          album: 'Alb',
          durationMs: 200000,
          isrc: 'X1'),
      const ImportRow(index: 1, title: 'Gone', artists: ['C']),
      const ImportRow(index: 2, title: 'Old', artists: ['D']),
    ]);
    await repo.setItem(id, 0,
        status: ImportItemStatus.downloaded,
        videoId: const Value('abc'),
        score: const Value(0.9137));
    await repo.setItem(id, 1,
        status: ImportItemStatus.notFound,
        note: const Value(ImportNote.noResults));
    await repo.setItem(id, 2, status: ImportItemStatus.removed);

    final csv = importOutcomeCsv(
      await repo.items(id),
      status: (s) => 'S:${s.name}',
      note: (c) => 'N:$c',
      header: const ['Row', 'Title'],
    );
    final table = parseCsv(csv);
    expect(table, hasLength(3), reason: 'header + 2 rows (the removed one is out)');
    expect(table[0], ['Row', 'Title']);
    expect(table[1], [
      '1',
      'Song, with "quotes"',
      'A; B',
      'Alb',
      '200000',
      'X1',
      'S:downloaded',
      '',
      'https://music.youtube.com/watch?v=abc',
      '0.91',
    ]);
    expect(table[2][0], '2');
    expect(table[2][6], 'S:notFound');
    expect(table[2][7], 'N:no_results');
    expect(table[2][8], '');
  });
}
