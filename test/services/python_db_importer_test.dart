import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/migration/python_db_importer.dart';
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sql;

void main() {
  late Directory tmp;
  late AppDatabase db;
  late String oldPath;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('imp');
    db = AppDatabase(NativeDatabase.memory());
    TracksCompanion row(String path, String title, String artist) =>
        TracksCompanion.insert(
            path: path,
            title: title,
            albumKey: 'k',
            format: 'mp3',
            sizeBytes: 1,
            mtimeMs: 1,
            addedAt: 1,
            artist: Value(artist));
    await TrackRepository(db).upsertBatch([
      row('/music/Same Name.mp3', 'Whatever', 'X'),
      row('/music/other.mp3', 'Bohemian Rhapsody', 'Queen'),
      row('/music/lonely.mp3', 'Lonely', 'Y'),
    ]);

    oldPath = p.join(tmp.path, 'old.db');
    final old = sql.sqlite3.open(oldPath);
    old.execute('CREATE TABLE tracks (id TEXT, path TEXT, title TEXT, '
        'artist TEXT, is_favorite INTEGER, lyrics TEXT, curiosities TEXT)');
    old.execute('CREATE TABLE playlists (id TEXT, name TEXT, created_at INTEGER)');
    old.execute('CREATE TABLE playlist_tracks (playlist_id TEXT, track_id TEXT, '
        'position INTEGER)');
    old.execute("INSERT INTO tracks VALUES "
        "('a', 'C:\\\\Users\\\\x\\\\Same name.MP3', 'Other', 'Z', 1, 'words', NULL),"
        "('b', 'D:\\\\Old\\\\file.mp3', 'bohemian  rhapsody', 'QUEEN', 1, NULL, 'trivia'),"
        "('c', 'C:\\\\nothing.mp3', 'No Match', 'Nobody', 1, 'x', NULL)");
    old.execute("INSERT INTO playlists VALUES ('p1', 'Rock', 1)");
    old.execute("INSERT INTO playlist_tracks VALUES "
        "('p1','b',0),('p1','a',1),('p1','c',2)");
    old.close();
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  test('matches by file name then artist+title; ambiguous/none unmatched',
      () async {
    final before = File(oldPath).lengthSync();
    final s = await PythonDbImporter(db).import(oldPath);
    expect(s.favorites, 2);
    expect(s.lyrics, 1);
    expect(s.curiosities, 1);
    expect(s.playlists, 1);
    expect(s.unmatched, 1);
    expect(File(oldPath).lengthSync(), before);

    final tracks = await db.select(db.tracks).get();
    final same = tracks.firstWhere((t) => t.path.endsWith('Same Name.mp3'));
    expect(same.isFavorite, true);
    expect(same.lyricsPlain, 'words');
    final bohemian = tracks.firstWhere((t) => t.title == 'Bohemian Rhapsody');
    expect(bohemian.curiosities, 'trivia');
    expect(tracks.firstWhere((t) => t.title == 'Lonely').isFavorite, false);

    final pls = await db.select(db.playlists).get();
    expect(pls.single.name, 'Rock');
    final pt = await (db.select(db.playlistTracks)
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    expect(pt.map((e) => e.trackId), [bohemian.id, same.id]);
  });

  test('never un-favourites or overwrites existing lyrics', () async {
    await (db.update(db.tracks)..where((t) => t.title.equals('Whatever')))
        .write(const TracksCompanion(lyricsPlain: Value('mine')));
    await PythonDbImporter(db).import(oldPath);
    final t = await (db.select(db.tracks)
          ..where((t) => t.title.equals('Whatever')))
        .getSingle();
    expect(t.lyricsPlain, 'mine');
  });
}
