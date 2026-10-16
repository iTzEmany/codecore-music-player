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

  test('v3 database gets the import tables and keeps its data', () async {
    final dir = Directory.systemTemp.createTempSync('mig4');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'v3.db'));
    final db = AppDatabase(NativeDatabase(file, setup: (raw) {
      if (raw.userVersion == 0) {
        raw.execute('CREATE TABLE playlists (id INTEGER PRIMARY KEY '
            'AUTOINCREMENT, name TEXT NOT NULL, created_at INTEGER NOT NULL, '
            'cover_key TEXT)');
        raw.execute("INSERT INTO playlists (name, created_at) VALUES ('Mine', 1)");
        raw.execute('CREATE TABLE tracks (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'path TEXT NOT NULL, replay_gain_db REAL)');
        raw.userVersion = 3;
      }
    }));
    final rows = await db.select(db.playlists).get();
    expect(rows.single.name, 'Mine');
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final names = tables.map((t) => t.read<String>('name'));
    expect(names, containsAll(['playlist_imports', 'playlist_import_items']));
    expect(await db.select(db.playlistImports).get(), isEmpty);
    await db.close();
  });

  test('v4 database gets the v5 import columns and keeps its import intact',
      () async {
    final dir = Directory.systemTemp.createTempSync('mig5');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'v4.db'));
    final db = AppDatabase(NativeDatabase(file, setup: (raw) {
      if (raw.userVersion == 0) {
        raw.execute('CREATE TABLE playlists (id INTEGER PRIMARY KEY '
            'AUTOINCREMENT, name TEXT NOT NULL, created_at INTEGER NOT NULL, '
            'cover_key TEXT)');
        raw.execute("INSERT INTO playlists (name, created_at) VALUES ('Mood', 1)");
        raw.execute('CREATE TABLE tracks (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'path TEXT NOT NULL, replay_gain_db REAL)');
        raw.execute('CREATE TABLE playlist_imports (id INTEGER PRIMARY KEY '
            'AUTOINCREMENT, playlist_id INTEGER NOT NULL, source_name TEXT NOT '
            'NULL, created_at INTEGER NOT NULL, status INTEGER NOT NULL DEFAULT 0)');
        raw.execute('CREATE TABLE playlist_import_items (import_id INTEGER NOT '
            'NULL, row_index INTEGER NOT NULL, title TEXT NOT NULL, artists TEXT '
            'NOT NULL, album TEXT, duration_ms INTEGER, isrc TEXT, status INTEGER '
            'NOT NULL DEFAULT 0, video_id TEXT, candidates TEXT, track_id '
            'INTEGER, score REAL, PRIMARY KEY (import_id, row_index))');
        raw.execute("INSERT INTO playlist_imports (playlist_id, source_name, "
            "created_at, status) VALUES (1, 'Mood', 5, 2)");
        raw.execute("INSERT INTO playlist_import_items (import_id, row_index, "
            "title, artists, status) VALUES (1, 0, 'Song', 'Band', 2)");
        raw.userVersion = 4;
      }
    }));
    final imp = (await db.select(db.playlistImports).get()).single;
    expect(imp.sourceName, 'Mood');
    expect(imp.status, 2);
    expect(imp.sourceKind, 'exportify', reason: 'default for old imports');
    expect(imp.folderPath, isNull);
    expect(imp.numberFiles, isFalse);
    expect(imp.linkOnly, isFalse);
    expect(imp.planFirst, isFalse);
    expect(imp.fetchCovers, isFalse);
    final item = (await db.select(db.playlistImportItems).get()).single;
    expect(item.title, 'Song');
    expect(item.status, 2);
    expect(item.note, isNull);
    expect(item.location, isNull);
    await db.close();
  });

  test('a fresh install and an upgrade from v3 both end with the v5 columns',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cols = await db.customSelect('PRAGMA table_info(playlist_imports)').get();
    expect(cols.map((c) => c.read<String>('name')),
        containsAll(['source_kind', 'folder_path', 'number_files', 'link_only',
          'plan_first', 'fetch_covers']));
    await db.close();
  });

  test('v5 database gets tracks.resume_position_ms and keeps its tracks', () async {
    final dir = Directory.systemTemp.createTempSync('mig6');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'v5.db'));
    final db = AppDatabase(NativeDatabase(file, setup: (raw) {
      if (raw.userVersion == 0) {
        raw.execute('CREATE TABLE tracks (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'path TEXT NOT NULL, title TEXT NOT NULL, album_key TEXT NOT NULL, '
            'format TEXT NOT NULL, size_bytes INTEGER NOT NULL, mtime_ms INTEGER '
            'NOT NULL, added_at INTEGER NOT NULL, replay_gain_db REAL)');
        raw.execute("INSERT INTO tracks (path, title, album_key, format, size_bytes, "
            "mtime_ms, added_at) VALUES ('/a.mp3', 'Old', 'k', 'mp3', 1, 1, 1)");
        raw.userVersion = 5;
      }
    }));
    final t = (await db
            .customSelect('SELECT title, resume_position_ms FROM tracks')
            .get())
        .single;
    expect(t.read<String>('title'), 'Old');
    expect(t.read<int?>('resume_position_ms'), isNull);
    final cols = await db.customSelect('PRAGMA table_info(tracks)').get();
    expect(cols.map((c) => c.read<String>('name')), contains('resume_position_ms'));
    await db.close();
  });
}
