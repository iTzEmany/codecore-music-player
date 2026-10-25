import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/services/online/artist_link_resolver.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

YtmArtistRef ref(String id, String name) => YtmArtistRef(id: id, name: name);

TracksCompanion row(String path, String artist, int kind) =>
    TracksCompanion.insert(
      path: path,
      title: path,
      albumKey: 'k',
      format: 'mp3',
      sizeBytes: 1,
      mtimeMs: 1,
      addedAt: 1,
      artist: Value(artist),
      kind: Value(kind),
    );

void main() {
  late AppDatabase db;
  late LibraryQueries q;
  var searches = 0;
  var found = <YtmArtistRef>[];
  late ArtistLinkResolver resolver;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    q = LibraryQueries(db);
    await db.into(db.tracks).insert(row('/1', 'Queen', 0));
    await db.into(db.tracks).insert(row('/2', 'Shadow', 2));
    searches = 0;
    found = [];
    resolver = ArtistLinkResolver(
      library: q.artistByKey,
      search: (_) async {
        searches++;
        return found;
      },
    );
  });
  tearDown(() => db.close());

  test('library hit: no search, case and spaces ignored', () async {
    final r = await resolver.resolve(' QUEEN ', ytmId: 'UC1');
    expect((r as LibraryArtist).artist.trackCount, 1);
    expect(searches, 0);
  });

  test('a kind 2 row does not count as library', () async {
    final r = await resolver.resolve('Shadow', ytmId: 'UC2');
    expect(r, isA<OnlineArtist>());
  });

  test('ytmId opens the page without searching', () async {
    final r = await resolver.resolve('Nobody', ytmId: 'UC9');
    expect((r as OnlineArtist).artist.id, 'UC9');
    expect(searches, 0);
  });

  test('one exact match opens it', () async {
    found = [ref('UC1', 'Nobody'), ref('UC2', 'Somebody')];
    final r = await resolver.resolve('Nobody');
    expect((r as OnlineArtist).artist.id, 'UC1');
  });

  test('no exact match offers the first 3 of 5', () async {
    found = [for (var i = 0; i < 5; i++) ref('UC$i', 'Other $i')];
    final r = await resolver.resolve('Nobody');
    expect((r as ChooseArtists).artists.length, 3);
  });

  test('nothing found', () async {
    expect(await resolver.resolve('Nobody'), isA<NoArtistLink>());
  });

  test('online result: ids aligned with artists, empty id means none', () {
    const r = YtResult(
      id: 'x',
      title: 't',
      channel: 'c',
      duration: null,
      artists: ['A', 'B'],
      artistIds: ['UCa', ''],
    );
    final a = onlineArtists(r);
    expect(a.map((e) => e.ytmId), ['UCa', null]);
    expect(a.map((e) => e.sep), [', ', '']);
  });
}
