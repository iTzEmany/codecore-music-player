import 'package:codecore/data/db/app_database.dart';
import 'dart:convert';

import 'package:codecore/data/repositories/backup_merge.dart';
import 'package:codecore/data/repositories/backup_queries.dart';
import 'package:codecore/data/repositories/playlist_sync_repository.dart';
import 'package:codecore/services/backup/user_data.dart';
import 'package:drift/drift.dart' show OrderingTerm, Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

TrackRef ref(String name) => TrackRef(title: name, relPath: '$name.mp3', artist: 'Art', durationMs: 60000);

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final folder = await db.into(db.folders).insert(FoldersCompanion.insert(path: '/music', addedAt: 1));
    for (final n in ['a', 'b', 'c']) {
      await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/music/$n.mp3', title: n, albumKey: 'k', format: 'mp3', sizeBytes: 1, mtimeMs: 1, addedAt: 1,
          artist: const Value('Art'), durationMs: const Value(60000), folderId: Value(folder)));
    }
  });
  tearDown(() => db.close());

  Future<MergeReport> merge(UserData d) async =>
      mergeUserData(db, d, await PlaylistSyncRepository(db).resolver());

  Future<Track> track(String t) => (db.select(db.tracks)..where((r) => r.title.equals(t))).getSingle();

  test('a favourite is added, plays keep the max and the latest date, lyrics fill only empty fields', () async {
    await (db.update(db.tracks)..where((r) => r.title.equals('b'))).write(const TracksCompanion(
        playCount: Value(9), lastPlayedAt: Value(500), lyricsPlain: Value('mine')));
    final r = await merge(UserData(createdAt: 1, tracks: [
      TrackUserData(ref: ref('a'), favorite: true, playCount: 4, lastPlayedAt: 100, lyricsPlain: 'theirs', curiosities: 'fun'),
      TrackUserData(ref: ref('b'), playCount: 3, lastPlayedAt: 900, lyricsPlain: 'theirs'),
    ]));
    expect(r.recognized, 2);
    expect(r.favoritesAdded, 1);
    final a = await track('a');
    expect(a.isFavorite, isTrue);
    expect((a.playCount, a.lastPlayedAt, a.lyricsPlain, a.curiosities), (4, 100, 'theirs', 'fun'));
    final b = await track('b');
    expect((b.playCount, b.lastPlayedAt, b.lyricsPlain), (9, 900, 'mine'));
  });

  test('a hand edit applies to an untouched track but never over a local edit', () async {
    await (db.update(db.tracks)..where((r) => r.title.equals('c'))).write(
        const TracksCompanion(userEdited: Value(true), genre: Value('Local')));
    await merge(UserData(createdAt: 1, tracks: [
      TrackUserData(ref: ref('a'), edit: const TrackEditData(title: 'A!', artist: 'New', album: 'Alb', genre: 'Pop')),
      TrackUserData(ref: ref('c'), edit: const TrackEditData(title: 'C!', genre: 'Theirs')),
    ]));
    final a = await (db.select(db.tracks)..where((r) => r.path.equals('/music/a.mp3'))).getSingle();
    expect((a.title, a.artist, a.album, a.genre, a.userEdited), ('A!', 'New', 'Alb', 'Pop', true));
    final c = await track('c');
    expect((c.title, c.genre), ('c', 'Local'));
  });

  test('a playlist with a free name is created, an existing name becomes «(ripristinata)»; missing items are counted', () async {
    final id = await db.into(db.playlists).insert(PlaylistsCompanion.insert(name: 'Mix', createdAt: 1));
    await db.into(db.playlistTracks).insert(PlaylistTracksCompanion.insert(playlistId: id, trackId: 1, position: 0));
    final r = await merge(UserData(createdAt: 1, playlists: [
      PlaylistData(name: 'Mix', createdAt: 5, items: [ref('c'), ref('zzz'), ref('a'), ref('c')]),
      const PlaylistData(name: 'Nuova', createdAt: 6),
    ]));
    expect(r.playlistsCreated, 2);
    expect(r.playlistItemsSkipped, 1);
    final names = [for (final p in await db.select(db.playlists).get()) p.name];
    expect(names, unorderedEquals(['Mix', 'Mix (ripristinata)', 'Nuova']));
    final restored = await (db.select(db.playlists)..where((p) => p.name.equals('Mix (ripristinata)'))).getSingle();
    final items = await (db.select(db.playlistTracks)..where((t) => t.playlistId.equals(restored.id))).get();
    expect((items..sort((a, b) => a.position.compareTo(b.position))).map((i) => i.trackId), [3, 1]);
    // The original playlist is untouched.
    expect((await (db.select(db.playlistTracks)..where((t) => t.playlistId.equals(id))).get()), hasLength(1));
    expect(restored.uuid, isNot((await (db.select(db.playlists)..where((p) => p.id.equals(id))).getSingle()).uuid));
  });

  test('merging a playlist already here (same uuid) appends only the missing tracks, no copy', () async {
    final id = await db.into(db.playlists).insert(PlaylistsCompanion.insert(name: 'Mix', createdAt: 1));
    final uuid = (await (db.select(db.playlists)..where((p) => p.id.equals(id))).getSingle()).uuid;
    await db.into(db.playlistTracks).insert(PlaylistTracksCompanion.insert(playlistId: id, trackId: 1, position: 0));
    final r = await merge(UserData(createdAt: 1, playlists: [
      PlaylistData(name: 'Renamed', uuid: uuid, createdAt: 1, items: [ref('a'), ref('b')]),
    ]));
    expect(r.playlistsCreated, 0);
    expect(await db.select(db.playlists).get(), hasLength(1));
    final items = await (db.select(db.playlistTracks)..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    expect(items.map((i) => i.trackId), [1, 2]);
  });

  test('without a uuid, same name and same tracks is the same playlist; merging twice never doubles', () async {
    final id = await db.into(db.playlists).insert(PlaylistsCompanion.insert(name: 'Mix', createdAt: 1));
    await db.into(db.playlistTracks).insert(PlaylistTracksCompanion.insert(playlistId: id, trackId: 1, position: 0));
    final d = UserData(createdAt: 1, playlists: [PlaylistData(name: 'Mix', createdAt: 1, items: [ref('a')])]);
    await merge(d);
    await merge(d);
    expect(await db.select(db.playlists).get(), hasLength(1));
    expect(await db.select(db.playlistTracks).get(), hasLength(1));
  });

  test('a new playlist keeps the backup uuid, so a second merge does not copy it', () async {
    final d = UserData(createdAt: 1, playlists: [
      PlaylistData(name: 'Nuova', uuid: 'u-1', createdAt: 1, items: [ref('a')]),
    ]);
    await merge(d);
    await merge(d);
    final all = await db.select(db.playlists).get();
    expect(all.map((p) => (p.name, p.uuid)), [('Nuova', 'u-1')]);
    expect(await db.select(db.playlistTracks).get(), hasLength(1));
  });

  test('a track the library lacks is listed as not found, and nothing is deleted', () async {
    final before = (await db.select(db.tracks).get()).length;
    final r = await merge(UserData(createdAt: 1, tracks: [
      TrackUserData(ref: ref('ghost'), favorite: true),
      TrackUserData(ref: ref('a')),
    ]));
    expect(r.notFound, ['ghost']);
    expect((await db.select(db.tracks).get()).length, before);
  });

  group('saved radio stations', () {
    RadioData radio(String id, String name, {String url = 'http://s'}) =>
        RadioData(stationId: id, name: name, streamUrl: '$url/$id', tags: 'pop,rock', bitrate: 128, hls: id == 'b');

    Future<List<SavedRadio>> saved() => (db.select(db.radioStations)
          ..orderBy([(r) => OrderingTerm.asc(r.position)]))
        .get();

    test('export, JSON, merge into an empty database: same stations in the same order', () async {
      for (final (i, id) in ['c', 'a', 'b'].indexed) {
        await db.into(db.radioStations).insert(RadioStationsCompanion.insert(
            stationId: id, name: 'N$id', streamUrl: 'http://s/$id', position: i,
            tags: const Value('pop,rock'), hls: Value(id == 'b'), lastPlayedAt: const Value(7)));
      }
      final exported = await collectUserData(db);
      final json = jsonDecode(jsonEncode(exported.toJson())) as Map<String, dynamic>;
      final restored = UserData.fromJson(json);
      expect([for (final r in restored.radios) r.stationId], ['c', 'a', 'b']);

      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      final r = await mergeUserData(other, restored, await PlaylistSyncRepository(other).resolver());
      expect(r.radiosAdded, 3);
      final rows = await (other.select(other.radioStations)..orderBy([(x) => OrderingTerm.asc(x.position)])).get();
      expect([for (final x in rows) (x.stationId, x.name, x.streamUrl, x.tags, x.hls, x.lastPlayedAt)], [
        ('c', 'Nc', 'http://s/c', 'pop,rock', false, 7),
        ('a', 'Na', 'http://s/a', 'pop,rock', false, 7),
        ('b', 'Nb', 'http://s/b', 'pop,rock', true, 7),
      ]);
    });

    test('merging twice adds nothing; a station already here is untouched; new ones go last', () async {
      await db.into(db.radioStations).insert(RadioStationsCompanion.insert(
          stationId: 'a', name: 'Mine', streamUrl: 'http://mine/a', position: 0));
      final data = UserData(createdAt: 1, radios: [radio('b', 'B'), radio('a', 'Theirs'), radio('c', 'C')]);
      expect((await merge(data)).radiosAdded, 2);
      expect((await merge(data)).radiosAdded, 0);
      final rows = await saved();
      expect([for (final r in rows) (r.stationId, r.name)], [('a', 'Mine'), ('b', 'B'), ('c', 'C')]);
    });

    test('a hand-typed address is recognised by its URL even under another id', () async {
      await db.into(db.radioStations).insert(RadioStationsCompanion.insert(
          stationId: 'manual:1', name: 'Mine', streamUrl: 'http://s/manual:2', position: 0));
      final r = await merge(UserData(createdAt: 1, radios: [radio('manual:2', 'Same address')]));
      expect(r.radiosAdded, 0);
      expect(await saved(), hasLength(1));
    });

    test('a user_data.json without radios still reads, and writes none', () {
      final old = UserData.fromJson({'format': 1, 'createdAt': 5, 'tracks': [], 'playlists': []});
      expect(old.radios, isEmpty);
      expect(old.toJson().containsKey('radios'), isFalse);
    });
  });
}
