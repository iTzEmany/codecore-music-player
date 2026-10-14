import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/library/track_editor.dart';
import 'package:codecore/services/tags/tag_reader.dart';
import 'package:drift/drift.dart' show Value;
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
}
