import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/smart_playlist_repository.dart';
import 'package:codecore/data/repositories/tag_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TagRepository repo;
  late List<int> ids;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TagRepository(db);
    for (var i = 0; i < 6; i++) {
      await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/$i.mp3', title: 'T$i', albumKey: 'k', format: 'mp3',
          sizeBytes: 1, mtimeMs: 1, addedAt: 1));
    }
    ids = (await db.select(db.tracks).get()).map((t) => t.id).toList();
  });
  tearDown(() => db.close());

  test('a tag name is one tag whatever its case or spaces', () async {
    final a = await repo.create('Live');
    expect(await repo.create('live'), a);
    expect(await repo.create('  LIVE  '), a);
    expect(await repo.create('Studio'), isNot(a));
    expect((await repo.watchAll().first), hasLength(2));
  });

  test('the list is by name with the number of tracks, zero included', () async {
    final live = await repo.create('live');
    final calm = await repo.create('Calm');
    await repo.create('zen');
    await repo.assign([ids[0], ids[1], ids[2]], live);
    await repo.assign([ids[0]], calm);
    final all = await repo.watchAll().first;
    expect(all.map((t) => t.tag.name), ['Calm', 'live', 'zen']);
    expect(all.map((t) => t.trackCount), [1, 3, 0]);
  });

  test('assigning many tracks is one go, skips the ones that have it, and is undone by unassign', () async {
    final live = await repo.create('live');
    expect(await repo.assign(ids, live), 6);
    expect(await repo.assign(ids, live), 0, reason: 'already there');
    expect(await repo.assign([ids[0], ids[1]], live), 0);
    expect(await repo.unassign([ids[0], ids[1], ids[5]], live), 3);
    expect((await repo.watchAll().first).single.trackCount, 3);
    expect(await repo.unassign(ids, live), 3);
    expect((await repo.watchAll().first).single.trackCount, 0);
  });

  test('a failing assignment changes nothing at all', () async {
    final live = await repo.create('live');
    await expectLater(repo.assign([ids[0], ids[1], 99999], live), throwsA(anything));
    expect((await repo.watchAll().first).single.trackCount, 0, reason: 'rolled back');
  });

  test('countsAmong says how many of the given tracks carry each tag', () async {
    final live = await repo.create('live');
    final calm = await repo.create('calm');
    await repo.assign([ids[0], ids[1], ids[2]], live);
    await repo.assign([ids[2]], calm);
    expect(await repo.countsAmong([ids[0], ids[1]]), {live: 2});
    expect(await repo.countsAmong([ids[2], ids[3]]), {live: 1, calm: 1});
    expect(await repo.countsAmong([ids[4]]), isEmpty);
    expect(await repo.countsAmong(const []), isEmpty);
  });

  test('renaming changes the name, ignores an empty one and refuses a taken one', () async {
    final live = await repo.create('live');
    final calm = await repo.create('calm');
    expect(await repo.rename(live, '  Dal vivo '), isTrue);
    expect((await repo.watchAll().first).map((t) => t.tag.name), ['calm', 'Dal vivo']);
    expect(await repo.rename(live, ''), isFalse);
    expect(await repo.rename(live, 'CALM'), isFalse, reason: 'taken ignoring case');
    expect(await repo.rename(calm, 'Calm'), isTrue, reason: 'only the case changes');
    expect(await repo.rename(99999, 'x'), isFalse);
  });

  test('renaming a tag rewrites the smart playlists that name it, and only those', () async {
    final live = await repo.create('live');
    final smart = SmartPlaylistRepository(db, TrackRepository(db));
    final a = await smart.create(name: 'A', rules: 'tag:live artista:floyd');
    final b = await smart.create(name: 'B', rules: '-tag:live OR preferiti');
    final c = await smart.create(name: 'C', rules: 'tag:studio genere:rock');
    expect(await repo.rename(live, 'Dal vivo'), isTrue);
    expect((await smart.get(a))!.rules, 'tag:"Dal vivo" artista:floyd');
    expect((await smart.get(b))!.rules, '-tag:"Dal vivo" OR preferiti');
    expect((await smart.get(c))!.rules, 'tag:studio genere:rock');
    // And the rule still selects the same tracks.
    await repo.assign([ids[0], ids[3]], live);
    expect((await smart.count('tag:"Dal vivo"')), 2);
  });

  test('a refused rename leaves the rules as they were', () async {
    final live = await repo.create('live');
    await repo.create('calm');
    final smart = SmartPlaylistRepository(db, TrackRepository(db));
    final a = await smart.create(name: 'A', rules: 'tag:live');
    expect(await repo.rename(live, 'calm'), isFalse);
    expect((await smart.get(a))!.rules, 'tag:live');
  });

  test('deleting a tag unlinks it and nothing else', () async {
    final live = await repo.create('live');
    await repo.assign(ids, live);
    final smart = SmartPlaylistRepository(db, TrackRepository(db));
    final a = await smart.create(name: 'A', rules: 'tag:live');
    await repo.delete(live);
    expect(await repo.watchAll().first, isEmpty);
    expect(await db.select(db.trackTags).get(), isEmpty);
    expect(await TrackRepository(db).countAll(), 6, reason: 'every track is still there');
    expect((await smart.get(a))!.rules, 'tag:live', reason: 'the rule is user data too');
  });

  test('deleting a track takes it out of the counts', () async {
    final live = await repo.create('live');
    await repo.assign([ids[0], ids[1]], live);
    await TrackRepository(db).deleteTrack(ids[0]);
    expect((await repo.watchAll().first).single.trackCount, 1);
  });

  test('the colour can be set and cleared', () async {
    final live = await repo.create('live', color: 3);
    expect((await repo.byName('live'))!.color, 3);
    await repo.setColor(live, null);
    expect((await repo.byName('live'))!.color, isNull);
  });
}
