import 'dart:async';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/smart_playlist_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TrackRepository tracks;
  late SmartPlaylistRepository repo;
  late List<int> ids;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tracks = TrackRepository(db);
    repo = SmartPlaylistRepository(db, tracks);
    final specs = [
      ('Alpha', 'Daft Punk', 1999, 2, true),
      ('Bravo', 'Daft Punk', 2001, 9, false),
      ('Charlie', 'Pink Floyd', 1973, 0, false),
      ('Delta', 'Pink Floyd', 1979, 5, true),
      ('Echo', 'Lucio Dalla', 1980, 0, false),
    ];
    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      await db.into(db.tracks).insert(TracksCompanion.insert(
            path: '/${s.$1}.mp3', title: s.$1, albumKey: 'k', format: 'mp3',
            sizeBytes: 1, mtimeMs: 1, addedAt: 1000 + i, artist: Value(s.$2), year: Value(s.$3),
            playCount: Value(s.$4), isFavorite: Value(s.$5)));
    }
    ids = (await db.select(db.tracks).get()).map((t) => t.id).toList();
  });
  tearDown(() => db.close());

  /// The tracks of the smart playlist [id], as its screen gets them.
  Future<List<Track>> tracksOf(int id, {int randomSeed = 1}) async =>
      repo.watchTracks((await repo.get(id))!, randomSeed: randomSeed).first;

  test('create keeps the name, the rules in canonical form, the order and the limit', () async {
    final id = await repo.create(
        name: '  Anni 70  ', rules: 'year:1970..1979 ARTIST:floyd', sort: SmartSort.title, limit: 20);
    final p = (await repo.get(id))!;
    expect(p.name, 'Anni 70');
    expect(p.rules, 'anno:1970..1979 artista:floyd');
    expect(p.sort, 'title');
    expect(p.limitCount, 20);
    expect(p.createdAt, greaterThan(0));
    final plain = (await repo.get(await repo.create(name: 'x', rules: 'rock')))!;
    expect(plain.sort, isNull, reason: 'the default order is stored as nothing');
    expect(plain.limitCount, isNull);
  });

  test('the list is by name, ignoring case, and follows changes', () async {
    await repo.create(name: 'beta', rules: '');
    await repo.create(name: 'Alfa', rules: '');
    expect((await repo.watchAll().first).map((p) => p.name), ['Alfa', 'beta']);
  });

  test('update changes only what is given, and can clear the limit', () async {
    final id = await repo.create(name: 'A', rules: 'preferiti', sort: SmartSort.year, limit: 5);
    await repo.update(id, name: ' B ');
    var p = (await repo.get(id))!;
    expect((p.name, p.rules, p.sort, p.limitCount), ('B', 'preferiti', 'year', 5));
    await repo.update(id, rules: 'mai-ascoltati', sort: SmartSort.defaultOrder, clearLimit: true);
    p = (await repo.get(id))!;
    expect((p.rules, p.sort, p.limitCount), ('mai-ascoltati', null, null));
  });

  test('delete removes the playlist and nothing else', () async {
    final id = await repo.create(name: 'A', rules: '');
    await repo.delete(id);
    expect(await repo.get(id), isNull);
    expect(await db.select(db.tracks).get(), hasLength(5));
  });

  test('the tracks are the rules\' matches, in the saved order, up to the limit', () async {
    final id = await repo.create(name: 'Floyd', rules: 'artista:floyd', sort: SmartSort.title);
    expect((await tracksOf(id)).map((t) => t.title), ['Charlie', 'Delta']);
    await repo.update(id, sort: SmartSort.year);
    expect((await tracksOf(id)).map((t) => t.title), ['Delta', 'Charlie'], reason: 'newest year first');
    await repo.update(id, limit: 1);
    expect(await tracksOf(id), hasLength(1));
  });

  test('most played, recently added', () async {
    final top = await repo.create(name: 'Top', rules: 'ascolti>0', sort: SmartSort.mostPlayed);
    expect((await tracksOf(top)).map((t) => t.title), ['Bravo', 'Delta', 'Alpha']);
    final recent = await repo.create(name: 'New', rules: '', sort: SmartSort.addedAt, limit: 2);
    expect((await tracksOf(recent)).map((t) => t.title), ['Echo', 'Delta']);
  });

  test('never played', () async {
    final id = await repo.create(name: 'Never', rules: 'mai-ascoltati', sort: SmartSort.title);
    expect((await tracksOf(id)).map((t) => t.title), ['Charlie', 'Echo']);
  });

  test('a random order holds for a seed and changes with another', () async {
    final id = await repo.create(name: 'Any', rules: '', sort: SmartSort.random);
    final a = (await tracksOf(id, randomSeed: 3)).map((t) => t.id).toList();
    final b = (await tracksOf(id, randomSeed: 3)).map((t) => t.id).toList();
    final c = (await tracksOf(id, randomSeed: 99)).map((t) => t.id).toList();
    expect(a, b);
    expect(a.toSet(), ids.toSet());
    expect(a, isNot(c));
  });

  test('the list changes by itself: a track that becomes a favourite joins', () async {
    final id = await repo.create(name: 'Fav', rules: 'preferiti', sort: SmartSort.title);
    // Each list is awaited before the next change: no sleeping, no timing.
    final lists = StreamIterator(repo.watchTracks((await repo.get(id))!).map((l) => [for (final t in l) t.title]));
    addTearDown(lists.cancel);
    Future<List<String>> next() async {
      expect(await lists.moveNext(), isTrue);
      return lists.current;
    }

    expect(await next(), ['Alpha', 'Delta']);
    await tracks.setFavorite(ids[1], true); // Bravo joins
    expect(await next(), ['Alpha', 'Bravo', 'Delta']);
    await tracks.setFavorite(ids[0], false); // Alpha leaves
    expect(await next(), ['Bravo', 'Delta']);
  });

  test('count tells how many tracks some rules select', () async {
    expect(await repo.count('artista:floyd'), 2);
    expect(await repo.count(''), 5);
    expect(await repo.count('anno>2100'), 0);
    expect(await repo.count('artista:'), 5, reason: 'half-typed: everything');
  });

  test('SmartSort reads its name, and falls back to the default', () {
    expect(SmartSort.fromName('random'), SmartSort.random);
    expect(SmartSort.fromName(null), SmartSort.defaultOrder);
    expect(SmartSort.fromName('???'), SmartSort.defaultOrder);
  });
}
