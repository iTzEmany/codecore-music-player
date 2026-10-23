import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/duplicate_repository.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:drift/drift.dart' show Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final v4 = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  group('migration v9 → v10', () {
    test('every existing playlist gets its own uuid and keeps its data, updated_at starts as created_at', () async {
      // A v9 database fabricated in memory before drift reads its version (on
      // a file, each schema statement cost a disk sync: seconds on a busy disk).
      final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
        raw.execute('CREATE TABLE playlists (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'name TEXT NOT NULL, created_at INTEGER NOT NULL, cover_key TEXT)');
        raw.execute("INSERT INTO playlists (name, created_at, cover_key) VALUES ('Rock', 111, 'c1')");
        raw.execute("INSERT INTO playlists (name, created_at, cover_key) VALUES ('Jazz', 222, NULL)");
        raw.execute("INSERT INTO playlists (name, created_at) VALUES ('Mix', 333)");
        raw.execute("CREATE TABLE tracks (id INTEGER PRIMARY KEY AUTOINCREMENT, path TEXT NOT NULL)");
        raw.userVersion = 9;
      }));
      addTearDown(db.close);

      final rows = await db.customSelect('SELECT name, created_at, cover_key, uuid, updated_at FROM playlists ORDER BY id').get();
      expect(rows.map((r) => r.read<String>('name')), ['Rock', 'Jazz', 'Mix']);
      expect(rows.map((r) => r.read<int>('updated_at')), [111, 222, 333], reason: 'the creation time until the first change');
      expect(rows.first.read<String?>('cover_key'), 'c1');
      final uuids = rows.map((r) => r.read<String>('uuid')).toList();
      expect(uuids, everyElement(matches(v4)));
      expect(uuids.toSet(), hasLength(3));

      final index = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'playlists_uuid'").get();
      expect(index, hasLength(1));
      // The index is unique: the same uuid twice is refused.
      await expectLater(
        db.customStatement("UPDATE playlists SET uuid = '${uuids.first}' WHERE name = 'Jazz'"),
        throwsA(anything),
      );
    });

    test('a fresh install and a new playlist have the columns filled', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = PlaylistRepository(db);
      final a = await repo.create('A');
      final b = await repo.create('B');
      final rows = await db.select(db.playlists).get();
      expect(rows.map((r) => r.uuid), everyElement(matches(v4)));
      expect({for (final r in rows) r.uuid}, hasLength(2));
      expect(rows.every((r) => r.updatedAt > 0), isTrue);
      expect(a, isNot(b));
    });
  });

  group('every change stamps updated_at', () {
    late AppDatabase db;
    late PlaylistRepository repo;
    late TrackRepository tracks;
    late int list;
    late List<int> ids;

    Future<void> reset([int? id]) => db.customUpdate(
        'UPDATE playlists SET updated_at = 0 WHERE id = ?',
        variables: [Variable.withInt(id ?? list)], updates: {db.playlists});

    Future<int> stamp([int? id]) async => (await (db.select(db.playlists)..where((x) => x.id.equals(id ?? list))).getSingle()).updatedAt;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = PlaylistRepository(db);
      tracks = TrackRepository(db);
      await tracks.upsertBatch([
        for (var i = 0; i < 4; i++)
          TracksCompanion.insert(
              path: '/m/$i.mp3', title: 'T$i', albumKey: 'k', format: 'mp3',
              sizeBytes: 1, mtimeMs: 1, addedAt: 1, artist: const Value('A')),
      ]);
      ids = [for (var i = 0; i < 4; i++) (await tracks.idForPath('/m/$i.mp3'))!];
      list = await repo.create('Mix');
      await repo.addTracks(list, ids.sublist(0, 3));
      await reset();
    });
    tearDown(() => db.close());

    test('rename and cover', () async {
      await repo.rename(list, 'New name');
      expect(await stamp(), greaterThan(0));
      await reset();
      await repo.setCover(list, 'cover-key');
      expect(await stamp(), greaterThan(0));
    });

    test('adding tracks (only when something was added)', () async {
      await repo.addTracks(list, [ids[0]]); // already there
      expect(await stamp(), 0, reason: 'nothing changed');
      expect(await repo.addTracks(list, [ids[3]]), 1);
      expect(await stamp(), greaterThan(0));
    });

    test('removing, one or many, and putting back', () async {
      await repo.removeTrack(list, ids[0]);
      expect(await stamp(), greaterThan(0));
      await reset();
      final before = await repo.removeTracks(list, [ids[1]]);
      expect(await stamp(), greaterThan(0));
      await reset();
      await repo.restoreTracks(list, before, [ids[1]]);
      expect(await stamp(), greaterThan(0));
    });

    test('reordering by hand and by a sync', () async {
      await repo.reorder(list, 0, 2);
      expect(await stamp(), greaterThan(0));
      await reset();
      await repo.reorderBy(list, {ids[2]: 0});
      expect(await stamp(), greaterThan(0));
    });

    test('an imported track placed in the playlist', () async {
      final imp = await db.into(db.playlistImports).insert(
          PlaylistImportsCompanion.insert(playlistId: list, sourceName: 'x', createdAt: 1));
      expect(await repo.placeImported(list, imp, 5, ids[3]), isTrue);
      expect(await stamp(), greaterThan(0));
      await reset();
      expect(await repo.placeImported(list, imp, 5, ids[3]), isFalse, reason: 'already there: nothing changed');
      expect(await stamp(), 0);
    });

    test('merging duplicates changes the playlists that held them', () async {
      final other = await repo.create('Untouched');
      await reset(other);
      await DuplicateRepository(db).merge(ids[0], [ids[1]]);
      expect(await stamp(), greaterThan(0), reason: 'it had both');
      expect(await stamp(other), 0, reason: 'it had neither');
    });

    test('another playlist is not stamped by a change to this one', () async {
      final other = await repo.create('Other');
      await reset(other);
      await repo.rename(list, 'x');
      expect(await stamp(other), 0);
    });
  });
}
