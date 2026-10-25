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
    await db.into(db.tracks).insert(row('/3', 'Édith Piaf', 0));
    await db.into(db.tracks).insert(row('/4', 'Gone', 0));
    await (db.update(db.tracks)..where((t) => t.path.equals('/4')))
        .write(const TracksCompanion(missing: Value(true)));
    searches = 0;
    found = [];
    resolver = ArtistLinkResolver(
      library: q.artistNamed,
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

  test('a non-ASCII name is found in the library without searching', () async {
    final r = await resolver.resolve('Édith Piaf');
    expect((r as LibraryArtist).artist.name, 'Édith Piaf');
    expect(r.artist.key, 'Édith piaf'); // SQL lower is ASCII-only, like watchArtists
    expect(searches, 0);
  });

  test('a missing row does not count as library', () async {
    expect(await q.artistNamed('Gone'), isNull);
  });

  test('an empty ytmId searches', () async {
    await resolver.resolve('Nobody', ytmId: '');
    expect(searches, 1);
  });

  test('online artists: ids shorter than names give null ids, no error', () {
    const r = YtResult(
        id: 'x', title: 't', channel: 'c', duration: null,
        artists: ['A', 'B'], artistIds: ['UCa']);
    expect(onlineArtists(r).map((e) => e.ytmId), ['UCa', null]);
  });

  test('online artists: no artists splits the channel', () {
    const r = YtResult(id: 'x', title: 't', channel: 'A, B', duration: null);
    expect(onlineArtists(r).map((e) => e.name), ['A', 'B']);
  });

  test('a library track with an online result still uses its own artists', () async {
    final t = await (db.select(db.tracks)..where((t) => t.path.equals('/1'))).getSingle();
    // Queen is a kind 0 row
    const r = YtResult(id: 'x', title: 't', channel: 'c', duration: null, artists: ['Net']);
    expect(artistsOfTrack(t, r).map((e) => e.name), ['Queen']);
  });

  test('a credit that is a library artist stays one name only without comma/feat. and unless every piece is one too', () {
    const lib = [
      ArtistSummary(key: 'ac/dc', name: 'AC/DC', trackCount: 1, albumCount: 1),
      ArtistSummary(key: 'foo/bar', name: 'Foo/Bar', trackCount: 1, albumCount: 1),
      ArtistSummary(key: 'foo', name: 'Foo', trackCount: 1, albumCount: 1),
      ArtistSummary(key: 'bar', name: 'Bar', trackCount: 1, albumCount: 1),
    ];
    List<String> names(String c, List<ArtistSummary> l) => creditedArtists(c,
        isLibraryArtist: isLibraryArtistIn(l)).map((e) => e.name).toList();
    expect(names('AC/DC', lib), ['AC/DC']);
    expect(names('Foo/Bar', lib), ['Foo', 'Bar']);
    expect(names('AC/DC', const []), ['AC', 'DC']);
    const multi = [
      ArtistSummary(
          key: 'damiano david, tyla, nile rodgers',
          name: 'Damiano David, Tyla, Nile Rodgers',
          trackCount: 1,
          albumCount: 1),
    ];
    expect(names('Damiano David, Tyla, Nile Rodgers', multi),
        ['Damiano David', 'Tyla', 'Nile Rodgers']);
  });
}
