import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/library/rules/rule_parser.dart';
import 'package:codecore/services/online/enrichment_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 28.2: the lists leave lyrics and curiosities in the database. A list
/// row has '' where a text exists and null where it does not; only the whole
/// row (sheet, «In riproduzione») carries the text.
void main() {
  late AppDatabase db;
  late TrackRepository tracks;
  late int rich, bare;

  Future<int> add(String title, {bool texts = false}) => db.into(db.tracks).insert(TracksCompanion.insert(
        path: '/m/$title.mp3',
        title: title,
        artist: const Value('Band'),
        album: const Value('Disc'),
        albumKey: 'band|disc',
        genre: const Value('Rock'),
        format: 'mp3',
        sizeBytes: 1,
        mtimeMs: 1,
        addedAt: 1,
        playCount: const Value(3),
        lyricsPlain: Value(texts ? 'la la la' : null),
        lyricsSynced: Value(texts ? '[00:01.00] la' : null),
        curiosities: Value(texts ? 'A story\nhttps://it.wikipedia.org/wiki/X' : null),
      ));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tracks = TrackRepository(db);
    rich = await add('Rich', texts: true);
    bare = await add('Bare');
  });
  tearDown(() => db.close());

  void light(List<Track> rows, String where) {
    final r = rows.firstWhere((t) => t.id == rich), b = rows.firstWhere((t) => t.id == bare);
    expect([r.lyricsPlain, r.lyricsSynced, r.curiosities], ['', '', ''], reason: '$where: marker only');
    expect([b.lyricsPlain, b.lyricsSynced, b.curiosities], [null, null, null], reason: where);
    expect(r.title, 'Rich', reason: where);
    expect(r.playCount, 3, reason: where);
  }

  test('every list query reads list rows', () async {
    final q = LibraryQueries(db);
    final playlists = PlaylistRepository(db);
    final pl = await playlists.create('P');
    await playlists.addTracks(pl, [rich, bare]);

    light(await tracks.watchTracks().first, 'all tracks');
    light(await tracks.watchTracks(query: 'band').first, 'search');
    light(await tracks.watchByRules(parseRules('genere:rock').expr).first, 'rules');
    light(await q.watchAlbumTracks('band|disc').first, 'album');
    light(await q.watchArtistTracks('band').first, 'artist');
    light(await q.watchGenreTracks('Rock').first, 'genre');
    light(await q.watchTopTracks().first, 'top');
    light(await playlists.watchTracks(pl).first, 'playlist');
    light(await tracks.getByIdsLight([rich, bare]), 'queue');
    expect((await playlists.watchTracks(pl).first).map((t) => t.id), [rich, bare], reason: 'order kept');
  });

  test('the whole row keeps the texts', () async {
    final t = (await tracks.watchById(rich).first)!;
    expect(t.lyricsPlain, 'la la la');
    expect(t.curiosities, startsWith('A story'));
    expect((await tracks.getById(rich))!.lyricsSynced, '[00:01.00] la');
    expect((await tracks.getByIds([rich])).single.lyricsPlain, 'la la la');
  });

  test('«does it need lyrics?» answers the same on a list row', () async {
    final rows = await tracks.watchTracks().first;
    final r = rows.firstWhere((t) => t.id == rich), b = rows.firstWhere((t) => t.id == bare);
    expect(needsEnrichment(r, metadata: false, curiosities: true), isFalse);
    expect(needsEnrichment(b, metadata: false, curiosities: true), isTrue);
  });
}
