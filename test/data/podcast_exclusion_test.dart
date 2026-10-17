import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/duplicate_repository.dart';
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
  required String title,
  required String artist,
  required String album,
  required String key,
  String genre = 'Rock',
  int kind = 0,
  int plays = 3,
}) =>
    TracksCompanion.insert(
      path: path,
      title: title,
      albumKey: key,
      format: 'mp3',
      sizeBytes: 100,
      mtimeMs: 1,
      addedAt: 1,
      artist: Value(artist),
      album: Value(album),
      genre: Value(genre),
      durationMs: const Value(60000),
      playCount: Value(plays),
      kind: Value(kind),
    );

void main() {
  late AppDatabase db;
  late TrackRepository tracks;
  late LibraryQueries queries;
  late int songId, episodeId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tracks = TrackRepository(db);
    queries = LibraryQueries(db);
    await tracks.upsertBatch([
      _row('/m/song.mp3', title: 'Song', artist: 'Band', album: 'Hits', key: 'band|hits'),
      // A downloaded episode: the podcast's title is its artist and album.
      _row('/app/podcasts/1/ep1.mp3',
          title: 'Song of the day', artist: 'Band', album: 'Band', key: 'band|band', genre: 'Podcast', kind: 1, plays: 9),
    ]);
    songId = (await tracks.idForPath('/m/song.mp3'))!;
    episodeId = (await tracks.idForPath('/app/podcasts/1/ep1.mp3'))!;
  });
  tearDown(() => db.close());

  test('an episode is in none of the music lists', () async {
    expect((await tracks.watchTracks().first).map((t) => t.id), [songId]);
    expect((await tracks.watchTracks(query: 'Song').first).map((t) => t.id), [songId]);
    expect((await tracks.watchTracks(favoritesOnly: false, sort: SortOption.addedAt).first).map((t) => t.id), [songId]);
    expect((await queries.watchAlbums().first).map((a) => a.title), ['Hits']);
    expect((await queries.watchAlbumTracks('band|band').first), isEmpty);
    expect((await queries.watchArtists().first).single.trackCount, 1);
    expect((await queries.watchArtistTracks('band').first).map((t) => t.id), [songId]);
    expect((await queries.watchGenres().first).map((g) => g.name), ['Rock']);
    expect((await queries.watchGenreTracks('Podcast').first), isEmpty);
    expect((await queries.watchTopTracks().first).map((t) => t.id), [songId], reason: 'its 9 plays do not make it a favourite song');
    expect((await tracks.liteEntries()).map((e) => e.id), [songId], reason: 'an import never links to an episode');
    expect(await tracks.countAll(), 1);
  });

  test('rule searches and smart playlists do not see it either', () async {
    final all = parseRules('song').expr;
    expect((await tracks.tracksByRules(all)).map((t) => t.id), [songId]);
    expect(await tracks.countByRules(all), 1);
    expect((await tracks.watchByRules(parseRules('genere:podcast').expr).first), isEmpty);
  });

  test('duplicates are looked for among music only', () async {
    expect((await DuplicateRepository(db).entries()).map((e) => e.id), [songId]);
  });

  test('a playlist does not take an episode; the music in the same request goes in', () async {
    final playlists = PlaylistRepository(db);
    final list = await playlists.create('Mix');
    expect(await playlists.addTracks(list, [episodeId, songId]), 1);
    expect((await playlists.watchTracks(list).first).map((t) => t.id), [songId]);
    expect(await playlists.addTracks(list, [episodeId]), 0);
  });

  test('an episode that got into a playlist some other way is not shown there or in the history', () async {
    final playlists = PlaylistRepository(db);
    final list = await playlists.create('Mix');
    await db.into(db.playlistTracks).insert(
        PlaylistTracksCompanion.insert(playlistId: list, trackId: episodeId, position: 0));
    expect(await playlists.watchTracks(list).first, isEmpty);

    final history = PlayHistoryRepository(db);
    await history.start(episodeId, 1000);
    await history.start(songId, 2000);
    expect((await history.watchHistory().first).map((e) => e.track.id), [songId]);
  });

  test('the episode itself is still there for the player', () async {
    final t = await tracks.getById(episodeId);
    expect(t!.kind, 1);
    expect((await tracks.getByIds([episodeId, songId])).map((x) => x.id), [episodeId, songId]);
  });
}
