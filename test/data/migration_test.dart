import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('v1 database gets the playlists.cover_key column', () async {
    final dir = Directory.systemTemp.createTempSync('mig');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'old.db'));
    // The setup callback fabricates a version-1 file before drift opens it.
    final db = AppDatabase(NativeDatabase(file, setup: (raw) {
      if (raw.userVersion == 0) {
        raw.execute('CREATE TABLE playlists (id INTEGER PRIMARY KEY '
            'AUTOINCREMENT, name TEXT NOT NULL, created_at INTEGER NOT NULL)');
        raw.execute("INSERT INTO playlists (name, created_at) VALUES ('Old', 1)");
        // v1 also had a tracks table (without replay_gain_db).
        raw.execute('CREATE TABLE tracks (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'path TEXT NOT NULL)');
        raw.userVersion = 1;
      }
    }));
    final rows = await db.select(db.playlists).get();
    expect(rows.single.name, 'Old');
    expect(rows.single.coverKey, isNull);
    final cols = await db
        .customSelect('PRAGMA table_info(tracks)')
        .get();
    expect(cols.map((c) => c.read<String>('name')), contains('replay_gain_db'));
    await db.close();
  });
}
