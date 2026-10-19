import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/data/repositories/play_history_repository.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/library/rules/rule_parser.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

TracksCompanion _row(
  String path, {
  String title = 'Song',
  String artist = 'Queen',
  String album = 'Hits',
  String key = 'queen|hits',
  String genre = 'Rock',
}) => TracksCompanion.insert(
  path: path,
  title: title,
  albumKey: key,
  format: 'mp3',
  sizeBytes: 1,
  mtimeMs: 1,
  addedAt: 1,
  album: Value(album),
  artist: Value(artist),
  genre: Value(genre),
  durationMs: const Value(1000),
  playCount: const Value(3),
);

void main() {
  late AppDatabase db;
  late TrackRepository tracks;
  late LibraryQueries queries;
  late int keepId;
  late int hiddenId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tracks = TrackRepository(db);
    queries = LibraryQueries(db);
    await tracks.upsertBatch([
      _row('/keep.flac'),
      _row('/dup.mp3'),
      _row(
        '/other.mp3',
        title: 'Other',
        artist: 'ABBA',
        album: 'Gold',
        key: 'abba|gold',
        genre: 'Pop',
      ),
    ]);
    keepId = (await tracks.idForPath('/keep.flac'))!;
    hiddenId = (await tracks.idForPath('/dup.mp3'))!;
  });
  tearDown(() => db.close());

  test('a hidden track is out of tracks, albums, artists, genres and the lite list', () async {
    await tracks.setIgnored({hiddenId}, true);

    expect(
      (await tracks.watchTracks().first).map((t) => t.id),
      isNot(contains(hiddenId)),
    );
    expect((await tracks.watchTracks(query: 'Song').first).map((t) => t.id), [
      keepId,
    ]);
    expect(
      (await queries.watchAlbums().first)
          .firstWhere((a) => a.title == 'Hits')
          .trackCount,
      1,
    );
    expect(
      (await queries.watchAlbumTracks('queen|hits').first).map((t) => t.id),
      [keepId],
    );
    final queen = (await queries.watchArtists().first).firstWhere(
      (a) => a.name == 'Queen',
    );
    expect(queen.trackCount, 1);
    expect((await queries.watchArtistTracks('queen').first).map((t) => t.id), [
      keepId,
    ]);
    expect(
      (await queries.watchGenres().first)
          .firstWhere((g) => g.name == 'Rock')
          .trackCount,
      1,
    );
    expect((await queries.watchGenreTracks('Rock').first).map((t) => t.id), [
      keepId,
    ]);
    expect(
      (await queries.watchTopTracks().first).map((t) => t.id),
      isNot(contains(hiddenId)),
    );
    expect(
      (await tracks.liteEntries()).map((e) => e.id),
      isNot(contains(hiddenId)),
    );
  });

  test('a hidden track does not match rule searches or smart playlists, and is not counted', () async {
    await tracks.setIgnored({hiddenId}, true);
    final all = parseRules('queen').expr;

    expect(await tracks.countByRules(all), 1);
    expect((await tracks.watchByRules(all).first).map((t) => t.id), [keepId]);
  });

  test('a hidden track leaves playlists and the history', () async {
    final playlists = PlaylistRepository(db);
    final list = await playlists.create('Mix');
    await playlists.addTracks(list, [keepId, hiddenId]);
    final history = PlayHistoryRepository(db);
    await history.start(keepId, 1000);
    await history.start(hiddenId, 2000);

    await tracks.setIgnored({hiddenId}, true);

    expect((await playlists.watchTracks(list).first).map((t) => t.id), [
      keepId,
    ]);
    expect((await history.watchHistory().first).map((e) => e.track.id), [
      keepId,
    ]);
  });

  test(
    'restoring shows it again, and watchIgnored lists exactly the hidden ones',
    () async {
      await tracks.setIgnored({hiddenId}, true);
      expect((await tracks.watchIgnored().first).map((t) => t.id), [hiddenId]);

      await tracks.setIgnored({hiddenId}, false);
      expect(await tracks.watchIgnored().first, isEmpty);
      expect(
        (await tracks.watchTracks().first).map((t) => t.id),
        containsAll([keepId, hiddenId]),
      );
    },
  );

  test('a rescan of the same file refreshes it but leaves it hidden', () async {
    await tracks.setIgnored({hiddenId}, true);
    await tracks.markMissing({'/dup.mp3'}, true);

    // The scanner finds the file again (and its size changed).
    await tracks.upsertBatch([
      _row('/dup.mp3').copyWith(sizeBytes: const Value(99)),
    ]);

    final row = (await tracks.getById(hiddenId))!;
    expect(row.ignored, isTrue, reason: 'the scanner never clears ignored');
    expect(
      row.missing,
      isFalse,
      reason: 'but it does clear missing, as before',
    );
    expect(row.sizeBytes, 99);
    final shown = (await tracks.watchTracks().first).map((t) => t.id).toSet();
    expect(shown, {keepId, (await tracks.idForPath('/other.mp3'))!});
  });

  test(
    'setIgnored with no ids does nothing and many ids are handled in chunks',
    () async {
      await tracks.setIgnored({}, true);
      expect(await tracks.watchIgnored().first, isEmpty);

      await tracks.upsertBatch([
        for (var i = 0; i < 1200; i++) _row('/bulk/$i.mp3', title: 'B$i'),
      ]);
      final ids = (await tracks.watchTracks(query: 'B').first)
          .map((t) => t.id)
          .toSet();
      await tracks.setIgnored(ids, true);
      expect((await tracks.watchIgnored().first).length, ids.length);
    },
  );
}
