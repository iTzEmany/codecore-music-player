import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:drift/drift.dart' show Value;
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
        raw.execute('CREATE TABLE playlists (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'name TEXT NOT NULL, created_at INTEGER NOT NULL, cover_key TEXT)');
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

  test('v6 database gets the history, smart playlist and tag tables and keeps its data', () async {
    final dir = Directory.systemTemp.createTempSync('mig7');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'v6.db'));
    final db = AppDatabase(NativeDatabase(file, setup: (raw) {
      if (raw.userVersion == 0) {
        raw.execute('CREATE TABLE playlists (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'name TEXT NOT NULL, created_at INTEGER NOT NULL, cover_key TEXT)');
        raw.execute('CREATE TABLE tracks (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'path TEXT NOT NULL, title TEXT NOT NULL, album_key TEXT NOT NULL, '
            'format TEXT NOT NULL, size_bytes INTEGER NOT NULL, mtime_ms INTEGER '
            'NOT NULL, added_at INTEGER NOT NULL, play_count INTEGER NOT NULL '
            'DEFAULT 0, replay_gain_db REAL, resume_position_ms INTEGER)');
        raw.execute("INSERT INTO tracks (path, title, album_key, format, size_bytes, "
            "mtime_ms, added_at, play_count) VALUES ('/a.mp3', 'Old', 'k', 'mp3', 1, 1, 1, 7)");
        raw.userVersion = 6;
      }
    }));
    final t = (await db.customSelect('SELECT title, play_count FROM tracks').get()).single;
    expect(t.read<String>('title'), 'Old');
    expect(t.read<int>('play_count'), 7, reason: 'the old counter is untouched');
    final tables = (await db
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
            .get())
        .map((r) => r.read<String>('name'));
    expect(tables, containsAll(['plays', 'smart_playlists', 'user_tags', 'track_tags']));
    expect(await db.select(db.plays).get(), isEmpty, reason: 'new tables start empty');
    expect(await db.select(db.smartPlaylists).get(), isEmpty);
    expect(await db.select(db.userTags).get(), isEmpty);
    expect(await db.select(db.trackTags).get(), isEmpty);
    final indexes = (await db
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
            .get())
        .map((r) => r.read<String>('name'));
    expect(indexes, containsAll(['plays_track', 'plays_at']));
    await db.close();
  });

  test('v7 database gets tracks.ignored, false for every existing track', () async {
    final dir = Directory.systemTemp.createTempSync('mig8');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'v7.db'));
    final db = AppDatabase(NativeDatabase(file, setup: (raw) {
      if (raw.userVersion == 0) {
        raw.execute('CREATE TABLE playlists (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'name TEXT NOT NULL, created_at INTEGER NOT NULL, cover_key TEXT)');
        raw.execute('CREATE TABLE tracks (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'path TEXT NOT NULL, title TEXT NOT NULL, album_key TEXT NOT NULL, '
            'format TEXT NOT NULL, size_bytes INTEGER NOT NULL, mtime_ms INTEGER '
            'NOT NULL, added_at INTEGER NOT NULL, play_count INTEGER NOT NULL '
            'DEFAULT 0, missing INTEGER NOT NULL DEFAULT 0)');
        raw.execute("INSERT INTO tracks (path, title, album_key, format, size_bytes, "
            "mtime_ms, added_at, play_count) VALUES ('/a.mp3', 'Old', 'k', 'mp3', 1, 1, 1, 7)");
        raw.userVersion = 7;
      }
    }));
    final t = (await db.customSelect('SELECT title, play_count, ignored FROM tracks').get()).single;
    expect(t.read<String>('title'), 'Old');
    expect(t.read<int>('play_count'), 7, reason: 'the old counter is untouched');
    expect(t.read<int>('ignored'), 0, reason: 'nothing is hidden by the upgrade');
    await db.close();
  });

  test('v8 database gets tracks.kind (0 for every track) and the podcast tables, and keeps its data', () async {
    final dir = Directory.systemTemp.createTempSync('mig9');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'v8.db'));
    final db = AppDatabase(NativeDatabase(file, setup: (raw) {
      if (raw.userVersion == 0) {
        raw.execute('CREATE TABLE playlists (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'name TEXT NOT NULL, created_at INTEGER NOT NULL, cover_key TEXT)');
        raw.execute('CREATE TABLE tracks (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'path TEXT NOT NULL, title TEXT NOT NULL, album_key TEXT NOT NULL, '
            'format TEXT NOT NULL, size_bytes INTEGER NOT NULL, mtime_ms INTEGER '
            'NOT NULL, added_at INTEGER NOT NULL, play_count INTEGER NOT NULL '
            'DEFAULT 0, missing INTEGER NOT NULL DEFAULT 0, ignored INTEGER NOT NULL DEFAULT 0)');
        raw.execute("INSERT INTO tracks (path, title, album_key, format, size_bytes, "
            "mtime_ms, added_at, play_count) VALUES ('/a.mp3', 'Old', 'k', 'mp3', 1, 1, 1, 7)");
        raw.execute("INSERT INTO tracks (path, title, album_key, format, size_bytes, "
            "mtime_ms, added_at, ignored) VALUES ('/b.mp3', 'Hidden', 'k', 'mp3', 1, 1, 1, 1)");
        raw.userVersion = 8;
      }
    }));
    final rows = await db.customSelect('SELECT title, play_count, ignored, kind FROM tracks ORDER BY id').get();
    expect(rows.map((r) => r.read<int>('kind')), [0, 0], reason: 'every old track is music');
    expect(rows.first.read<int>('play_count'), 7, reason: 'the old counter is untouched');
    expect(rows.last.read<int>('ignored'), 1, reason: 'a hidden track stays hidden');
    expect(await db.select(db.podcasts).get(), isEmpty);
    expect(await db.select(db.podcastEpisodes).get(), isEmpty);
    final names = (await db
            .customSelect("SELECT name FROM sqlite_master WHERE type IN ('table', 'index')")
            .get())
        .map((r) => r.read<String>('name'));
    expect(names, containsAll(['podcasts', 'podcast_episodes', 'tracks_kind', 'podcast_episodes_podcast']));
    await db.close();
  });

  test('podcast rows: a feed address is unique, an episode is unique per podcast, deleting a podcast takes its episodes and a track link goes null', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final pid = await db.into(db.podcasts).insert(PodcastsCompanion.insert(feedUrl: 'https://x/feed', title: 'P', addedAt: 1));
    await expectLater(
      db.into(db.podcasts).insert(PodcastsCompanion.insert(feedUrl: 'https://x/feed', title: 'Other', addedAt: 2)),
      throwsA(anything),
    );
    final trackId = await db.into(db.tracks).insert(TracksCompanion.insert(
        path: '/p/e1.mp3', title: 'E1', albumKey: 'k', format: 'mp3', sizeBytes: 1, mtimeMs: 1, addedAt: 1,
        kind: const Value(1)));
    await db.into(db.podcastEpisodes).insert(PodcastEpisodesCompanion.insert(
        podcastId: pid, guid: 'g1', title: 'E1', audioUrl: 'https://x/e1.mp3', trackId: Value(trackId)));
    await expectLater(
      db.into(db.podcastEpisodes).insert(PodcastEpisodesCompanion.insert(
          podcastId: pid, guid: 'g1', title: 'dup', audioUrl: 'https://x/e1b.mp3')),
      throwsA(anything),
    );
    // The same guid in another podcast is fine.
    final other = await db.into(db.podcasts).insert(PodcastsCompanion.insert(feedUrl: 'https://y/feed', title: 'Q', addedAt: 1));
    await db.into(db.podcastEpisodes).insert(PodcastEpisodesCompanion.insert(
        podcastId: other, guid: 'g1', title: 'E1', audioUrl: 'https://y/e1.mp3'));

    await (db.delete(db.tracks)..where((t) => t.id.equals(trackId))).go();
    final ep = await (db.select(db.podcastEpisodes)..where((e) => e.podcastId.equals(pid))).getSingle();
    expect(ep.trackId, isNull, reason: 'the episode stays listed as not downloaded');

    await (db.delete(db.podcasts)..where((p) => p.id.equals(pid))).go();
    expect((await db.select(db.podcastEpisodes).get()).map((e) => e.podcastId), [other]);
    await db.close();
  });

  test('a fresh install has the v7 tables and indexes too', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final names = (await db
            .customSelect("SELECT name FROM sqlite_master WHERE type IN ('table', 'index')")
            .get())
        .map((r) => r.read<String>('name'));
    expect(names, containsAll(['plays', 'smart_playlists', 'user_tags', 'track_tags', 'plays_track', 'plays_at']));
    await db.close();
  });

  test('deleting a track takes its listens and its tag links with it, and a tag name is unique ignoring case', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.tracks).insert(TracksCompanion.insert(
        path: '/a.mp3', title: 'A', albumKey: 'k', format: 'mp3',
        sizeBytes: 1, mtimeMs: 1, addedAt: 1));
    final trackId = (await db.select(db.tracks).getSingle()).id;
    final tagId = await db.into(db.userTags).insert(UserTagsCompanion.insert(name: 'Live'));
    await db.into(db.trackTags).insert(TrackTagsCompanion.insert(trackId: trackId, tagId: tagId));
    await db.into(db.plays).insert(PlaysCompanion.insert(trackId: trackId, playedAt: 5));
    await expectLater(
      db.into(db.userTags).insert(UserTagsCompanion.insert(name: 'LIVE')),
      throwsA(anything),
    );
    await (db.delete(db.tracks)..where((t) => t.id.equals(trackId))).go();
    expect(await db.select(db.plays).get(), isEmpty);
    expect(await db.select(db.trackTags).get(), isEmpty);
    expect(await db.select(db.userTags).get(), hasLength(1), reason: 'the label stays');
    await db.close();
  });

  test('a v10 database gets the artist_infos table and keeps its tracks', () async {
    final dir = Directory.systemTemp.createTempSync('mig11');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'v10.db'));
    // A current database is made, then put back to version 10 without the table.
    final first = AppDatabase(NativeDatabase(file));
    await first.customSelect('SELECT 1').get();
    await first.customStatement('DROP TABLE artist_infos');
    await first.customStatement('PRAGMA user_version = 10');
    await first.close();

    final db = AppDatabase(NativeDatabase(file));
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    expect(tables.map((r) => r.read<String>('name')), contains('artist_infos'));
    expect(await db.select(db.artistInfos).get(), isEmpty);
    await db.close();
  });
}
