import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/library/track_editor.dart';
import 'package:codecore/services/tags/tag_reader.dart';
import 'package:codecore/core/text_utils.dart';
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _Tags implements TagReader {
  @override
  Future<TagInfo> read(String path, {bool withCover = true}) async =>
      const TagInfo(title: 'File Title', artist: 'File Artist', album: 'File Album');
}

void main() {
  late AppDatabase db;
  late TrackRepository repo;
  late TrackEditor editor;

  TracksCompanion row(String title, {int mtime = 1}) => TracksCompanion.insert(
      path: '/m/a.mp3',
      title: title,
      albumKey: 'k',
      format: 'mp3',
      sizeBytes: 1,
      mtimeMs: mtime,
      addedAt: 1,
      artist: const Value('Old'));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrackRepository(db);
    editor = TrackEditor(db, _Tags());
  });
  tearDown(() => db.close());

  test('edit survives rescan (unchanged and modified file)', () async {
    await repo.upsertBatch([row('Orig')]);
    var t = (await db.select(db.tracks).get()).single;
    await editor.save(
        t, const TrackEdit(title: 'Unknown Pleasures', artist: 'Joy', album: 'Alb'));
    await repo.upsertBatch([row('FromFile', mtime: 5)]);
    t = (await db.select(db.tracks).get()).single;
    expect(t.title, 'Unknown Pleasures');
    expect(t.artist, 'Joy');
    expect(t.albumKey, 'joy|alb');
    expect(t.userEdited, true);
  });

  test('restore from file clears userEdited', () async {
    await repo.upsertBatch([row('Orig')]);
    var t = (await db.select(db.tracks).get()).single;
    await editor.save(t, const TrackEdit(title: 'X'));
    t = (await db.select(db.tracks).get()).single;
    await editor.restoreFromFile(t);
    t = (await db.select(db.tracks).get()).single;
    expect(t.title, 'File Title');
    expect(t.userEdited, false);
  });

  group('saveMany', () {
    TracksCompanion album(String path, String title, String artist, String albumName,
            {String? albumArtist, String? cover}) =>
        TracksCompanion.insert(
          path: path,
          title: title,
          albumKey: computeAlbumKey(
              albumArtist: albumArtist, artist: artist, album: albumName, directory: '/m'),
          format: 'mp3',
          sizeBytes: 1,
          mtimeMs: 1,
          addedAt: 1,
          artist: Value(artist),
          album: Value(albumName),
          albumArtist: Value(albumArtist),
          hasCover: Value(cover != null),
          coverKey: Value(cover),
        );

    Future<List<Track>> all() => (db.select(db.tracks)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

    test('two albums with different keys end up with one key and the main cover', () async {
      await repo.upsertBatch([
        album('/m/1.mp3', 'One', 'Queen', 'Greatest Hits', cover: 'main'),
        album('/m/2.mp3', 'Two', 'Queen', 'Greatest Hits', cover: 'main'),
        album('/m/3.mp3', 'Three', 'Queen & Friends', 'Greatest Hits (Remaster)', cover: 'other'),
      ]);
      final before = await all();
      expect({for (final t in before) t.albumKey}, hasLength(2));

      await editor.saveMany(before,
          album: 'Greatest Hits', albumArtist: 'Queen', cover: (hasCover: true, coverKey: 'main'));

      final after = await all();
      expect({for (final t in after) t.albumKey}, {'queen|greatest hits'});
      expect(after.map((t) => t.coverKey), everyElement('main'));
      expect(after.map((t) => t.userEdited), everyElement(isTrue));
      expect(after.map((t) => t.artist), ['Queen', 'Queen', 'Queen & Friends'], reason: 'the track artist is untouched');
    });

    test('moving some tracks out of an album makes two albums; a name that exists merges', () async {
      await repo.upsertBatch([
        album('/m/1.mp3', 'One', 'Band', 'Live'),
        album('/m/2.mp3', 'Two', 'Band', 'Live'),
        album('/m/3.mp3', 'Three', 'Band', 'Live'),
      ]);
      final tracks = await all();

      await editor.saveMany([tracks[2]], album: 'Bonus', albumArtist: 'Band');
      expect({for (final t in await all()) t.albumKey}, {'band|live', 'band|bonus'});

      await editor.saveMany([tracks[2]], album: 'live', albumArtist: 'BAND');
      expect({for (final t in await all()) t.albumKey}, {'band|live'});
    });

    test('restoreMany puts every field back, including a track that was not edited', () async {
      await repo.upsertBatch([
        album('/m/1.mp3', 'One', 'Queen', 'A', cover: 'c1'),
        album('/m/2.mp3', 'Two', 'Queen', 'B', cover: 'c2'),
      ]);
      final before = await all();

      final snapshot = await editor.saveMany(before,
          album: 'A', albumArtist: 'Queen', cover: (hasCover: true, coverKey: 'c1'));
      await editor.restoreMany(snapshot);

      final after = await all();
      expect(after.map((t) => t.albumKey), before.map((t) => t.albumKey));
      expect(after.map((t) => t.album), ['A', 'B']);
      expect(after.map((t) => t.coverKey), ['c1', 'c2']);
      expect(after.map((t) => t.userEdited), everyElement(isFalse));
    });

    test('an edit made this way survives a rescan', () async {
      await repo.upsertBatch([album('/m/1.mp3', 'One', 'Band', 'Old')]);
      await editor.saveMany(await all(), album: 'New', albumArtist: 'Band');
      await repo.upsertBatch([album('/m/1.mp3', 'One', 'Band', 'Old').copyWith(mtimeMs: const Value(9))]);
      expect((await all()).single.albumKey, 'band|new');
    });
  });
}
