import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/duplicate_repository.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

TracksCompanion _row(
  String path, {
  String title = 'Song',
  bool fav = false,
  int plays = 0,
  int? lastPlayed,
  String? lyrics,
  String? curiosities,
  bool edited = false,
  bool cover = false,
}) => TracksCompanion.insert(
  path: path,
  title: title,
  albumKey: 'k',
  format: 'mp3',
  sizeBytes: 1,
  mtimeMs: 1,
  addedAt: 1,
  artist: const Value('Band'),
  isFavorite: Value(fav),
  playCount: Value(plays),
  lastPlayedAt: Value(lastPlayed),
  lyricsPlain: Value(lyrics),
  curiosities: Value(curiosities),
  userEdited: Value(edited),
  hasCover: Value(cover),
  coverKey: Value(cover ? 'cover-$path' : null),
);

void main() {
  late AppDatabase db;
  late TrackRepository tracks;
  late PlaylistRepository playlists;
  late DuplicateRepository repo;
  late int keep, dupA, dupB, other, p1, p2, p3, p4;

  Future<List<int>> listOf(int playlistId) async => [
    for (final r in await (db.select(db.playlistTracks)
          ..where((t) => t.playlistId.equals(playlistId))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get())
      r.trackId,
  ];

  Future<List<int>> positionsOf(int playlistId) async => [
    for (final r in await (db.select(db.playlistTracks)
          ..where((t) => t.playlistId.equals(playlistId))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get())
      r.position,
  ];

  Future<void> build({void Function(String)? onStep}) async {
    db = AppDatabase(NativeDatabase.memory());
    tracks = TrackRepository(db);
    playlists = PlaylistRepository(db);
    repo = DuplicateRepository(db, onStep: onStep);
    await tracks.upsertBatch([
      _row('/keep.flac', plays: 5, lastPlayed: 100, curiosities: 'KEEP'),
      _row('/a.mp3', fav: true, plays: 2, lastPlayed: 300, lyrics: 'from A', curiosities: 'from A'),
      _row('/b.mp3', plays: 1, lastPlayed: 200, lyrics: 'from B', edited: true, title: 'Edited', cover: true),
      _row('/other.mp3', title: 'Other'),
    ]);
    keep = (await tracks.idForPath('/keep.flac'))!;
    dupA = (await tracks.idForPath('/a.mp3'))!;
    dupB = (await tracks.idForPath('/b.mp3'))!;
    other = (await tracks.idForPath('/other.mp3'))!;
    p1 = await playlists.create('P1');
    p2 = await playlists.create('P2');
    p3 = await playlists.create('P3');
    p4 = await playlists.create('P4');
    await playlists.addTracks(p1, [other, dupA, keep]);
    await playlists.addTracks(p2, [dupB, keep]);
    await playlists.addTracks(p3, [other, keep]);
    await playlists.addTracks(p4, [dupA, dupB]);
    await db.into(db.plays).insert(PlaysCompanion.insert(trackId: dupA, playedAt: 10));
    await db.into(db.plays).insert(PlaysCompanion.insert(trackId: dupA, playedAt: 20));
    await db.into(db.plays).insert(PlaysCompanion.insert(trackId: dupB, playedAt: 30));
    await db.into(db.plays).insert(PlaysCompanion.insert(trackId: keep, playedAt: 40));
    final rock = await db.into(db.userTags).insert(UserTagsCompanion.insert(name: 'rock'));
    final live = await db.into(db.userTags).insert(UserTagsCompanion.insert(name: 'live'));
    final chill = await db.into(db.userTags).insert(UserTagsCompanion.insert(name: 'chill'));
    for (final (t, g) in [(keep, rock), (dupA, rock), (dupA, live), (dupB, chill)]) {
      await db.into(db.trackTags).insert(TrackTagsCompanion.insert(trackId: t, tagId: g));
    }
    final imp = await db.into(db.playlistImports).insert(PlaylistImportsCompanion.insert(
        playlistId: p1, sourceName: 'x.csv', createdAt: 1));
    await db.into(db.playlistImportItems).insert(PlaylistImportItemsCompanion.insert(
        importId: imp, rowIndex: 0, title: 'Song', artists: 'Band', trackId: Value(dupA)));
  }

  tearDown(() => db.close());

  test('the kept track gets the favourite, the summed plays, the latest date and the missing texts', () async {
    await build();
    await repo.merge(keep, [dupA, dupB]);

    final k = (await tracks.getById(keep))!;
    expect(k.isFavorite, isTrue, reason: 'one of them was a favourite');
    expect(k.playCount, 8);
    expect(k.lastPlayedAt, 300);
    expect(k.lyricsPlain, 'from A', reason: 'the first duplicate that has lyrics');
    expect(k.curiosities, 'KEEP', reason: 'the kept track keeps what it already had');
    expect(k.userEdited, isTrue);
    expect(k.title, 'Edited', reason: 'the user edit travels to the kept track');
    expect(k.hasCover, isTrue);
    expect(k.coverKey, 'cover-/b.mp3');
    expect(k.ignored, isFalse);
  });

  test('a kept track that was edited keeps its own edit and cover', () async {
    await build();
    await (db.update(db.tracks)..where((t) => t.id.equals(keep))).write(
        const TracksCompanion(userEdited: Value(true), title: Value('Mine'), hasCover: Value(true), coverKey: Value('mine')));
    await repo.merge(keep, [dupA, dupB]);

    final k = (await tracks.getById(keep))!;
    expect(k.title, 'Mine');
    expect(k.coverKey, 'mine');
  });

  test('the duplicates are hidden, not deleted', () async {
    await build();
    await repo.merge(keep, [dupA, dupB]);

    expect((await tracks.getById(dupA))!.ignored, isTrue);
    expect((await tracks.getById(dupB))!.ignored, isTrue);
    expect((await tracks.getById(other))!.ignored, isFalse);
    expect((await tracks.watchIgnored().first).map((t) => t.id), unorderedEquals([dupA, dupB]));
  });

  test('in each playlist the kept track takes the place of the first of the group, with no doubles', () async {
    await build();
    await repo.merge(keep, [dupA, dupB]);

    expect(await listOf(p1), [other, keep], reason: 'dupA gave its place to keep, the old keep slot went');
    expect(await listOf(p2), [keep]);
    expect(await listOf(p3), [other, keep], reason: 'untouched');
    expect(await listOf(p4), [keep], reason: 'a playlist that only had duplicates now has the kept track');
    for (final p in [p1, p2, p3, p4]) {
      expect(await positionsOf(p), List.generate((await listOf(p)).length, (i) => i));
    }
  });

  test('listens, tags and import rows move to the kept track', () async {
    await build();
    await repo.merge(keep, [dupA, dupB]);

    final plays = await db.select(db.plays).get();
    expect(plays.map((p) => p.trackId).toSet(), {keep});
    expect(plays, hasLength(4));
    final links = await db.select(db.trackTags).get();
    expect(links.map((l) => l.trackId).toSet(), {keep});
    expect(links, hasLength(3), reason: 'rock once, live and chill moved');
    final item = await db.select(db.playlistImportItems).getSingle();
    expect(item.trackId, keep);
  });

  test('merging a track with itself or with nothing changes nothing', () async {
    await build();
    await repo.merge(keep, []);
    await repo.merge(keep, [keep]);
    expect((await tracks.getById(keep))!.playCount, 5);
    expect((await tracks.getById(keep))!.ignored, isFalse);
  });

  test('an error half way through leaves everything as it was', () async {
    await build(onStep: (step) {
      if (step == 'tags') throw StateError('disk full');
    });
    final before = {
      'p1': await listOf(p1),
      'p4': await listOf(p4),
      'plays': (await db.select(db.plays).get()).map((p) => '${p.trackId}:${p.playedAt}').toList()..sort(),
    };

    await expectLater(repo.merge(keep, [dupA, dupB]), throwsA(isA<StateError>()));

    final k = (await tracks.getById(keep))!;
    expect(k.playCount, 5);
    expect(k.isFavorite, isFalse);
    expect(k.lyricsPlain, isNull);
    expect((await tracks.getById(dupA))!.ignored, isFalse);
    expect((await tracks.getById(dupB))!.ignored, isFalse);
    expect(await listOf(p1), before['p1']);
    expect(await listOf(p4), before['p4']);
    expect((await db.select(db.plays).get()).map((p) => '${p.trackId}:${p.playedAt}').toList()..sort(), before['plays']);
    expect((await db.select(db.trackTags).get()).map((l) => l.trackId).toSet(), {keep, dupA, dupB});
    expect((await db.select(db.playlistImportItems).getSingle()).trackId, dupA);
  });

  test('merging a track that does not exist fails without changes', () async {
    await build();
    await expectLater(repo.merge(keep, [dupA, 9999]), throwsA(anything));
    expect((await tracks.getById(dupA))!.ignored, isFalse);
    expect((await tracks.getById(keep))!.playCount, 5);
  });
}
