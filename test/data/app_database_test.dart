import 'package:codecore/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('insert and read a track', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/m/a.mp3',
          title: 'A',
          albumKey: 'unknown|/m',
          format: 'mp3',
          sizeBytes: 10,
          mtimeMs: 1,
          addedAt: 2,
        ));
    final rows = await db.select(db.tracks).get();
    expect(rows.single.title, 'A');
    expect(rows.single.isFavorite, false);
    expect(rows.single.durationMs, 0);
  });
}
